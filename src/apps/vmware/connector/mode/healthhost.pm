#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::healthhost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub custom_summary_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{type} ne '') {
        $msg = $self->{result_values}->{type} . " sensor " . $self->{result_values}->{name} . ": ". $self->{result_values}->{summary};
    } else {
        $msg = $self->{result_values}->{name} . ": ". $self->{result_values}->{summary};
    }
    return $msg;
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{display} . "'";
}

sub prefix_global_cpu_output {
    my ($self, %options) = @_;

    return "cpu total average : ";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "cpu '" . $options{instance_value}->{display} . "' ";
}

sub prefix_sensor_output {
    my ($self, %options) = @_;

    return "sensor '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global_host', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_problems', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_summary', type => 1 },
                { name => 'sensors_temp', display_long => 1, cb_prefix_output => 'prefix_sensor_output', message_multiple => 'temperature sensors are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'sensors_fan', display_long => 1, cb_prefix_output => 'prefix_sensor_output', message_multiple => 'fan sensors are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'sensors_voltage', display_long => 1, cb_prefix_output => 'prefix_sensor_output', message_multiple => 'voltage sensors are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'sensors_power', display_long => 1, cb_prefix_output => 'prefix_sensor_output', message_multiple => 'power sensors are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-problems', nlabel => 'host.health.problems.current.count', set => {
                key_values => [ { name => 'total_problems' }, { name => 'total' } ],
                output_template => '%s total health issue(s) found',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_host} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global_problems} = [
        { label => 'ok', threshold => 0, set => {
                key_values => [ { name => 'ok' } ],
                output_template => '%s health checks are green',
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'problems', nlabel => 'host.health.problems.current.count', set => {
                key_values => [ { name => 'total_problems' }, { name => 'total' } ],
                output_template => '%s total health issue(s) found',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'problems-yellow', nlabel => 'host.health.yellow.current.count', set => {
                key_values => [ { name => 'yellow' }, { name => 'total' } ],
                output_template => '%s yellow health issue(s) found',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'problems-red', nlabel => 'host.health.red.current.count', set => {
                key_values => [ { name => 'red' }, { name => 'total' } ],
                output_template => '%s red health issue(s) found',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_summary} = [
        { label => 'global-summary', threshold => 0, set => {
                key_values => [ { name => 'type' }, { name => 'name' }, { name => 'summary' } ],
                closure_custom_output => $self->can('custom_summary_output'),
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];

    $self->{maps_counters}->{sensors_temp} = [
        { label => 'sensor-temperature', nlabel => 'host.sensor.temperature.celsius', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sensors_fan} = [
        { label => 'sensor-fan', nlabel => 'host.sensor.fan.speed.rpm', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'fan speed: %s rpm',
                perfdatas => [
                    { template => '%s', unit => 'rpm', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sensors_voltage} = [
        { label => 'sensor-voltage', nlabel => 'host.sensor.voltage.volt', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { template => '%s', unit => 'V', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sensors_power} = [
        { label => 'sensor-power', nlabel => 'host.sensor.power.watt', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'power: %s W',
                perfdatas => [
                    { template => '%s', unit => 'W', min => 0, label_extra_instance => 1 }
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
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' },
        'storage-status'     => { name => 'storage_status' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total_problems => 0, total => 0 };
    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'healthhost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { display => $host_name, 
            global_host => {
                state => $response->{data}->{$host_id}->{state},    
            },
            global_summary => {},
            global_problems => {
                ok => 0, total_problems => 0, red => 0, yellow => 0, total => 0
            },
            sensors_temp => {}
        };

        my $i = 0;
        foreach (('memory_info', 'cpu_info', 'sensor_info', 'storage_info')) {
            if (defined($response->{data}->{$host_id}->{$_})) {
                foreach my $entry (@{$response->{data}->{$host_id}->{$_}}) {
                    my $status = 'ok';
                    $status = lc($1) if ($entry->{status} =~ /(yellow|red)/i);
                    $self->{host}->{$host_name}->{global_problems}->{$status}++;
                    $self->{host}->{$host_name}->{global_problems}->{total}++;
                    if ($status ne 'ok') {
                        $self->{host}->{$host_name}->{global_problems}->{total_problems}++;
                        $self->{host}->{$host_name}->{global_summary}->{$i} = {
                            type => defined($entry->{type}) ? $entry->{type} : '',
                            name => $entry->{name},
                            summary => $entry->{summary}
                        };
                    }
                }

                $i++;
            }
        }

        if (defined($response->{data}->{$host_id}->{sensor_info})) {
            foreach my $entry (@{$response->{data}->{$host_id}->{sensor_info}}) {
                next if ($entry->{current_reading} == 0);

                $entry->{current_reading} *= 10 ** $entry->{power10};
                $entry->{name} =~ s/\s---\s.+//;
                if (lc($entry->{type}) eq 'temperature' && $entry->{unit} =~ /Degrees\s+C/i) {
                    $self->{host}->{$host_name}->{sensors_temp}->{ $entry->{name} } = { value => $entry->{current_reading} };
                } elsif (lc($entry->{type}) eq 'fan' && $entry->{unit} =~ /rpm/i) {
                    $self->{host}->{$host_name}->{sensors_fan}->{ $entry->{name} } = { value => $entry->{current_reading} };
                } elsif (lc($entry->{type}) eq 'voltage' && $entry->{unit} =~ /volts/i) {
                    $self->{host}->{$host_name}->{sensors_voltage}->{ $entry->{name} } = { value => $entry->{current_reading} };
                } elsif (lc($entry->{type}) eq 'power' && $entry->{unit} =~ /watts/i) {
                    $self->{host}->{$host_name}->{sensors_power}->{ $entry->{name} } = { value => $entry->{current_reading} };
                }
            }
        }

        $self->{global}->{total_problems} += $self->{host}->{$host_name}->{global_problems}->{red} + $self->{host}->{$host_name}->{global_problems}->{yellow};
        $self->{global}->{total} +=  $self->{host}->{$host_name}->{global_problems}->{total};
    }
}

1;

__END__

=head1 MODE

Check health of ESX hosts.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--storage-status>

Check storage(s) status.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (Default: '%{status} !~ /^connected$/i').
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (Default: '').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (Default: '').
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-problems', 'problems', 'problems-yellow', 'problems-red',
'sensor-temperature', 'sensor-fan', 'sensor-voltage', 'sensor-power'.

=back

=cut
