#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::brocade::snmp::mode::components::sensor;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_status = (
    1 => 'unknown',
    2 => 'faulty',
    3 => 'below-min',
    4 => 'nominal',
    5 => 'above-max',
    6 => 'absent'
);

my %map_type = (
    1 => 'temperature',
    2 => 'fan',
    3 => 'power-supply'
);

my %map_unit = (
    temperature => 'celsius',
    fan => 'rpm'
); # No voltage value available

# For sensor Brocade 5480 switches - FCMGMT-MIB
my %map_status2 = (
    1 => 'unknown',
    2 => 'other',
    3 => 'ok',
    4 => 'warning',
    5 => 'failes'
);

# For sensor Brocade 5480 switches - FCMGMT-MIB
my %map_type2 = (
    1 => 'unknown',
    2 => 'other',
    3 => 'battery',
    4 => 'fan',
    5 => 'power-supply',
    6 => 'transmitter',
    7 => 'enclosure',
    8 => 'board',
    9 => 'receiver'
);

# For sensor Brocade 5480 switches - FCMGMT-MIB
my %map_characteristic2 = (
    1 => 'unknown',
    2 => 'other',
    3 => 'temperature',
    4 => 'pressure',
    5 => 'emf',
    6 => 'currentValue',
    7 => 'airflow',
    8 => 'frequency',
    9 => 'power',
    10 => 'door'
);

# For sensor Brocade 5480 switches - FCMGMT-MIB (should be enhance)
my %map_unit2 = (
    temperature => 'celsius',
);

my $mapping = {
    swSensorType    => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.2', map => \%map_type },
    swSensorStatus  => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.3', map => \%map_status },
    swSensorValue   => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.4' },
    swSensorInfo    => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.5' }
};
my $oid_swSensorEntry = '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1';

# For sensor Brocade 5480 switches - FCMGMT-MIB
my $mapping2 = {
    connUnitSensorType           => { oid => '.1.3.6.1.3.94.1.8.1.7', map => \%map_type2 },
    connUnitSensorStatus         => { oid => '.1.3.6.1.3.94.1.8.1.4', map => \%map_status2 },
    connUnitSensorCharacteristic => { oid => '.1.3.6.1.3.94.1.8.1.8', map => \%map_characteristic2 },
    connUnitSensorMessage        => { oid => '.1.3.6.1.3.94.1.8.1.6' },
    connUnitSensorName           => { oid => '.1.3.6.1.3.94.1.8.1.3' }
};
my $oid_connUnitSensorEntry = '.1.3.6.1.3.94.1.8.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_swSensorEntry };
    push @{$self->{request}}, { oid => $oid_connUnitSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    # Regular sensor
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swSensorEntry}})) {
        next if ($oid !~ /^$mapping->{swSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_swSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sensor', instance => $instance));
        next if ($result->{swSensorStatus} =~ /absent/i &&
                 $self->absent_problem(section => 'sensor', instance => $instance));

        $result->{swSensorInfo} = centreon::plugins::misc::trim($result->{swSensorInfo});
        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "%s sensor '%s' status is '%s' [instance = %s]",
                $result->{swSensorType}, $result->{swSensorInfo}, $result->{swSensorStatus}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'sensor', value => $result->{swSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("%s sensor '%s' status is '%s'", $result->{swSensorType}, $result->{swSensorInfo}, $result->{swSensorStatus})
            );
        }

        if ($result->{swSensorValue} > 0 && $result->{swSensorType} ne 'power-supply') {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $result->{swSensorType}, instance => $instance, value => $result->{swSensorValue});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "%s sensor '%s' is %s %s",
                        $result->{swSensorType}, $result->{swSensorInfo}, $result->{swSensorValue},
                        $map_unit{$result->{swSensorType}}
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.sensor.' . $result->{swSensorType} . '.' . $map_unit{$result->{swSensorType}},
                unit => $map_unit{$result->{swSensorType}},
                instances => $result->{swSensorInfo},
                value => $result->{swSensorValue},
                warning => $warn,
                critical => $crit
            );
        }
    }

    # sensor Brocade 5480 switches - FCMGMT-MIB
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_connUnitSensorEntry}})) {
        next if ($oid !~ /^$mapping2->{connUnitSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_connUnitSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sensor', instance => $instance));

        $result->{connUnitSensorName} = centreon::plugins::misc::trim($result->{connUnitSensorName});
        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "%s sensor '%s' status is '%s' [instance = %s]",
                $result->{connUnitSensorType}, $result->{connUnitSensorName}, $result->{connUnitSensorStatus}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'sensor', value => $result->{connUnitSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("%s sensor '%s' status is '%s'", $result->{connUnitSensorType}, $result->{connUnitSensorName}, $result->{connUnitSensorStatus})
            );
        }

        my $sensor_value = 0+ ($result->{connUnitSensorMessage}=~ /value is\s*(\d+)/)[0];

        if (defined($sensor_value)) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $result->{connUnitSensorCharacteristic}, instance => $instance, value => $sensor_value);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "%s sensor '%s' is %s %s",
                        $result->{connUnitSensorType}, $result->{connUnitSensorName}, $sensor_value,
                        $map_unit2{$result->{connUnitSensorCharacteristic}}
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.sensor.' . $result->{connUnitSensorType} . '.' . $result->{connUnitSensorCharacteristic}. '.' . $map_unit2{$result->{connUnitSensorCharacteristic}},
                unit => $map_unit2{$result->{connUnitSensorCharacteristic}},
                instances => $result->{connUnitSensorName},
                value => $sensor_value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;