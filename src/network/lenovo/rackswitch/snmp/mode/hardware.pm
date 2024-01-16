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

package network::lenovo::rackswitch::snmp::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use network::lenovo::rackswitch::snmp::mode::resources;

sub prefix_sensor_output {
    my ($self, %options) = @_;

    return "sensor '" . $options{instance} . "' ";
}

sub prefix_fan_output {
    my ($self, %options) = @_;

    return "fan '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sensors', type => 1, cb_prefix_output => 'prefix_sensor_output', message_multiple => 'All sensors are ok', skipped_code => { -10 => 1 } },
        { name => 'fans', type => 1, cb_prefix_output => 'prefix_fan_output', message_multiple => 'All fans are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} eq "noncritical"',
            critical_default => '%{status} eq "critical"',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'global health status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{sensors} = [
        { label => 'sensor-temperature', nlabel => 'hardware.sensor.temperature.celsius', set => {
                key_values => [ { name => 'temp' } ],
                output_template => 'temperature is %s C',
                perfdatas => [
                    { template => '%s', unit => 'C', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{fans} = [
        { label => 'fan-speed', nlabel => 'hardware.fan.speed.rpm', set => {
                key_values => [ { name => 'speed' } ],
                output_template => 'speed is %s rpm',
                perfdatas => [
                    { template => '%s', unit => 'rpm', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_status = {
        1 => 'ok', 2 => 'noncritical', 3 => 'critical'
    };

    my $branch = network::lenovo::rackswitch::snmp::mode::resources::find_rackswitch_branch(
        output => $self->{output}, snmp => $options{snmp}
    );
    my $oid_fan_speed = $branch . '.1.3.1.13.0'; # hwFanSpeed
    my $oid_temp_sensors = $branch . '.1.3.1.14.0'; # hwTempSensors
    my $oid_health_status = $branch . '.1.3.1.15.0'; # hwGlobalHealthStatus
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_fan_speed, $oid_temp_sensors, $oid_health_status],
        nothing_quit => 1
    );

    $self->{global} = { status => $map_status->{ $snmp_result->{$oid_health_status} } };
    $self->{sensors} = {};
    while ($snmp_result->{$oid_temp_sensors} =~ /Sensor\s+(\d+):\s*([0-9\.]+)/ig) {
        $self->{sensors}->{$1} = { temp => $2 };
    }

    $self->{fans} = {};
    while ($snmp_result->{$oid_fan_speed} =~ /Fan\s+(\d+):\s*([0-9\.]+)\s*RPM/ig) {
        $self->{fans}->{$1} = { speed => $2 };
    }
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} eq "noncritical"').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "critical"').
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'sensor-temperature', 'fan-speed'.

=back

=cut
