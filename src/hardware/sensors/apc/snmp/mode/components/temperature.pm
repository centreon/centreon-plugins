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

package hardware::sensors::apc::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::apc::snmp::mode::components::resources qw($map_alarm_status $map_comm_status $map_comm_status3);

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

        $instance = 'module.' . $instance;

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
                    "Temperature '%s' is %s %s",
                    $name,
                    $result->{temp},
                    $self->{temp_unit}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.temperature.' . ($self->{temp_unit} eq 'C' ? 'celsius' : 'fahrenheit'),
            unit => $self->{temp_unit},
            instances => $name,
            value => $result->{temp},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check_wireless_temp {
    my ($self) = @_;

    my $oid_wirelessSensorStatusTable = '.1.3.6.1.4.1.318.1.1.10.5.1.1';
    my $oid_wirelessSensorStatusMinHumidityThresh = '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.15';
    my $mapping = {
        name        => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.3' }, # wirelessSensorStatusName
        temp        => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.5' }, # wirelessSensorStatusTemperature
        highWarn    => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.6' }, # wirelessSensorStatusHighTempThresh
        lowWarn     => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.7' }, # wirelessSensorStatusLowTempThresh
        commStatus  => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.11', map => $map_comm_status3 }, # wirelessSensorStatusCommStatus
        highCrit    => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.12' }, # wirelessSensorStatusHighTempThresh
        lowCrit     => { oid => '.1.3.6.1.4.1.318.1.1.10.5.1.1.1.13' }  # wirelessSensorStatusLowTempThresh
    };

    my $snmp_result = $self->{snmp_wireless_sensors};
    if ($self->{checked_wireless_sensors} == 0) {
        $self->{snmp_wireless_sensors} = $self->{snmp}->get_table(oid => $oid_wirelessSensorStatusTable, end => $oid_wirelessSensorStatusMinHumidityThresh);
        $self->{checked_wireless_sensors} = 1;
    }

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{snmp_wireless_sensors}})) {
        next if ($oid !~ /^$mapping->{commStatus}->{oid}\.(\d+)$/);

        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping,
            results => $self->{snmp_wireless_sensors},
            instance => $instance
        );

        $instance = 'wireless.' . $instance;

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        my $name = $result->{name};
        $result->{temp} *= 0.1;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is %s %s [instance: %s] [comm: %s]",
                $name,
                $result->{temp},
                $self->{temp_unit},
                $instance, 
                $result->{commStatus}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'temperature.comm', value => $result->{commStatus});
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
        if ($checked == 0) {
            my $warn_th = ($result->{lowWarn} * 0.1) . ':' . ($result->{highCrit} * 0.1);
            my $crit_th = ($result->{lowCrit} * 0.1) . ':' . ($result->{highCrit} * 0.1);
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{temp},
                threshold => [
                    { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Temperature '%s' is %s %s",
                    $name,
                    $result->{temp},
                    $self->{temp_unit}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.temperature.' . ($self->{temp_unit} eq 'C' ? 'celsius' : 'fahrenheit'),
            unit => $self->{temp_unit},
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
    check_wireless_temp($self);
}

1;
