#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (@{$self->{results}->{env}}) {
        next if ($item->{class} ne 'Temp');
        $self->{output}->add_disco_entry(
            component => 'temperature',
            instance  => $item->{name}
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $item (@{$self->{results}->{env}}) {
        next if ($item->{class} ne 'Temp');
        next if ($self->check_filter(section => 'temperature', instance => $item->{name}));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is %s [current: %s%s].",
                $item->{name},
                $item->{status},
                $item->{temperature} ne '' ? $item->{temperature} : '-',
                defined($self->{option_results}->{display_instances}) ? ', instance: ' . $item->{name} : ''
            )
        );

        my $exit = $self->get_severity(section => 'temperature', value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Temperature '%s' status is %s",
                    $item->{name}, $item->{status}
                )
            );
        }

        next if ($item->{temperature} eq '');

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $item->{name}, value => $item->{temperature});

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit2,
                short_msg => sprintf("Temperature '%s' is %s degree centigrade", $item->{name}, $item->{temperature})
            );
        }

        $self->{output}->perfdata_add(
            nlabel    => 'hardware.temperature.celsius',
            unit      => 'C',
            instances => $item->{name},
            value     => $item->{temperature},
            warning   => $warn,
            critical  => $crit
        );
    }
}

1;
