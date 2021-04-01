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

package storage::netapp::ontap::restapi::mode::components::bay;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking bays');
    $self->{components}->{bay} = { name => 'bays', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'bay'));
    return if (!defined($self->{json_results}->{records}));

    foreach my $shelf (@{$self->{json_results}->{records}}) {
        my $shelf_instance = $shelf->{serial_number};
        my $shelf_name = $shelf->{name};

        next if ($self->check_filter(section => 'shelf', instance => $shelf_instance));

        foreach my $bay (@{$shelf->{bays}}) {
            my $instance = $bay->{id};
            my $name = $bay->{id};

            next if ($self->check_filter(section => 'bay', instance => $instance));
            $self->{components}->{bay}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "bay '%s' shelf '%s' state is '%s' [shelf: %s, instance: %s]",
                    $name,
                    $shelf_name,
                    $bay->{state},
                    $shelf_instance,
                    $instance
                )
            );
            
            my $exit = $self->get_severity(label => 'state', section => 'bay', value => $bay->{state});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Bay '%s' shelf '%s' state is '%s'",
                        $name,
                        $shelf_name,
                        $bay->{state}
                    )
                );
            }
        }
    }
}

1;
