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

package network::juniper::common::junos::netconf::mode::components::pic;

use strict;
use warnings;

sub load {}

sub disco_show {
    my ($self) = @_;

    foreach my $item (sort { $a->{instance} cmp $b->{instance} } values %{$self->{results}->{pic}}) {
        my %attrs = (fpc_slot => $item->{fpc_slot}, pic_slot => $item->{pic_slot});
        $attrs{mic_slot} = $item->{mic_slot} if (defined($item->{mic_slot}));

        $self->{output}->add_disco_entry(
            component   => 'pic',
            instance    => $item->{instance},
            description => $item->{description},
            %attrs
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking pic");
    $self->{components}->{pic} = { name => 'pic', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'pic'));

    foreach my $item (sort { $a->{instance} cmp $b->{instance} } values %{$self->{results}->{pic}}) {
        next if ($self->check_filter(section => 'pic', instance => $item->{instance}));
        $self->{components}->{pic}->{total}++;

        my @attrs = ('fpc slot: ' . $item->{fpc_slot});
        push @attrs, 'mic slot: ' . $item->{mic_slot} if (defined($item->{mic_slot}));
        push @attrs, 'pic slot: ' . $item->{pic_slot};
        $self->{output}->output_add(
            long_msg => sprintf(
                "pic '%s @ %s' status is %s [%s]%s.",
                $item->{description},
                $item->{instance},
                $item->{status},
                join(', ', @attrs),
                defined($self->{option_results}->{display_instances}) ? ' [instance: ' . $item->{instance} . ']' : ''
            )
        );

        my $exit = $self->get_severity(section => 'pic', value => $item->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "pic '%s @ %s' status is %s [%s]",
                    $item->{description},
                    $item->{instance},
                    $item->{status},
                    join(', ', @attrs)
                )
            );
        }
    }
}

1;
