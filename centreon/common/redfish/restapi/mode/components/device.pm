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

package centreon::common::redfish::restapi::mode::components::device;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking devices');
    $self->{components}->{device} = { name => 'devices', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'device'));

    $self->get_devices();

    foreach my $chassis (@{$self->{chassis}}) {
        my $chassis_name = 'chassis:' . $chassis->{Id};

        next if (!defined($chassis->{Devices}));

        foreach my $device (@{$chassis->{Devices}}) {
            my $device_name = $device->{Name};
            my $instance = $chassis->{Id} . '.' . $device->{Id};

            $device->{Status}->{Health} = defined($device->{Status}->{Health}) ? $device->{Status}->{Health} : 'n/a';
            $device->{Status}->{State} = defined($device->{Status}->{State}) ? $device->{Status}->{State} : 'n/a';
            next if ($self->check_filter(section => 'device', instance => $instance));
            $self->{components}->{device}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "device '%s/%s' status is '%s' [instance: %s, state: %s]",
                    $chassis_name, $device_name, $device->{Status}->{Health}, $instance, $device->{Status}->{State}
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'device.state', value => $device->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Device '%s/%s' state is '%s'", $chassis_name, $device_name, $device->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'device.status', value => $device->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Device '%s/%s' status is '%s'", $chassis_name, $device_name, $device->{Status}->{Health})
                );
            }
        }
    }
}

1;
