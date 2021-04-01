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

package centreon::common::sun::snmp::mode::components::entity;

use strict;
use warnings;

my %map_class = (
    1 => 'other', 2 => 'unknown', 3 => 'chassis',
    4 => 'backplane', 5 => 'container', 6 => 'powerSupply',
    7 => 'fan', 8 => 'sensor', 9 => 'module', 
    10 => 'port', 11 => 'stack',
);
my %map_oper_state = (1 => 'disabled', 2 => 'enabled');
my %map_alarm = (
    1 => 'critical', 2 => 'major', 3 => 'minor', 4 => 'indeterminate',
    5 => 'warning', 6 => 'pending', 7 => 'cleared'
);
my %map_sensor_type = (1 => 'other',
    2 => 'unknown', 3 => 'temperature', 4 => 'voltage', 5 => 'current', 6 => 'tachometer',
    7 => 'counter', 8 => 'switch', 9 => 'lock', 10 => 'humidity',
    11 => 'smokeDetection', 12 => 'presence', 13 => 'airFlow');
my %mapping_units = (
    1 => 'unknown', 2 => 'unknown',
    3 => 'celsius',
    4 => 'fahrenheit',
    5 => 'kelvin',
    6 => 'volt',
    7 => 'ampere',
    8 => 'watt',
    9 => 'Joules', 10 => 'Coulombs', 11 => 'VA', 12 => 'Nits',
    13 => 'Lumens', 14 => 'Lux', 15 => 'Candelas',
    16 => 'kPa', 17 => 'PSI', 18 => 'Newtons',
    19 => 'CFM', 20 => 'rpm',
    21 => 'Hz', # Hertz
    22 => 'Seconds', 23 => 'Minutes', 24 => 'Hours',
    25 => 'Days', 26 => 'Weeks', 27 => 'Mils',
    28 => 'Inches', 29 => 'Feet', 30 => 'Cubic_Inches',
    31 => 'CubicFeet', 32 => 'Meters', 33 => 'CubicCentimeters',
    34 => 'CubicMeters', 35 => 'Liters', 36 => 'FluidOunces',
    37 => 'Radians', 38 => 'Steradians', 39 => 'Revolutions',
    40 => 'Cycles', 41 => 'Gravities', 42 => 'Ounces',
    43 => 'Pounds', 44 => 'FootPounds', 45 => 'OunceInches',
    46 => 'Gauss', 47 => 'Gilberts', 48 => 'Henries',
    49 => 'Farads', 50 => 'Ohms', 51 => 'Siemens',
    52 => 'Moles', 53 => 'Becquerels', 54 => 'PPM',
    55 => 'Decibels', 56 => 'DbA', 57 => 'DbC',
    58 => 'Grays', 59 => 'Sieverts', 60 => 'ColorTemperatureDegreesKelvin',
    61 => 'bits',
    62 => 'bytes',
    63 => 'Words', 64 => 'DoubleWords', 65 => 'QuadWords',
    66 => 'percentage',
    67 => 'Pascals',
);

my $mapping = {
    entPhysicalClass                    => { oid => '.1.3.6.1.2.1.47.1.1.1.1.5', map => \%map_class },
    entPhysicalName                     => { oid => '.1.3.6.1.2.1.47.1.1.1.1.7' },
    sunPlatEquipmentOperationalState    => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.2.1.2', map => \%map_oper_state },
    sunPlatEquipmentAlarmStatus         => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.2.1.3', map => \%map_alarm },
    sunPlatSensorType                   => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.6.1.2', map => \%map_sensor_type },
    sunPlatNumericSensorBaseUnits       => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.8.1.1', map => \%mapping_units },
    sunPlatNumericSensorExponent        => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.8.1.2' },
    sunPlatNumericSensorCurrent         => { oid => '.1.3.6.1.4.1.42.2.70.101.1.1.8.1.4' },
};
my $oid_sunPlatEquipmentEntry = '.1.3.6.1.4.1.42.2.70.101.1.1.2.1';
my $oid_sunPlatNumericSensorEntry = '.1.3.6.1.4.1.42.2.70.101.1.1.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{entPhysicalName}->{oid} }, { oid => $mapping->{entPhysicalClass}->{oid} },
        { oid => $oid_sunPlatEquipmentEntry }, { oid => $oid_sunPlatNumericSensorEntry },
        { oid => $mapping->{sunPlatSensorType}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking entities");
    $self->{components}->{entity} = {name => 'entity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'entity'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$mapping->{entPhysicalName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        next if ($self->check_filter(section => 'entity', instance => $result->{entPhysicalClass} . '.' . $instance));
        next if ($result->{sunPlatEquipmentOperationalState} eq 'disabled');

        if (defined($result->{sunPlatNumericSensorCurrent})) {
            $result->{sunPlatNumericSensorCurrent} *= 10 ** $result->{sunPlatNumericSensorExponent}
        }
        
        $self->{components}->{entity}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("%s '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{entPhysicalClass}, $result->{entPhysicalName}, 
                                                        $result->{sunPlatEquipmentAlarmStatus}, $result->{entPhysicalClass} . '.' . $instance,
                                                        defined($result->{sunPlatNumericSensorCurrent}) ? $result->{sunPlatNumericSensorCurrent} : '-'));
        $exit = $self->get_severity(label => 'default', section => 'entity', instance => $result->{entPhysicalClass} . '.' . $instance, value => $result->{sunPlatEquipmentAlarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s '%s' status is '%s'", $result->{entPhysicalClass}, $result->{entPhysicalName}, $result->{sunPlatEquipmentAlarmStatus}));
        }
        
        next if (!defined($result->{sunPlatNumericSensorCurrent}));
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => $result->{sunPlatSensorType}, instance => $result->{entPhysicalClass} . '.' . $instance,, value => $result->{sunPlatNumericSensorCurrent});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s '%s' is '%s' %s", $result->{sunPlatSensorType}, 
                                            $result->{entPhysicalName}, $result->{sunPlatNumericSensorCurrent}, $result->{sunPlatNumericSensorBaseUnits}));
        }
        $self->{output}->perfdata_add(
            label => $result->{sunPlatSensorType}, unit => $result->{sunPlatNumericSensorBaseUnits},
            nlabel => 'hardware.entity.' . $result->{sunPlatSensorType} . '.' . lc($result->{sunPlatNumericSensorBaseUnits}),
            instances => $result->{entPhysicalName},
            value => $result->{sunPlatNumericSensorCurrent},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
