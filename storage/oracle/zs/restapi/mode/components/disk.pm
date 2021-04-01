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

package storage::oracle::zs::restapi::mode::components::disk;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    foreach my $chassis (values %{$self->{results}}) {
        foreach (@{$chassis->{disk}}) { 
            my $instance = $chassis->{name} . ':' . $_->{label};
            
            next if ($self->check_filter(section => 'disk', instance => $instance));
            $self->{components}->{disk}->{total}++;

            my $status = $_->{faulted} ? 'faulted' : 'ok';
            $self->{output}->output_add(
                long_msg => sprintf(
                    "disk '%s' status is '%s' [instance = %s]",
                    $instance, $status, $instance,
                )
            );

            my $exit = $self->get_severity(label => 'default', section => 'disk', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Disk '%s' status is '%s'", $instance, $status)
                );
            }
        }
    }
}

1;
