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

package hardware::devices::cisco::ces::restapi::mode::components::camera;

use strict;
use warnings;

#<Camera item="1">
#    <Capabilities item="1">
#      <Options item="1">ptzf</Options>
#    </Capabilities>
#    <Connected item="1">True</Connected>
#    ...
#</Camera>
#

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking cameras');
    $self->{components}->{camera} = { name => 'cameras', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'camera'));

    my $cameras = defined($self->{results}->{Cameras}->{Camera}) ? $self->{results}->{Cameras}->{Camera} : $self->{results}->{Camera};

    return if (!$cameras);

    foreach (@$cameras) {
        my $instance = $_->{item};

        next if ($self->check_filter(section => 'camera', instance => $instance));
        $self->{components}->{camera}->{total}++;

        my $connected = ref($_->{Connected}) eq 'HASH' ? $_->{Connected}->{content} : $_->{Connected};

        $self->{output}->output_add(
            long_msg => sprintf(
                "camera '%s' connection status is '%s' [instance: %s]",
                $instance,
                $connected,
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'connected', section => 'camera.status', value => $connected);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("camera '%s' connection status is '%s'", $instance, $connected)
            );
        }
    }
}

1;
