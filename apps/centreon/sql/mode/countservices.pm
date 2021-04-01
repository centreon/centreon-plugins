#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'poller', type => 1, cb_prefix_output => 'prefix_poller_output', message_multiple => 'All poller hosts/services are ok' }
    ];
    
    $self->{maps_counters}->{poller} = [
        { label => 'host', set => {
                key_values => [ { name => 'hosts' }, { name => 'display' } ],
                output_template => 'Number of hosts : %s',
                perfdatas => [
                    { label => 'total_hosts', value => 'hosts', template => '%s', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'service', set => {
                key_values => [ { name => 'services' }, { name => 'display' } ],
                output_template => 'Number of services : %s',
                perfdatas => [
                    { label => 'total_services', value => 'services', template => '%s', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_poller_output {
    my ($self, %options) = @_;
    
    return "Poller '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
    $options{sql}->query(query => $query);

    # check by poller
    $self->{poller} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_poller}) && $self->{option_results}->{filter_poller} ne '' &&
            $row->{name} !~ /$self->{option_results}->{filter_poller}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $row->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{poller}->{$row->{name}} = { display => $row->{name}, hosts => $row->{num_hosts}, services => $row->{num_services} };
    }
    
    if (scalar(keys %{$self->{poller}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "No poller found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check the number of hosts/services by poller.

=over 8

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^services$'

=item B<--warning-*>

Threshold warning.
Can be: 'host', 'service'.

=item B<--critical-*>

Threshold critical.
Can be: Can be: 'host', 'service'.

=item B<--filter-poller>

Filter by poller name (regexp can be used).

=back

=cut
