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

package hardware::sensors::netbotz::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status);

sub load {
    my ($self) = @_;

    $self->{mapping_temperature} = {
        tempSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.1.1.1' },
        tempSensorValue       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.1.1.2' },
        tempSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.1.1.3', map => $map_status },
        tempSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.1.1.4' },
    };
    $self->{oid_tempSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.1.1';
    push @{$self->{request}}, {
        oid => $self->{oid_tempSensorEntry},
        end => $self->{mapping_temperature}->{tempSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_tempSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_temperature}->{tempSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_temperature},
            results => $self->{results}->{ $self->{oid_tempSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{tempSensorValue} *= 0.1;
        my $label = defined($result->{tempSensorLabel}) && $result->{tempSensorLabel} ne '' ? $result->{tempSensorLabel} : $result->{tempSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{tempSensorErrorStatus},
                $instance, 
                $result->{tempSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{tempSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' status is '%s'",
                    $label,
                    $result->{tempSensorErrorStatus}
                )
            );
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{tempSensorValue});
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Temperature '%s' is %s C",
                    $label,
                    $result->{tempSensorValue}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.sensor.temperature.celsius',
            instances => $label,
            value => $result->{tempSensorValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
