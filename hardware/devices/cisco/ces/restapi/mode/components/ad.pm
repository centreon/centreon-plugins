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

package hardware::devices::cisco::ces::restapi::mode::components::ad;

use strict;
use warnings;

sub check_ad {
    my ($self, %options) = @_;

    return if (!defined($options{entry}));

    my $instance = $options{instance};
    next if ($self->check_filter(section => 'ad', instance => $instance));
    $self->{components}->{ad}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "audio device '%s' connection status is '%s' [instance: %s]",
            $instance, $options{entry}->{ConnectionStatus}, $instance
        )
    );

    my $exit = $self->get_severity(label => 'connection_status', section => 'ad.status', value => $options{entry}->{ConnectionStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("audio device '%s' connection status is '%s'", $instance, $options{entry}->{ConnectionStatus})
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking audio devices');
    $self->{components}->{ad} = { name => 'audio devices', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'ad'));

    # since CE 9.8
    check_ad(
        $self,
        entry => $self->{results}->{Audio}->{Devices}->{HandsetUSB},
        instance => 'handsetUSB'
    );
    # since CE 9.8
    check_ad(
        $self,
        entry => $self->{results}->{Audio}->{Devices}->{HeadsetUSB},
        instance => 'headsetUSB'
    );
}

1;
