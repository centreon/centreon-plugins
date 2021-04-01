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

package hardware::sensors::netbotz::snmp::mode::components::humidity;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status);

sub load {
    my ($self) = @_;

    $self->{mapping_humidity} = {
        humiSensorId            => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.2.1.1' },
        humiSensorValue         => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.2.1.2' },
        humiSensorErrorStatus   => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.2.1.3', map => $map_status },
        humiSensorLabel         => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.2.1.4' }
    };
    $self->{oid_humiSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.2.1';
    push @{$self->{request}}, {
        oid => $self->{oid_humiSensorEntry},
        end => $self->{mapping_humidity}->{humiSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidities");
    $self->{components}->{humidity} = { name => 'humidity', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'humidity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_humiSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_humidity}->{humiSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_humidity},
            results => $self->{results}->{ $self->{oid_humiSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;

        $result->{humiSensorValue} *= 0.1;
        my $label = defined($result->{humiSensorLabel}) && $result->{humiSensorLabel} ne '' ? $result->{humiSensorLabel} : $result->{humiSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "humidity '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{humiSensorErrorStatus},
                $instance, 
                $result->{humiSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'humidity', value => $result->{humiSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Humidity '%s' status is '%s'",
                    $label,
                    $result->{humiSensorErrorStatus}
                )
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{humiSensorValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Humidity '%s' is %s %%",
                    $label,
                    $result->{humiSensorValue}
                )
            );
        }

        $self->{output}->perfdata_add(
            label => 'humidity', unit => '%',
            nlabel => 'hardware.sensor.humidity.percentage',
            instances => $label,
            value => $result->{humiSensorValue},
            warning => $warn,
            critical => $crit, min => 0, max => 100
        );
    }
}

1;
