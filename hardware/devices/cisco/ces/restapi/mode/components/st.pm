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

package hardware::devices::cisco::ces::restapi::mode::components::st;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking speaker track');
    $self->{components}->{st} = { name => 'speaker track', total => 0, skip => 0 }  ;
    return if ($self->check_filter(section => 'st'));

    return if (!defined($self->{results}->{Cameras}->{SpeakerTrack}));

    my $instance = 1;
    return if ($self->check_filter(section => 'st', instance => $instance));
    $self->{components}->{st}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "speaker track '%s' status is '%s' [instance: %s, availability: %s]",
            $instance,
            $self->{results}->{Cameras}->{SpeakerTrack}->{Status},
            $instance,
            $self->{results}->{Cameras}->{SpeakerTrack}->{Availability}
        )
    );

    my $exit = $self->get_severity(section => 'st_status', value => $self->{results}->{Cameras}->{SpeakerTrack}->{Status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("speaker track '%s' status is '%s'", $instance, $self->{results}->{Cameras}->{SpeakerTrack}->{Status})
        );
    }

    $exit = $self->get_severity(section => 'st_availability', value => $self->{results}->{Cameras}->{SpeakerTrack}->{Availability});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("speaker track '%s' availability is '%s'", $instance, $self->{results}->{Cameras}->{SpeakerTrack}->{Availability})
        );
    }
}

1;
