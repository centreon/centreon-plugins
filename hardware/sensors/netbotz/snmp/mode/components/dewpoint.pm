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

package hardware::sensors::netbotz::snmp::mode::components::dewpoint;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status);

sub load {
    my ($self) = @_;

    $self->{mapping_dewpoint} = {
        dewPointSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.3.1.1' },
        dewPointSensorValue       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.3.1.2' },
        dewPointSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.3.1.3', map => $map_status },
        dewPointSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.3.1.4' }
    };
    $self->{oid_dewPointSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.1.3.1';
    push @{$self->{request}}, {
        oid => $self->{oid_dewPointSensorEntry},
        end => $self->{mapping_dewpoint}->{dewPointSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking dew points");
    $self->{components}->{dewpoint} = { name => 'dew points', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'dewpoint'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_dewPointSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_dewpoint}->{dewPointSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_dewpoint},
            results => $self->{results}->{ $self->{oid_dewPointSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'dewpoint', instance => $instance));
        $self->{components}->{dewpoint}->{total}++;

        $result->{dewPointSensorValue} *= 0.1;
        my $label = defined($result->{dewPointSensorLabel}) && $result->{dewPointSensorLabel} ne '' ? $result->{dewPointSensorLabel} : $result->{dewPointSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "dew point '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{dewPointSensorErrorStatus},
                $instance, 
                $result->{dewPointSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'dewpoint', value => $result->{dewPointSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Dew point '%s' status is '%s'",
                    $label,
                    $result->{dewPointSensorErrorStatus}
                )
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'dewpoint', instance => $instance, value => $result->{dewPointSensorValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Dew point '%s' is %s C",
                    $label,
                    $result->{dewPointSensorValue}
                )
            );
        }

        $self->{output}->perfdata_add(
            label => 'dewpoint', unit => 'C',
            nlabel => 'hardware.sensor.dewpoint.celsius',
            instances => $label,
            value => $result->{dewPointSensorValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
