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

package network::juniper::common::junos::netconf::mode::components::fan;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (@{$self->{results}->{fan}}) {
        $self->{output}->add_disco_entry(
            component => 'fan',
            instance  => $item->{name}
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $item (@{$self->{results}->{fan}}) {
        next if ($self->check_filter(section => 'fan', instance => $item->{name}));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [rpm: %s%s].",
                $item->{name},
                $item->{status},
                defined($item->{rpm}) ? $item->{rpm} : '-',
                defined($self->{option_results}->{display_instances}) ? ', instance: ' . $item->{name} : ''
            )
        );

        my $exit = $self->get_severity(section => 'fan', value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is %s",
                    $item->{name}, $item->{status}
                )
            );
        }

        if (defined($item->{rpm})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $item->{name}, value => $item->{rpm});

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit2,
                    short_msg => sprintf("Fan '%s' speed is %s rpm", $item->{name}, $item->{rpm})
                );
            }

            $self->{output}->perfdata_add(
                nlabel    => 'hardware.fan.speed.rpm',
                unit      => 'rpm',
                instances => $item->{name},
                value     => $item->{rpm},
                warning   => $warn,
                critical  => $crit,
                min       => 0
            );
        }
    }
}

1;
