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

package snmp_standard::mode::components::sensors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_sensor_status = (
    1 => 'unknown', 2 => 'other',
    3 => 'ok', 4 => 'warning',
    5 => 'failed',
);

my %map_sensor_type = (
    1 => 'unknown', 2 => 'other',
    3 => 'battery', 4 => 'fan',
    5 => 'power-supply', 6 => 'transmitter',
    7 => 'enclosure', 8 => 'board', 9 => 'receiver',
);

my %map_sensor_chara = (
    1 => 'unknown', 2 => 'other',
    3 => 'temperature', 4 => 'pressure',
    5 => 'emf', 6 => 'currentValue', 7 => 'airflow',
    8 => 'frequency', 9 => 'power', 10 => 'door',
);

my $mapping = {
    connUnitSensorName            => { oid => '.1.3.6.1.3.94.1.8.1.3' },
    connUnitSensorStatus          => { oid => '.1.3.6.1.3.94.1.8.1.4', map => \%map_sensor_status },
    connUnitSensorMessage         => { oid => '.1.3.6.1.3.94.1.8.1.6' },
    connUnitSensorType            => { oid => '.1.3.6.1.3.94.1.8.1.7', map => \%map_sensor_type },
    connUnitSensorCharacteristic  => { oid => '.1.3.6.1.3.94.1.8.1.8', map => \%map_sensor_chara },
};
my $oid_connUnitSensorEntry = '.1.3.6.1.3.94.1.8.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_connUnitSensorEntry, start => $mapping->{connUnitSensorName}->{oid}, end => $mapping->{connUnitSensorCharacteristic}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking sensors");
    $self->{components}->{sensors} = { name => 'sensors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sensors'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_connUnitSensorEntry}})) {
        next if ($oid !~ /^$mapping->{connUnitSensorName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_connUnitSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sensors', instance => $instance, name => $result->{connUnitSensorName}));

        $self->{components}->{sensors}->{total}++;
        $self->{output}->output_add(long_msg => sprintf(
            "sensor '%s' status is %s [msg: %s] [type: %s] [chara: %s]",
            $result->{connUnitSensorName}, $result->{connUnitSensorStatus},
            $result->{connUnitSensorMessage}, $result->{connUnitSensorType}, $result->{connUnitSensorCharacteristic})
        );
        my $exit = $self->get_severity(section => 'sensors', name => $result->{connUnitSensorName}, value => $result->{connUnitSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Sensor '%s' status is %s",
                    $result->{connUnitSensorName},
                    $result->{connUnitSensorStatus}
                )
            );
        }
    }
}

1;