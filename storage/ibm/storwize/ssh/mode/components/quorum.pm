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

package storage::ibm::storwize::ssh::mode::components::quorum;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{ssh_commands} .= 'echo "==========lsquorum=========="; lsquorum -delim : ; echo "===============";';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking quorums");
    $self->{components}->{quorum} = {name => 'quorums', total => 0, skip => 0};
    return if ($self->check_filter(section => 'quorum'));

    return if ($self->{results} !~ /==========lsquorum==.*?\n(.*?)==============/msi);
    my $content = $1;

    my $result = $self->{custom}->get_hasharray(content => $content, delim => ':');
    foreach (@$result) {
        next if ($self->check_filter(section => 'quorum', instance => $_->{quorum_index}));
        $self->{components}->{quorum}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "quorum '%s' status is '%s' [instance: %s].",
                $_->{controller_name},
                $_->{status},
                $_->{quorum_index}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'quorum', value => $_->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Quorum '%s' status is '%s'",
                    $_->{controller_name},
                    $_->{status}
                )
            );
        }
    }
}

1;
