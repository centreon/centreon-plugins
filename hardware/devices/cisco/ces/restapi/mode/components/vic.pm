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

package hardware::devices::cisco::ces::restapi::mode::components::vic;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking video input connectors');
    $self->{components}->{vic} = { name => 'video input connectors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'vic'));

    return if (!defined($self->{results}->{Video}->{Input}->{Connector}));

    foreach (@{$self->{results}->{Video}->{Input}->{Connector}}) {
        my $instance = $_->{Type} . ':' . $_->{item};

        next if ($self->check_filter(section => 'vic', instance => $instance));
        $self->{components}->{vic}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "video input connector '%s' connection status is '%s' [instance: %s, signal state: %s]",
                $instance,
                $_->{Connected},
                $instance,
                $_->{SignalState}
            )
        );

        my $exit = $self->get_severity(label => 'connected', section => 'vic.status', value => $_->{Connected});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("video input connector '%s' connection status is '%s'", $instance, $_->{Connected})
            );
        }

        $exit = $self->get_severity(label => 'signal_state', section => 'vic.signal_state', value => $_->{SignalState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("video input connector '%s' signal state is '%s'", $instance, $_->{SignalState})
            );
        }
    }
}

1;
