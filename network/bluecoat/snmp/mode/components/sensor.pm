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

package network::bluecoat::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_status = (
    1 => 'ok', 
    2 => 'unavailable', 
    3 => 'nonoperational', 
);
my %map_code = (
    1 => 'ok',
    2 => 'unknown',
    3 => 'notInstalled',
    4 => 'voltageLowWarning',
    5 => 'voltageLowCritical',
    6 => 'noPower',
    7 => 'voltageHighWarning',
    8 => 'voltageHighCritical',
    9 => 'voltageHighSevere',
    10 => 'temperatureHighWarning',
    11 => 'temperatureHighCritical',
    12 => 'temperatureHighSevere',
    13 => 'fanSlowWarning',
    14 => 'fanSlowCritical',
    15 => 'fanStopped',
);
my %map_units = (
    1 => { unit => '', nunit => '' }, # other
    2 => { unit => '', nunit => '' }, # truthvalue
    3 => { unit => '', nunit => '' }, # specialEnum
    4 => { unit => 'V', nunit => 'voltage.volt' }, # volts
    5 => { unit => 'C', nunit => 'temperature.celsius' }, # celsius
    6 => { unit => 'rpm', nunit => 'speed.rpm' },
);

# In MIB 'BLUECOAT-SG-SENSOR-MIB'
my $mapping = {
    deviceSensorUnits   => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.3', map => \%map_units },
    deviceSensorScale   => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.4' },
    deviceSensorValue   => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.5' },
    deviceSensorCode    => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.6', map => \%map_code },
    deviceSensorStatus  => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.7', map => \%map_status },
    deviceSensorName    => { oid => '.1.3.6.1.4.1.3417.2.1.1.1.1.1.9' },
};
my $oid_deviceSensorValueEntry = '.1.3.6.1.4.1.3417.2.1.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_deviceSensorValueEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_deviceSensorValueEntry}})) {
        next if ($oid !~ /^$mapping->{deviceSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_deviceSensorValueEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'sensor', instance => $instance));
        $self->{components}->{sensor}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' status is '%s' [instance: %s, operational status: %s, value: %s, scale: %s, unit: %s]", 
                                    $result->{deviceSensorName}, $result->{deviceSensorCode}, 
                                    $instance, $result->{deviceSensorStatus}, $result->{deviceSensorValue}, $result->{deviceSensorScale},
                                    $result->{deviceSensorUnits}->{unit}));
        my $exit = $self->get_severity(section => 'sensor_opstatus', value => $result->{deviceSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' operational status is %s", 
                                                            $result->{deviceSensorName}, $result->{deviceSensorStatus}));
        }
        $exit = $self->get_severity(section => 'sensor', value => $result->{deviceSensorCode});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' status is %s", 
                                                             $result->{deviceSensorName}, $result->{deviceSensorCode}));
        }
        
        if (defined($result->{deviceSensorValue}) && $result->{deviceSensorValue} =~ /[0-9]/ && $result->{deviceSensorUnits}->{unit} ne '') {
            my $value = ($result->{deviceSensorValue} * (10 ** $result->{deviceSensorScale}));
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensor', instance => $instance, value => $value);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Sensor '%s' value is %s %s", $result->{deviceSensorName}, $value, $result->{deviceSensorUnits}->{unit}));
            }
            
            $self->{output}->perfdata_add(
                label => 'sensor', unit => $result->{deviceSensorUnits}->{unit},
                nlabel => 'hardware.sensor.' . $result->{deviceSensorUnits}->{nunit},
                instances => $result->{deviceSensorName},
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
