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

package storage::emc::DataDomain::snmp::mode::replications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use storage::emc::DataDomain::snmp::lib::functions;
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_replication_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $instances,
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_sync_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel => 'replication.last.insync.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $instances,
        value => floor($self->{result_values}->{offset_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_sync_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{offset_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_repl_output {
    my ($self, %options) = @_;

    return sprintf(
        "state: %s, status: %s",
        $self->{result_values}->{state},
        $self->{result_values}->{status}
    );
}

sub repl_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking replication source '%s' destination '%s' [type: %s]",
        $options{instance_value}->{source},
        $options{instance_value}->{destination},
        $options{instance_value}->{type}
    );
}

sub prefix_repl_output {
    my ($self, %options) = @_;

    return sprintf(
        "replication source '%s' destination '%s' [type: %s] ",
        $options{instance_value}->{source},
        $options{instance_value}->{destination},
        $options{instance_value}->{type}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of replications ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'repl', type => 3, cb_prefix_output => 'prefix_repl_output', cb_long_output => 'repl_long_output', indent_long_output => '    ', message_multiple => 'All replications are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'precomp', type => 0, skipped_code => { -10 => 1 } },
                { name => 'sync', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'repl-detected', display_ok => 0, nlabel => 'replications.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
         {
             label => 'status',
             type => 2,
             warning_default => '%{state} =~ /initializing|recovering/i',
             critical_default => '%{state} =~ /disabledNeedsResync|uninitialized/i',
             set => {
                key_values => [ { name => 'state' }, { name => 'status' }, { name => 'source' }, { name => 'destination' }, { name => 'type' } ],
                closure_custom_output => $self->can('custom_repl_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{precomp} = [
        { label => 'precompression-data-remaining', nlabel => 'replication.precompression.data.remaining.bytes', set => {
                key_values => [ { name => 'remaining' }, { name => 'source' }, { name => 'destination' }, { name => 'type' } ],
                output_template => 'precompression data remaining: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_replication_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{sync} = [
        { label => 'last-insync-time', set => {
                key_values      => [ { name => 'offset_seconds' }, { name => 'offset_human' }, { name => 'source' }, { name => 'destination' }, { name => 'type' } ],
                output_template => 'last in sync time: %s',
                output_use => 'offset_human',
                closure_custom_perfdata => $self->can('custom_sync_perfdata'),
                closure_custom_threshold_check => $self->can('custom_sync_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-repl-index:s'         => { name => 'filter_repl_index' },
        'filter-repl-source:s'        => { name => 'filter_repl_source' },
        'filter-repl-destination:s'   => { name => 'filter_repl_destination' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' },
        'unit:s'                      => { name => 'unit', default => 'd' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 'd';
    }

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(type) %(source) %(destination)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { type => 1, source => 1, destination => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0'; # 'Data Domain OS 5.4.1.1-411752'
    my $oid_replicationInfoEntry = '.1.3.6.1.4.1.19746.1.8.1.1.1';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr ],
        nothing_quit => 1
    );

    if (!($self->{os_version} = storage::emc::DataDomain::snmp::lib::functions::get_version(value => $snmp_result->{$oid_sysDescr}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get DataDomain OS version.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_replicationInfoEntry,
        nothing_quit => 1
    );

    my ($oid_replSource, $oid_replDestination, $oid_replState, $oid_replStatus);
    my %map_state = (
        1 => 'enabled', 2 => 'disabled', 3 => 'disabledNeedsResync',
    );
    my %map_status = (
        1 => 'connected', 2 => 'disconnected', 3 => 'migrating',
        4 => 'suspended', 5 => 'neverConnected', 6 => 'idle'
    );
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.4')) {
        %map_state = (
            1 => 'initializing', 2 => 'normal', 3 => 'recovering', 4 => 'uninitialized',
        );
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.4';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } elsif (centreon::plugins::misc::minimal_version($self->{os_version}, '5.0')) {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.8';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.4';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
    } else {
        $oid_replSource = '.1.3.6.1.4.1.19746.1.8.1.1.1.6';
        $oid_replDestination = '.1.3.6.1.4.1.19746.1.8.1.1.1.7';
        $oid_replStatus = '.1.3.6.1.4.1.19746.1.8.1.1.1.3';
        $oid_replState = '.1.3.6.1.4.1.19746.1.8.1.1.1.2';
    }

    my $mapping = {
        replState                 => { oid => $oid_replState, map => \%map_state },
        replStatus                => { oid => $oid_replStatus, map => \%map_status },
        replSource                => { oid => $oid_replSource },
        replDestination           => { oid => $oid_replDestination },
        replPreCompBytesRemaining => { oid => '.1.3.6.1.4.1.19746.1.8.1.1.1.11' },
        replSyncedAsOfTime        => { oid => '.1.3.6.1.4.1.19746.1.8.1.1.1.14' }
    };

    my $ctime = time();

    $self->{global} = { detected => 0 };
    $self->{repl} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{replState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{replSource} =~ /^(.*?):\/\//;
        my $type = $1;

        $result->{replSource} =~ s/^(.*?):\/\///;
        $result->{replDestination} =~ s/^(.*?):\/\///;

        # /data/col1/ is always present (useless information)
        $result->{replSource} =~ s/\/data\/col1//;
        $result->{replDestination} =~ s/\/data\/col1//;
        
        next if (defined($self->{option_results}->{filter_repl_index}) && $self->{option_results}->{filter_repl_index} ne '' &&
            $instance !~ /$self->{option_results}->{filter_repl_index}/);
        next if (defined($self->{option_results}->{filter_repl_source}) && $self->{option_results}->{filter_repl_source} ne '' &&
            $result->{replSource} !~ /$self->{option_results}->{filter_repl_source}/);
        next if (defined($self->{option_results}->{filter_repl_destination}) && $self->{option_results}->{filter_repl_destination} ne '' &&
            $result->{replDestination} !~ /$self->{option_results}->{filter_repl_destination}/);

        $self->{global}->{detected}++;

        $self->{repl}->{$instance} = {
            type => $type,
            source => $result->{replSource},
            destination => $result->{replDestination},
            status => {
                type => $type,
                source => $result->{replSource},
                destination => $result->{replDestination},
                state => $result->{replState},
                status => $result->{replStatus}
            },
            precomp => {
                type => $type,
                source => $result->{replSource},
                destination => $result->{replDestination},
                remaining => $result->{replPreCompBytesRemaining}
            },
            sync => {
                type => $type,
                source => $result->{replSource},
                destination => $result->{replDestination}
            }
        };
    
        $self->{repl}->{$instance}->{sync}->{offset_seconds} = $ctime - $result->{replSyncedAsOfTime};
        $self->{repl}->{$instance}->{sync}->{offset_human} = centreon::plugins::misc::change_seconds(
            value => $self->{repl}->{$instance}->{sync}->{offset_seconds}
        );
    }
}

1;

__END__

=head1 MODE

Check replication.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-repl-index>

Check replications by index.

=item B<--filter-repl-source>

Check replications by source.

=item B<--filter-repl-destination>

Check replications by destination.

=item B<--custom-perfdata-instances>

Customize the name composition rule for the instances the metrics will be attached to (default: '%(type) %(source) %(destination)').
You can use the following variables: %(type) %(source) %(destination)

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks (default: 'd').

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{status}, %{source}, %{destination}, %{type}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /initializing|recovering/i').
You can use the following variables: %{state}, %{status}, %{source}, %{destination}, %{type}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /disabledNeedsResync|uninitialized/i').
You can use the following variables: %{state}, %{status}, %{source}, %{destination}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'repl-detected', 'precompression-data-remaining', 'last-insync-time'.

=back

=cut
