#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::centreon::sql::mode::countservices;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:values :counters);

use strict;
use warnings;

sub poller_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking poller '%s'",
        $options{instance}
    );
}

sub prefix_poller_output {
    my ($self, %options) = @_;

    return sprintf(
        "poller '%s' ",
        $options{instance}
    );
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "number of hosts ";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "number of services ";
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        {
            name => 'pollers', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_poller_output', cb_long_output => 'poller_long_output', indent_long_output => '    ', message_multiple => 'All pollers are ok',
            group => [
                { name => 'host', type => COUNTER_MULTIPLE_INSTANCE, prefix_output => 'number of hosts ', skipped_code => { NO_VALUE() => 1 } },
                { name => 'service', type => COUNTER_MULTIPLE_INSTANCE, prefix_output => 'number of services ', skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{host} = [
        { label => 'host', nlabel => 'centreon.hosts.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    foreach ('up', 'down', 'unreachable', 'pending') {
        push @{$self->{maps_counters}->{host}}, {
             label => 'hosts-' . $_, nlabel => 'centreon.hosts.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        };
    }

    $self->{maps_counters}->{service} = [
        { label => 'service', nlabel => 'centreon.services.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
    foreach ('ok', 'warning', 'critical', 'unknown', 'pending') {
        push @{$self->{maps_counters}->{service}}, {
             label => 'services-' . $_, nlabel => 'centreon.services.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-poller:s'             => { name => 'filter_poller' },
        'centreon-storage-database:s' => { name => 'centreon_storage_database', default => 'centreon_storage' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query = "SELECT instances.name, COUNT(DISTINCT hosts.host_id) as num_hosts, count(DISTINCT services.host_id, services.service_id) as num_services
        FROM " . $self->{option_results}->{centreon_storage_database} .  ".instances, " . $self->{option_results}->{centreon_storage_database} . ".hosts, " . $self->{option_results}->{centreon_storage_database} . ".services WHERE instances.running = '1' AND instances.instance_id = hosts.instance_id AND hosts.enabled = '1' AND hosts.host_id = services.host_id AND services.enabled = '1' GROUP BY hosts.instance_id";
    $options{sql}->connect();
    $options{sql}->query(
        query => 'SELECT
            i.name,
            COALESCE(SUM(CASE WHEN h.state = 0 THEN 1 ELSE 0 END), 0) AS up,
            COALESCE(SUM(CASE WHEN h.state = 1 THEN 1 ELSE 0 END), 0) AS down,
            COALESCE(SUM(CASE WHEN h.state = 2 THEN 1 ELSE 0 END), 0) AS unreachable,
            COALESCE(SUM(CASE WHEN h.state = 4 THEN 1 ELSE 0 END), 0) AS pending,
            count(*) as total
            FROM ' . $self->{option_results}->{centreon_storage_database} . '.hosts h, ' . $self->{option_results}->{centreon_storage_database} . '.instances i
            WHERE i.running = 1
                AND h.instance_id = i.instance_id
                AND h.enabled = 1
                AND h.name NOT LIKE "\_Module\_%"
            GROUP BY h.instance_id'
    );

    # check by poller
    $self->{pollers} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_poller}) && $self->{option_results}->{filter_poller} ne '' &&
            $row->{name} !~ /$self->{option_results}->{filter_poller}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pollers}->{ $row->{name} } = { host => $row };
    }

    $options{sql}->query(
        query => 'SELECT
            i.name,
            COALESCE(SUM(CASE WHEN s.state = 0 THEN 1 ELSE 0 END), 0) AS ok,
            COALESCE(SUM(CASE WHEN s.state = 1 THEN 1 ELSE 0 END), 0) AS warning,
            COALESCE(SUM(CASE WHEN s.state = 2 THEN 1 ELSE 0 END), 0) AS critical,
            COALESCE(SUM(CASE WHEN s.state = 3 THEN 1 ELSE 0 END), 0) AS unknown,
            COALESCE(SUM(CASE WHEN s.state = 4 THEN 1 ELSE 0 END), 0) AS pending,
            count(*) as total
            FROM ' . $self->{option_results}->{centreon_storage_database} . '.hosts h, ' . $self->{option_results}->{centreon_storage_database} . '.services s, ' . $self->{option_results}->{centreon_storage_database} . '.instances i
            WHERE i.running = 1
                AND h.instance_id = i.instance_id
                AND h.enabled = 1
                AND (h.name NOT LIKE "\_Module\_%" OR h.name LIKE "\_Module\_Meta%")
                AND s.enabled = 1
                AND h.host_id = s.host_id
            GROUP BY h.instance_id'
    );
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_poller}) && $self->{option_results}->{filter_poller} ne '' &&
            $row->{name} !~ /$self->{option_results}->{filter_poller}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pollers}->{ $row->{name} }->{service} = $row;
    }
    
    if (scalar(keys %{$self->{pollers}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "No poller found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check the number of hosts/services by poller.
The mode should be used with the database::mysql::plugin plugin and C<--dyn-mode> option.
Example: C<perl centreon_plugins.pl --plugin=database::mysql::plugin --dyn-mode=apps::centreon::sql::mode::countservices ...>.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='service'

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--filter-poller>

Filter by poller name (regexp can be used).


=item B<--warning-host>

Threshold.

=item B<--critical-host>

Threshold.

=item B<--warning-hosts-down>

Threshold.

=item B<--critical-hosts-down>

Threshold.

=item B<--warning-hosts-pending>

Threshold.

=item B<--critical-hosts-pending>

Threshold.

=item B<--warning-hosts-unreachable>

Threshold.

=item B<--critical-hosts-unreachable>

Threshold.

=item B<--warning-hosts-up>

Threshold.

=item B<--critical-hosts-up>

Threshold.

=item B<--warning-service>

Threshold.

=item B<--critical-service>

Threshold.

=item B<--warning-services-critical>

Threshold.

=item B<--critical-services-critical>

Threshold.

=item B<--warning-services-ok>

Threshold.

=item B<--critical-services-ok>

Threshold.

=item B<--warning-services-pending>

Threshold.

=item B<--critical-services-pending>

Threshold.

=item B<--warning-services-unknown>

Threshold.

=item B<--critical-services-unknown>

Threshold.

=item B<--warning-services-warning>

Threshold.

=item B<--critical-services-warning>

Threshold.

=back

=cut
