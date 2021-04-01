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

package storage::netapp::ontap::restapi::mode::components::fru;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fru');
    $self->{components}->{fru} = { name => 'frus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fru'));
    return if (!defined($self->{json_results}->{records}));

    foreach my $shelf (@{$self->{json_results}->{records}}) {
        my $shelf_instance = $shelf->{serial_number};
        my $shelf_name = $shelf->{name};

        next if ($self->check_filter(section => 'shelf', instance => $shelf_instance));

        foreach my $fru (@{$shelf->{frus}}) {
            my $instance = $fru->{serial_number};
            my $name = $fru->{type} . ':' . $fru->{id};

            next if ($self->check_filter(section => 'fru', instance => $instance));
            $self->{components}->{fru}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "fru '%s' shelf '%s' state is '%s' [shelf: %s, instance: %s]",
                    $name,
                    $shelf_name,
                    $fru->{state},
                    $shelf_instance,
                    $instance
                )
            );
            
            my $exit = $self->get_severity(label => 'state', section => 'fru', value => $fru->{state});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fru '%s' shelf '%s' state is '%s'",
                        $name,
                        $shelf_name,
                        $fru->{state}
                    )
                );
            }
        }
    }
}

1;
