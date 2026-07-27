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

package apps::monitoring::prtg::api::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_sensor_type = {
    STORAGE => 1, # Go
    PERCENT => 2, # %
    MS      => 3, # ms
    TRAFFIC => 4, # Mbit/s
    CELSIUS => 5  # u00b0C
};

sub custom_sensor_current_perfdata {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    my ($nlabel, $min, $max) = ($self->{nlabel}); 
    if ($self->{result_values}->{type} == $map_sensor_type->{TRAFFIC}) {
        $nlabel .= '.bitspersecond';
        $min = 0;
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{STORAGE}) {
        $nlabel .= '.bytes';
        $min = 0;
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{PERCENT}) {
        $nlabel .= '.percent';
        $min = 0;
        $max = 100;
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{MS}) {
        $nlabel .= '.milliseconds';
        $min = 0;
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{CELSIUS}) {
        $nlabel .= '.celsius';
    }

    $self->{output}->perfdata_add(
        nlabel => $nlabel,
        instances => $instances,
        value => $self->{result_values}->{current},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => $min, 
        max => $max
    );
}

sub custom_sensor_current_output {
    my ($self, %options) = @_;

    if ($self->{result_values}->{type} == $map_sensor_type->{TRAFFIC}) {
        my ($current_value, $current_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{current}, network => 1);
        return sprintf(
            'current: %s %s/s',
            $current_value,
            $current_unit
        );
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{STORAGE}) {
        my ($current_value, $current_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{current});
        return sprintf(
            'current: %s %s',
            $current_value,
            $current_unit
        );
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{PERCENT}) {
        return sprintf(
            'current: %s %%',
            $self->{result_values}->{current}
        );
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{MS}) {
        return sprintf(
            'current: %s ms',
            $self->{result_values}->{current}
        );
    } elsif ($self->{result_values}->{type} == $map_sensor_type->{CELSIUS}) {
        return sprintf(
            'current: %s C',
            $self->{result_values}->{current}
        );
    }
}

sub custom_sensor_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{sensorStatus}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of devices ';
}

sub device_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking device '%s'",
        $options{instance_value}->{deviceName}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{deviceName}
    );
}

sub prefix_sensor_output {
    my ($self, %options) = @_;

    return sprintf(
        "sensor '%s' ",
        $options{instance_value}->{sensorName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'devices', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'sensors', type => COUNTER_MULTIPLE_SUBINSTANCE, message_multiple => 'All sensors are ok', cb_prefix_output => 'prefix_sensor_output', display_long => 1, skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'devices-detected', display_ok => 0, nlabel => 'devices.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sensors} = [
        {
            label => 'sensor-status',
            type => COUNTER_KIND_TEXT,
            unknown_default  => '%{sensorStatus} =~ /unknown|unusual|noProbe|pausedbyLicense/',
            warning_default  => '%{sensorStatus} =~ /warning/',
            critical_default => '%{sensorStatus} =~ /down|critical/',
            set => {
                key_values => [
                    { name => 'sensorStatus' }, { name => 'deviceName' }, { name => 'sensorName' }
                ],
                closure_custom_output => $self->can('custom_sensor_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sensor-current', nlabel => 'sensor.current', set => {
                key_values => [
                    { name => 'current' }, { name => 'type' }, { name => 'deviceName' }, { name => 'sensorName' }
                ],
                closure_custom_output => $self->can('custom_sensor_current_output'),
                closure_custom_perfdata => $self->can('custom_sensor_current_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-device-id:s'         => { name => 'include_device_id',  default => '' },
        'exclude-device-id:s'         => { name => 'exclude_device_id',  default => '' },
        'include-device-name:s'       => { name => 'include_device_name',  default => '' },
        'exclude-device-name:s'       => { name => 'exclude_device_name',  default => '' },
        'include-sensor-name:s'       => { name => 'include_sensor_name',  default => '' },
        'exclude-sensor-name:s'       => { name => 'exclude_sensor_name',  default => '' },
        'include-sensor-id:s'         => { name => 'include_sensor_id',  default => '' },
        'exclude-sensor-id:s'         => { name => 'exclude_sensor_id',  default => '' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(deviceName) %(sensorName)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances => $self->{option_results}->{custom_perfdata_instances},
        labels => { deviceName => 1, sensorName => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $devices = $options{custom}->get_devices();
    my $sensors = $options{custom}->get_sensors();

    $self->{global} = { detected => 0 };
    $self->{devices} = {};
    foreach my $sensor (values %$sensors) {
        next if is_excluded($devices->{ $sensor->{parentId} }->{name}, $self->{option_results}->{include_device_name}, $self->{option_results}->{exclude_device_name});
        next if is_excluded($devices->{ $sensor->{parentId} }->{id}, $self->{option_results}->{include_device_id}, $self->{option_results}->{exclude_device_id});
        next if is_excluded($sensor->{name}, $self->{option_results}->{include_sensor_name}, $self->{option_results}->{exclude_sensor_name});
        next if is_excluded($sensor->{id}, $self->{option_results}->{include_sensor_id}, $self->{option_results}->{exclude_sensor_id});

        if (!defined($self->{devices}->{ $sensor->{parentId} })) {
            $self->{devices}->{ $sensor->{parentId} } = {
                deviceName => $devices->{ $sensor->{parentId} }->{name},
                sensors => {}
            };
            $self->{global}->{detected}++;
        }

        $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} } = {
            deviceName => $devices->{ $sensor->{parentId} }->{name},
            sensorName   => $sensor->{name},
            sensorStatus => $sensor->{status},
            current      => $sensor->{lastvalueRaw}
        };
        
        if ($sensor->{lastvalue} =~ /\s+Go/) {
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{type} = $map_sensor_type->{STORAGE};
        } elsif ($sensor->{lastvalue} =~ /\s+%/) {
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{type} = $map_sensor_type->{PERCENT};
        } elsif ($sensor->{lastvalue} =~ /\s+ms/) {
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{type} = $map_sensor_type->{MS};
        } elsif ($sensor->{lastvalue} =~ /.*?([0-9.,]+?)\s+Mbit\/s/) {
            my $value = $1;
            $value =~ s/,/./g;
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{current} = $value * 1000 * 1000;
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{type} = $map_sensor_type->{TRAFFIC};
        } elsif ($sensor->{lastvalue} =~ /\s+.*?C$/) {
            $self->{devices}->{ $sensor->{parentId} }->{sensors}->{ $sensor->{id} }->{type} = $map_sensor_type->{CELSIUS};
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['deviceName', 'deviceId', 'sensorName', 'sensorId', 'sensorStatus']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $devices = $options{custom}->get_devices();
    my $sensors = $options{custom}->get_sensors();
    foreach my $sensor (values %$sensors) {
        next if is_excluded($devices->{ $sensor->{parentId} }->{name}, $self->{option_results}->{include_device_name}, $self->{option_results}->{exclude_device_name});
        next if is_excluded($devices->{ $sensor->{parentId} }->{id}, $self->{option_results}->{include_device_id}, $self->{option_results}->{exclude_device_id});
        next if is_excluded($sensor->{name}, $self->{option_results}->{include_sensor_name}, $self->{option_results}->{exclude_sensor_name});
        next if is_excluded($sensor->{id}, $self->{option_results}->{include_sensor_id}, $self->{option_results}->{exclude_sensor_id});

        $self->{output}->add_disco_entry(
            deviceName   => $devices->{ $sensor->{parentId} }->{name},
            deviceId     => $sensor->{parentId},
            sensorName   => $sensor->{name},
            sensorId     => $sensor->{id},
            sensorStatus => $sensor->{status}
        );
    }
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--include-device-name>

Include device names (regexp).

=item B<--exclude-device-name>

Exclude device names (regexp).

=item B<--include-device-id>

Include device IDs (regexp).

=item B<--exclude-device-id>

Exclude device IDs (regexp).

=item B<--include-sensor-name>

Include sensor names (regexp).

=item B<--exclude-sensor-name>

Exclude sensor names (regexp).

=item B<--include-sensor-id>

Include sensor IDs (regexp).

=item B<--exclude-sensor-id>

Exclude sensor IDs (regexp).

=item B<--exclude-gateway-id>

Exclude gateway IDs (regexp).

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(deviceName) %(sensorName)')

=item B<--unknown-sensor-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{sensorStatus} =~ /unknown|unusual|noProbe|pausedbyLicense/').
You can use the following variables: %{deviceName}, %{sensorName}, %{sensorStatus}

=item B<--warning-sensor-status>

Define the conditions to match for the status to be WARNING (default: '%{sensorStatus} =~ /warning/').
You can use the following variables: %{deviceName}, %{sensorName}, %{sensorStatus}

=item B<--critical-sensor-status>

Define the conditions to match for the status to be CRITICAL (default: '%{sensorStatus} =~ /down|critical/').
You can use the following variables: %{deviceName}, %{sensorName}, %{sensorStatus}

=item B<--warning-devices-detected>

Threshold.

=item B<--critical-devices-detected>

Threshold.

=item B<--warning-interface-traffic-in>

Threshold.

=item B<--critical-interface-traffic-in>

Threshold.

=item B<--warning-interface-traffic-out>

Threshold.

=item B<--critical-interface-traffic-out>

Threshold.

=item B<--warning-interface-jitter>

Threshold.

=item B<--critical-interface-jitter>

Threshold.

=item B<--warning-interface-latency>

Threshold.

=item B<--critical-interface-latency>

Threshold.

=item B<--warning-interface-loss>

Threshold.

=item B<--critical-interface-loss>

Threshold.

=back

=cut
