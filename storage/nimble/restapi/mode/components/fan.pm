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

package storage::nimble::restapi::mode::components::fan;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{requests}->{shelve} = '/v1/shelves/detail';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    return if (!defined($self->{results}->{shelve}));

    foreach my $array (@{$self->{results}->{shelve}->{data}}) {
        my $array_name = $array->{array_name};
        $array_name .= ':' . $array->{serial} if ($self->use_serial());

        foreach my $ctrl (@{$array->{ctrlrs}}) {
            foreach my $sensor (@{$ctrl->{ctrlr_sensors}}) {
                next if ($sensor->{type} ne 'fan');

                my $instance = $sensor->{cid} . ':' . $sensor->{name};
    
                next if ($self->check_filter(section => 'fan', instance => $instance));
                $self->{components}->{fan}->{total}++;

                $self->{output}->output_add(
                    long_msg => sprintf(
                        "fan '%s' array '%s' status is '%s' [instance = %s, value = %s]",
                        $instance, 
                        $array_name,
                        $sensor->{status}, 
                        $instance,
                        $sensor->{value}
                    )
                );

                my $exit = $self->get_severity(label => 'sensor', section => 'fan', value => $sensor->{status});
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(
                        severity => $exit,
                        short_msg => sprintf(
                            "Fan '%s' array '%s' status is '%s'",
                            $instance,
                            $array_name,
                            $sensor->{status}
                        )
                    );
                }

                my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $sensor->{value});
                if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(
                        severity => $exit2,
                        short_msg => sprintf("fan '%s' array '%s' speed is %s rpm", $instance, $array_name, $sensor->{value})
                    );
                }
                $self->{output}->perfdata_add(
                    nlabel => 'hardware.sensor.fan.speed.rpm',
                    unit => 'rpm',
                    instances => [$array_name, $instance],
                    value => $sensor->{value},
                    warning => $warn,
                    critical => $crit,
                    min => 0
                );
            }
        }
    }
}

1;
