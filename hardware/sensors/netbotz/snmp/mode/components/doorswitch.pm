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

package hardware::sensors::netbotz::snmp::mode::components::doorswitch;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status $map_door_value);

sub load {
    my ($self) = @_;

    $self->{mapping_doorswitch} = {
        doorSwitchSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.2.1.1' },
        doorSwitchSensorValue       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.2.1.2', map => $map_door_value },
        doorSwitchSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.2.1.3', map => $map_status },
        doorSwitchSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.2.1.4' }
    };
    $self->{oid_doorSwitchSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.2.1';
    push @{$self->{request}}, {
        oid => $self->{oid_doorSwitchSensorEntry},
        end => $self->{mapping_doorswitch}->{doorSwitchSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking door switches");
    $self->{components}->{doorswitch} = { name => 'door switches', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'doorswitch'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_doorSwitchSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_doorswitch}->{doorSwitchSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_doorswitch},
            results => $self->{results}->{ $self->{oid_doorSwitchSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'doorswitch', instance => $instance));
        $self->{components}->{doorswitch}->{total}++;

        my $label = defined($result->{doorSwitchSensorLabel}) && $result->{doorSwitchSensorLabel} ne '' ? $result->{doorSwitchSensorLabel} : $result->{doorSwitchSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "door switch '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{doorSwitchSensorErrorStatus},
                $instance, 
                $result->{doorSwitchSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'doorswitch', value => $result->{doorSwitchSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Door switch '%s' status is '%s'",
                    $label,
                    $result->{doorSwitchSensorErrorStatus}
                )
            );
        }
    }
}

1;
