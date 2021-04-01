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

package network::fiberstore::snmp::mode::components::slot;

use strict;
use warnings;

my $oid_lswSlotStatus = '.37.1.5.1.5'; # lswSlotStatus

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $self->{branch} . $oid_lswSlotStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking slots');
    $self->{components}->{slot} = {name => 'slots', total => 0, skip => 0};
    return if ($self->check_filter(section => 'slot'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{branch} . $oid_lswSlotStatus }})) {
        $oid =~ /\.(\d+\.\d+)$/;
        my $instance = $1;

        next if ($self->check_filter(section => 'slot', instance => $instance));
        
        my $status = $self->{results}->{ $self->{branch} . $oid_lswSlotStatus }->{$oid};
        $self->{components}->{slot}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "slot '%s' status is %s [instance: %s]",
                $instance, $status, $instance
            )
        );

        my $exit = $self->get_severity(section => 'slot', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Slot '%s' status is %s", $instance, $status
                )
            );
        }
    }
}

1;
