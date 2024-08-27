#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::netapp::ontap::snmp::mode::plexes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub plex_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking plex '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_plex_output {
    my ($self, %options) = @_;

    return sprintf(
        "Plex '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_aggregate_output {
    my ($self, %options) = @_;

    return sprintf(
        "aggregate '%s' ",
        $options{instance_value}->{aggregate}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Plex ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'plexes', type => 3, cb_prefix_output => 'prefix_plex_output', cb_long_output => 'plex_long_output',
          indent_long_output => '    ', message_multiple => 'All plexes are ok',
            group => [
                { name => 'aggregates', type => 1, cb_prefix_output => 'prefix_aggregate_output', message_multiple => 'aggregates are ok', display_long => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-online', display_ok => 0, nlabel => 'plexes.online.count', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'online: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-offline', display_ok => 0, nlabel => 'plexes.offline.count', set => {
                key_values => [ { name => 'offline' } ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-resyncing', display_ok => 0, nlabel => 'plexes.resyncing.count', set => {
                key_values => [ { name => 'resyncing' } ],
                output_template => 'resyncing: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{aggregates} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} eq "resyncing"',
            critical_default => '%{status} eq "offline"',
            set => {
                key_values => [ { name => 'status' }, { name => 'aggregate' }, { name => 'name' } ],
                output_template => "status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'resyncing', nlabel => 'plex.resyncing.percentage', set => {
                key_values => [ { name => 'resync' } ],
                output_template => 'resyncing: %.2f %%',
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'      => { name => 'filter_name' },
        'filter-aggregate:s' => { name => 'filter_aggregate' }
    });

    return $self;
}

my $map_plex_status = {
    1 => 'offline', 2 => 'resyncing', 3 => 'online'
};

my $mapping = {
    aggregate => { oid => '.1.3.6.1.4.1.789.1.6.11.1.3' }, # plexVolName
    status    => { oid => '.1.3.6.1.4.1.789.1.6.11.1.4', map => $map_plex_status },  # plexStatus
    resync    => { oid => '.1.3.6.1.4.1.789.1.6.11.1.5' } # plexPercentResyncing
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_plexName = '.1.3.6.1.4.1.789.1.6.11.1.2';

    $self->{global} = { offline => 0, resyncing => 0, online => 0 };
    $self->{plexes} = {};
    my $instances = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_plexName, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_plexName\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$oid};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping plex '" . $name . "'.", debug => 1);
            next;
        }

        $instances->{$instance} = $name;
        $self->{plexes}->{$name} = { name => $name, aggregates => {} };
    }

    if (scalar(keys %{$self->{plexes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No plex found");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [ map($_, keys %$instances) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    
    foreach (keys %$instances) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_aggregate}) && $self->{option_results}->{filter_aggregate} ne '' &&
            $result->{aggregate} !~ /$self->{option_results}->{filter_aggregate}/) {
            $self->{output}->output_add(long_msg => "skipping aggregatge '" . $result->{aggregate} . "'.", debug => 1);
            next;
        }

        $self->{plexes}->{ $instances->{$_} }->{aggregates}->{ $result->{aggregate} }->{name} = $instances->{$_};
        $self->{plexes}->{ $instances->{$_} }->{aggregates}->{ $result->{aggregate} }->{aggregate} = $result->{aggregate};
        $self->{plexes}->{ $instances->{$_} }->{aggregates}->{ $result->{aggregate} }->{status} = $result->{status};
        $self->{plexes}->{ $instances->{$_} }->{aggregates}->{ $result->{aggregate} }->{resync} = $result->{resync} if ($result->{status} eq 'resyncing');
        $self->{global}->{ $result->{status} }++;
    }
}

1;

__END__

=head1 MODE

Check plexes.

=over 8

=item B<--filter-name>

Filter plexes by name.

=item B<--filter-aggregate>

Filter plexes by aggregate name.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}, %{aggregate}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} eq "resyncing"').
You can use the following variables: %{status}, %{name}, %{aggregate}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status}  eq "offline"').
You can use the following variables: %{status}, %{name}, %{aggregate}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-online', 'total-offline', 'total-resyncing', 'resyncing'.

=back

=cut
