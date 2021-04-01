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

package storage::nimble::restapi::mode::components::disk;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{requests}->{disk} = '/v1/disks/detail';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    return if (!defined($self->{results}->{disk}));

    foreach (@{$self->{results}->{disk}->{data}}) {
        my $instance = $_->{serial};
        
        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' array '%s' shelf '%s' state is '%s' [instance = %s] [raid state: %s]",
                $instance, 
                $_->{array_name},
                $_->{shelf_location},
                $_->{state}, 
                $instance,
                $_->{raid_state}
            )
        );

        my $exit = $self->get_severity(section => 'disk', value => $_->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Disk '%s' array '%s' shelf '%s' state is '%s'",
                    $instance,
                    $_->{array_name},
                    $_->{shelf_location},
                    $_->{state}
                )
            );
        }

        $exit = $self->get_severity(section => 'raid', value => $_->{raid_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Disk '%s' array '%s' shelf '%s' raid state is '%s'",
                    $instance,
                    $_->{array_name},
                    $_->{shelf_location},
                    $_->{raid_state}
                )
            );
        }
    }
}

1;
