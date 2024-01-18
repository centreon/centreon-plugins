#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fnimged industry-strength solution that meets
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

package network::viptela::snmp::mode::components::nim;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nim");
    $self->{components}->{nim} = { name => 'nim', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'nim'));

    my ($exit, $warn, $crit, $checked);
    foreach (@{$self->{results}}) {
        next if ($_->{type} ne 'nim');
        my $instance = 'nim.' . $_->{name};
        next if ($self->check_filter(section => 'nim', instance => $instance));
        $self->{components}->{nim}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "nim '%s' status is '%s' [instance: %s]",
                $_->{name},
                $_->{status},
                $instance
            )
        );
        $exit = $self->get_severity(label => 'default', section => 'nim', value => $_->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("nim '%s' status is '%s'", $_->{name}, $_->{status})
            );
        }
    }
}

1;
