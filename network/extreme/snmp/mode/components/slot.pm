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

package network::extreme::snmp::mode::components::slot;

use strict;
use warnings;

my %map_slot_status = (
    1 => 'notPresent',
    2 => 'testing',
    3 => 'mismatch',
    4 => 'failed',
    5 => 'operational',
    6 => 'powerdown',
    7 => 'unknown',
    8 => 'present',
    9 => 'poweron',
    10 => 'post',
    11 => 'downloading',
    12 => 'booting',
    13 => 'offline',
    14 => 'initializing',
    100 => 'invalid',
);

my $mapping = {
    extremeSlotName => { oid => '.1.3.6.1.4.1.1916.1.1.2.2.1.2' },
    extremeSlotModuleState => { oid => '.1.3.6.1.4.1.1916.1.1.2.2.1.5', map => \%map_slot_status  },
};
my $oid_extremeSlotEntry = '.1.3.6.1.4.1.1916.1.1.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_extremeSlotEntry, start => $mapping->{extremeSlotName}->{oid}, end => $mapping->{extremeSlotModuleState}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking slots");
    $self->{components}->{slot} = { name => 'slots', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'slot'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_extremeSlotEntry}})) {
        next if ($oid !~ /^$mapping->{extremeSlotModuleState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_extremeSlotEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'slot', instance => $instance));
        if ($result->{extremeSlotModuleState} =~ /notPresent/i) {
            $self->absent_problem(section => 'slot', instance => $instance);
            next;
        }

        $self->{components}->{slot}->{total}++;
        $self->{output}->output_add(long_msg =>
            sprintf(
                "Slot '%s' status is '%s' [instance = %s]",
                $result->{extremeSlotName},
                $result->{extremeSlotModuleState},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'slot', value => $result->{extremeSlotModuleState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Slot '%s' status is '%s'",
                    $result->{extremeSlotName},
                    $result->{extremeSlotModuleState}
                )
            );
        }
    }
}

1;
