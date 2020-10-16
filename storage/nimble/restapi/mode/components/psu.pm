#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package storage::nimble::restapi::mode::components::psu;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{requests}->{shelve} = '/v1/shelves/detail';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    return if (!defined($self->{results}->{shelve}));

    foreach my $array (@{$self->{results}->{shelve}->{data}}) {
        my $array_name = $array->{array_name};
        $array_name .= ':' . $array->{serial} if ($self->use_serial());

        foreach my $sensor (@{$array->{chassis_sensors}}) {
            next if ($sensor->{type} ne 'power supply');

            my $instance = $sensor->{cid} . ':' . $sensor->{name};

            next if ($self->check_filter(section => 'psu', instance => $instance));
            $self->{components}->{psu}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s' array '%s' status is '%s' [instance = %s]",
                    $instance, 
                    $array_name,
                    $sensor->{status}, 
                    $instance
                )
            );

            my $exit = $self->get_severity(label => 'sensor', section => 'psu', value => $sensor->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Power supply '%s' array '%s' status is '%s'",
                        $instance,
                        $array_name,
                        $sensor->{status}
                    )
                );
            }
        }
    }
}

1;
