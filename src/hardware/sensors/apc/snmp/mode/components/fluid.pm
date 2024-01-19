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

package hardware::sensors::apc::snmp::mode::components::fluid;

use strict;
use warnings;
use hardware::sensors::apc::snmp::mode::components::resources qw($map_alarm_status $map_comm_status2 $map_fluid_state);

sub load {}

sub check_module_fluid {
    my ($self) = @_;

    my $oid_memFluidSensorStatusTable = '.1.3.6.1.4.1.318.1.1.10.4.7.6';
    my $mapping = {
        name        => { oid => '.1.3.6.1.4.1.318.1.1.10.4.7.6.1.3' }, # memFluidSensorStatusSensorName
        state       => { oid => '.1.3.6.1.4.1.318.1.1.10.4.7.6.1.5', map => $map_fluid_state }, # memFluidSensorStatusSensorState
        alarmStatus => { oid => '.1.3.6.1.4.1.318.1.1.10.4.7.6.1.7', map => $map_alarm_status }, # memFluidStatusAlarmStatus
        commStatus  => { oid => '.1.3.6.1.4.1.318.1.1.10.4.7.6.1.8', map => $map_comm_status2 } # memFluidSensorCommStatus
    };

    my $snmp_result = $self->{snmp}->get_table(oid => $oid_memFluidSensorStatusTable);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{alarmStatus}->{oid}\.(\d+)\.(\d+)$/);

        my $module_name = $self->{modules_name}->{$1};
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        next if ($self->check_filter(section => 'fluid', instance => $instance));
        $self->{components}->{fluid}->{total}++;

        my $name = $module_name . ':' . $result->{name};
        $self->{output}->output_add(
            long_msg => sprintf(
                "fluid '%s' alarm status is %s [instance: %s] [state: %s] [comm: %s]",
                $name,
                $result->{alarmStatus},
                $instance, 
                $result->{state},
                $result->{commStatus}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'fluid.alarm', value => $result->{alarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fluid '%s' alarm status is %s",
                    $name,
                    $result->{alarmStatus}
                )
            );
        }

        $exit = $self->get_severity(label => 'default', section => 'fluid.comm', value => $result->{commStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fluid '%s' communication status is %s",
                    $name,
                    $result->{commStatus}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fluids");
    $self->{components}->{fluid} = { name => 'fluid', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fluid'));

    check_module_fluid($self);
}

1;
