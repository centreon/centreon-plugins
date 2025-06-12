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

package network::juniper::common::junos::netconf::mode::components::mic;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (sort { $a->{instance} cmp $b->{instance} } values %{$self->{results}->{mic}}) {
        next if (scalar(@{$item->{pics}}) <= 0);

        $self->{output}->add_disco_entry(
            component   => 'mic',
            instance    => $item->{instance},
            description => $item->{description},
            fpc_slot    => $item->{fpc_slot},
            mic_slot    => $item->{mic_slot}
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking mic");
    $self->{components}->{mic} = { name => 'mic', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'mic'));

    foreach my $item (sort { $a->{instance} cmp $b->{instance} } values %{$self->{results}->{mic}}) {
        next if (scalar(@{$item->{pics}}) <= 0);
        next if ($self->check_filter(section => 'mic', instance => $item->{instance}));
        $self->{components}->{mic}->{total}++;

        my @attrs = ('fpc slot: ' . $item->{fpc_slot});
        push @attrs, 'mic slot: ' . $item->{mic_slot};

        my $status = 'Online';
        foreach my $pic_instance (@{$item->{pics}}) {
            my $exit = $self->get_severity(section => 'pic', value => $self->{results}->{pic}->{$pic_instance}->{status});
            $status = 'Error' if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1));
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "mic '%s @ %s' status is %s [%s]%s.",
                $item->{description},
                $item->{instance},
                $status,
                join(', ', @attrs),
                defined($self->{option_results}->{display_instances}) ? ' [instance: ' . $item->{instance} . ']' : ''
            )
        );

        my $exit = $self->get_severity(section => 'mic', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "mic '%s @ %s' status is %s [%s]",
                    $item->{description},
                    $item->{instance},
                    $status,
                    join(', ', @attrs)
                )
            );
        }
    }
}

1;
