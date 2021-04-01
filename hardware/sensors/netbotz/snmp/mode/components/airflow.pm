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

package hardware::sensors::netbotz::snmp::mode::components::airflow;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status);

sub load {
    my ($self) = @_;

    $self->{mapping_airflow} = {
        airFlowSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.5.1.1' },
        airFlowSensorValue       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.5.1.2' },
        airFlowSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.5.1.3', map => $map_status },
        airFlowSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.5.1.4' }
    };
    $self->{oid_airFlowSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.5.1';
    push @{$self->{request}}, {
        oid => $self->{oid_airFlowSensorEntry},
        end => $self->{mapping_airflow}->{airFlowSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking air flows");
    $self->{components}->{airflow} = { name => 'air flows', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'airflow'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_airFlowSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_airflow}->{airFlowSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_airflow},
            results => $self->{results}->{ $self->{oid_airFlowSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'airflow', instance => $instance));
        $self->{components}->{airflow}->{total}++;

        $result->{airFlowSensorValue} *= 0.1;
        my $label = defined($result->{airFlowSensorLabel}) && $result->{airFlowSensorLabel} ne '' ? $result->{airFlowSensorLabel} : $result->{airFlowSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "air flow '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{airFlowSensorErrorStatus},
                $instance, 
                $result->{airFlowSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'airflow', value => $result->{airFlowSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Air flow '%s' status is '%s'",
                    $label,
                    $result->{airFlowSensorErrorStatus}
                )
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'airflow', instance => $instance, value => $result->{airFlowSensorValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Air flow '%s' is %s m/min",
                    $label,
                    $result->{airFlowSensorValue}
                )
            );
        }

        $self->{output}->perfdata_add(
            label => 'airflow', unit => 'm/min',
            nlabel => 'hardware.sensor.airflow.cubicmeterperminute',
            instances => $label,
            value => $result->{airFlowSensorValue},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
