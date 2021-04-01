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

package storage::ibm::storwize::ssh::mode::components::enclosurepsu;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{ssh_commands} .= 'echo "==========lsenclosurepsu=========="; lsenclosurepsu -delim : ; echo "===============";';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosure psus");
    $self->{components}->{enclosurepsu} = {name => 'enclosure psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'enclosurepsu'));

    return if ($self->{results} !~ /==========lsenclosurepsu==.*?\n(.*?)==============/msi);
    my $content = $1;

    my $result = $self->{custom}->get_hasharray(content => $content, delim => ':');
    foreach (@$result) {
        my $instance = $_->{enclosure_id} . '.' . $_->{PSU_id};
        next if ($self->check_filter(section => 'enclosurepsu', instance => $instance));
        $self->{components}->{enclosurepsu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure power supply '%s' status is '%s' [instance: %s].",
                $instance,
                $_->{status},
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'enclosurepsu', value => $_->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Enclosure power supply '%s' status is '%s'",
                    $instance,
                    $_->{status}
                )
            );
        }
    }
}

1;
