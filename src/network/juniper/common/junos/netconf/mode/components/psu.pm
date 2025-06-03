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

package network::juniper::common::junos::netconf::mode::components::psu;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (@{$self->{results}->{psu}}) {
        $self->{output}->add_disco_entry(
            component => 'psu',
            instance  => $item->{name}
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking power supplies");
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $item (@{$self->{results}->{psu}}) {
        next if ($self->check_filter(section => 'psu', instance => $item->{name}));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [dc output load: %s%s].",
                $item->{name},
                $item->{status},
                defined($item->{dc_output_load}) ? $item->{dc_output_load} . '%' : '-',
                defined($self->{option_results}->{display_instances}) ? ', instance: ' . $item->{name} : ''
            )
        );

        my $exit = $self->get_severity(section => 'psu', value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is %s",
                    $item->{name}, $item->{status}
                )
            );
        }

        if (defined($item->{dc_output_load})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => $item->{name}, value => $item->{dc_output_load});

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit2,
                    short_msg => sprintf("Power supply '%s' DC output load is %s%%", $item->{name}, $item->{dc_output_load})
                );
            }

            $self->{output}->perfdata_add(
                nlabel    => 'hardware.psu.dc.output.load.percentage',
                unit      => '%',
                instances => $item->{name},
                value     => $item->{dc_output_load},
                warning   => $warn,
                critical  => $crit,
                min       => 0,
                max       => 100
            );
        }
    }
}

1;
