#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package storage::purestorage::flashblade::v2::restapi::mode::components::fm;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fabric modules");
    $self->{components}->{fm} = { name => 'fm', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fm'));

    foreach my $item (@{$self->{results}}) {
        next if ($item->{type} ne 'fm');
        my $instance = defined($item->{index}) ? $item->{index} : $item->{slot};
        
        next if ($self->check_filter(section => 'fm', instance => $instance));
        $self->{components}->{fm}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fabric module '%s' status is %s [instance: %s]",
                $item->{name},
                $item->{status},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'fm', instance => $instance, value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fabric module '%s' status is %s", $item->{name}, $item->{status}
                )
            );
        }
    }
}

1;
