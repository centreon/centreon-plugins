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

package hardware::sensors::netbotz::snmp::mode::components::camera;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status $map_camera_value);

sub load {
    my ($self) = @_;

    $self->{mapping_camera} = {
        cameraMotionSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.3.1.1' },
        cameraMotionSensorValue       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.3.1.2', map => $map_camera_value },
        cameraMotionSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.3.1.3', map => $map_status },
        cameraMotionSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.3.1.4' }
    };
    $self->{oid_cameraMotionSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.3.1';
    push @{$self->{request}}, { 
        oid => $self->{oid_cameraMotionSensorEntry},
        end => $self->{mapping_camera}->{cameraMotionSensorLabel}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cameras");
    $self->{components}->{camera} = { name => 'cameras', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'camera'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_cameraMotionSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_camera}->{cameraMotionSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_camera},
            results => $self->{results}->{ $self->{oid_cameraMotionSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'camera', instance => $instance));
        $self->{components}->{camera}->{total}++;

        my $label = defined($result->{cameraMotionSensorLabel}) && $result->{cameraMotionSensorLabel} ne '' ? $result->{cameraMotionSensorLabel} : $result->{cameraMotionSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "camera motion '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{cameraMotionSensorErrorStatus},
                $instance, 
                $result->{cameraMotionSensorValue}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'camera', value => $result->{cameraMotionSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Camera motion '%s' status is '%s'",
                    $label,
                    $result->{cameraMotionSensorErrorStatus}
                )
            );
        }
    }
}

1;
