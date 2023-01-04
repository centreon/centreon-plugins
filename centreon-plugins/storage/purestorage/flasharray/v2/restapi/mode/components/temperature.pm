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

package storage::purestorage::flasharray::v2::restapi::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $item (@{$self->{results}}) {
        next if ($item->{type} ne 'temp_sensor');
        my $instance = $item->{index};
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is %s [instance: %s] [value: %s]",
                $item->{name},
                $item->{status},
                $instance, 
                $item->{temperature}
            )
        );

        $exit = $self->get_severity(label => 'default', section => 'temperature', instance => $instance, value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' status is %s", $item->{name}, $item->{status}
                )
            );
        }

        next if (!defined($item->{temperature}) || $item->{temperature} !~ /[0-9]/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $item->{temperature});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Temperature '%s' is %s degree centigrade", $item->{name}, $item->{temperature})
            );
        }
        
        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.temperature.celsius',
            unit => 'C',
            instances => $item->{name},
            value => $item->{temperature},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
