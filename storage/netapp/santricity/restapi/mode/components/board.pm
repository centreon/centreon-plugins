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

package storage::netapp::santricity::restapi::mode::components::board;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking boards');
    $self->{components}->{board} = { name => 'boards', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'board'));

    return if (!defined($self->{json_results}->{storages}));

    foreach (@{$self->{json_results}->{storages}}) {
        my $storage_name = $_->{name};

        next if ($self->check_filter(section => 'storage', instance => $_->{chassisSerialNumber}));
        
        next if (!defined($_->{'/hardware-inventory'}->{hostBoards}));

        foreach my $entry (@{$_->{'/hardware-inventory'}->{hostBoards}}) {
            my $instance = $entry->{hostBoardRef};
            my $name = $storage_name . ':' . $entry->{physicalLocation}->{locationPosition} . ':' . $entry->{physicalLocation}->{slot};

            next if ($self->check_filter(section => 'board', instance => $instance));
            $self->{components}->{board}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "board '%s' status is '%s' [instance = %s]",
                    $name, $entry->{status}, $instance
                )
            );

            my $exit = $self->get_severity(section => 'board', instance => $instance, value => $entry->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Board '%s' status is '%s'", $name, $entry->{status})
                );
            }
        }
    }
}

1;
