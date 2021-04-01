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

package hardware::devices::cisco::ces::restapi::mode::components::voc;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking video output connectors');
    $self->{components}->{voc} = { name => 'video output connectors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voc'));

    return if (!defined($self->{results}->{Video}->{Output}->{Connector}));

    foreach (@{$self->{results}->{Video}->{Output}->{Connector}}) {
        my $instance = $_->{Type} . ':' . $_->{item};

        next if ($self->check_filter(section => 'voc', instance => $instance));
        $self->{components}->{vic}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "video output connector '%s' connection status is '%s' [instance: %s]",
                $instance,
                $_->{Connected},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'connected', section => 'voc.status', value => $_->{Connected});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("video output connector '%s' connection status is '%s'", $instance, $_->{Connected})
            );
        }
    }
}

1;
