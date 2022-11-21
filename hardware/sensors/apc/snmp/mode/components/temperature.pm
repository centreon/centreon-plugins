#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package hardware::sensors::apc::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::apc::snmp::mode::components::resources qw($map_alarm_status $map_comm_status);

sub load {}

sub check_module_temp {
    my ($self) = @_;

    my $oid_memSensorsStatusTable = '.1.3.6.1.4.1.318.1.1.10.4.2.3';
    my $mapping = {
        name        => { oid => '.1.3.6.1.4.1.318.1.1.10.4.2.3.1.3' }, # memSensorsStatusSensorName
        temp        => { oid => '.1.3.6.1.4.1.318.1.1.10.4.2.3.1.5' }, # memSensorsTemperature
        commStatus  => { oid => '.1.3.6.1.4.1.318.1.1.10.4.2.3.1.7', map => $map_comm_status }, # memSensorsCommStatus
        alarmStatus => { oid => '.1.3.6.1.4.1.318.1.1.10.4.2.3.1.8', map => $map_alarm_status } # memSensorsAlarmStatus
    };

    my $snmp_result = $self->{snmp_module_sensors};
    if ($self->{checked_module_sensors} == 0) {
        $self->{snmp_module_sensors} = $self->{snmp}->get_table(oid => $oid_memSensorsStatusTable);
        $self->{checked_module_sensors} = 1;
    }

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{snmp_module_sensors}})) {
        next if ($oid !~ /^$mapping->{alarmStatus}->{oid}\.(\d+)\.(\d+)$/);

        my $module_name = $self->{modules_name}->{$1};
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping,
            results => $self->{snmp_module_sensors},
            instance => $instance
        );

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        my $name = $module_name . ':' . $result->{name};
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' alarm status is %s [instance: %s] [value: %s] [comm: %s]",
                $name,
                $result->{alarmStatus},
                $instance, 
                $result->{temp},
                $result->{commStatus}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'temperature.alarm', value => $result->{alarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' alarm status is %s",
                    $name,
                    $result->{alarmStatus}
                )
            );
        }

        $exit = $self->get_severity(label => 'default', section => 'temperature.comm', value => $result->{commStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' communication status is %s",
                    $name,
                    $result->{commStatus}
                )
            );
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temp});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Temperature '%s' is %s C",
                    $name,
                    $result->{temp}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.temperature.celsius',
            unit => 'C',
            instances => $name,
            value => $result->{temp},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    check_module_temp($self);
}

1;
