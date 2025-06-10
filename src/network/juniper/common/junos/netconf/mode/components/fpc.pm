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

package network::juniper::common::junos::netconf::mode::components::fpc;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (@{$self->{results}->{fpc}}) {
        $self->{output}->add_disco_entry(
            component => 'fpc',
            instance  => $item->{name}
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fpc");
    $self->{components}->{fpc} = { name => 'fpc', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fpc'));

    foreach my $item (@{$self->{results}->{fpc}}) {
        next if ($self->check_filter(section => 'fpc', instance => $item->{name}));
        $self->{components}->{fpc}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "%s status is %s%s.",
                $item->{name},
                $item->{status},
                defined($self->{option_results}->{display_instances}) ? ' [instance: ' . $item->{name} . ']' : ''
            )
        );

        my $exit = $self->get_severity(section => 'fpc', value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "%s status is %s",
                    $item->{name}, $item->{status}
                )
            );
        }
    }
}

1;
