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

package centreon::common::cisco::smallbusiness::snmp::mode::components::temperature;

use strict;
use warnings;
use centreon::common::cisco::smallbusiness::snmp::mode::components::resources qw($oid_rlPhdUnitEnvParamEntry);

my $map_entity_sensor = { 1 => 'ok', 2 => 'unavailable', 3 => 'nonoperational' };

my $mapping = {
    new => {
        rlPhdUnitEnvParamTempSensorValue                  => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.10' },
        rlPhdUnitEnvParamTempSensorStatus                 => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.11', map => $map_entity_sensor },
        rlPhdUnitEnvParamTempSensorWarningThresholdValue  => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.12' },
        rlPhdUnitEnvParamTempSensorCriticalThresholdValue => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.13' }
    },
    old => {
        rlPhdUnitEnvParamTempSensorValue  => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.9' },
        rlPhdUnitEnvParamTempSensorStatus => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.10', map => $map_entity_sensor },
    }
};

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rlPhdUnitEnvParamEntry}})) {
        next if ($oid !~ /^$mapping->{new}->{rlPhdUnitEnvParamTempSensorValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{sb_new} == 1 ? $mapping->{new} : $mapping->{old},
            results => $self->{results}->{$oid_rlPhdUnitEnvParamEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance = %s, value: %s degree centigrade]",
                $instance,
                $result->{rlPhdUnitEnvParamTempSensorStatus},
                $instance,
                $result->{rlPhdUnitEnvParamTempSensorValue}
            )
        );

        my $exit = $self->get_severity(section => 'temperature', value => $result->{rlPhdUnitEnvParamTempSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' status is '%s'",
                    $instance,
                    $result->{rlPhdUnitEnvParamTempSensorStatus}
                )
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{rlPhdUnitEnvParamTempSensorValue});
        if ($checked == 0 && defined($result->{rlPhdUnitEnvParamTempSensorWarningThresholdValue})) {
            my $warn_th = ':' . $result->{rlPhdUnitEnvParamTempSensorWarningThresholdValue};
            my $crit_th = ':' . $result->{rlPhdUnitEnvParamTempSensorCriticalThresholdValue};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $exit2 = $self->{perfdata}->threshold_check(
                value => $result->{rlPhdUnitEnvParamTempSensorValue}, 
                threshold => [
                    { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Temperature '%s' is %s degree centigrade",
                    $instance,
                    $result->{rlPhdUnitEnvParamTempSensorValue}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance,
            value => $result->{rlPhdUnitEnvParamTempSensorValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
