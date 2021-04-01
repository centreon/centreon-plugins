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

package network::dell::os10::snmp::mode::components::card;

use strict;
use warnings;

my $map_card_status = {
    1 => 'ready', 2 => 'cardMisMatch', 3 => 'cardProblem',
    4 => 'diagMode', 5 => 'cardAbsent', 6 => 'offline'
};

my $mapping = {
    os10CardDescription => { oid => '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.4.1.3' },
    os10CardStatus      => { oid => '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.4.1.4', map => $map_card_status },
};
my $oid_os10CardEntry = '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.4.1';
my $oid_os10ChassisPPID = '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.3.1.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_os10CardEntry,
        start => $mapping->{os10CardDescription}->{oid},
        end => $mapping->{os10CardStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking cards');
    $self->{components}->{card} = { name => 'cards', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'card'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_os10CardEntry}})) {
        next if ($oid !~ /^$mapping->{os10CardStatus}->{oid}\.(.*?)\.(.*)$/);
        my ($chassis_index, $card_index, $instance) = ($1, $2, $1 . '.' . $2);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_os10CardEntry}, instance => $instance);
        my $name = $self->{results}->{$oid_os10ChassisPPID}->{$oid_os10ChassisPPID . '.' . $chassis_index} . ':' . $result->{os10CardDescription};

        next if ($self->check_filter(section => 'card', instance => $instance));
        $self->{components}->{card}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "card '%s' status is '%s' [instance: %s].",
                $name,
                $result->{os10CardStatus},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'card', value => $result->{os10CardStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "card '%s' status is '%s'",
                    $name,
                    $result->{os10CardStatus}
                )
            );
        }
    }
}

1;
