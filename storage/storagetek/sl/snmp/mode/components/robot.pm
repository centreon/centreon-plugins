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

package storage::storagetek::sl::snmp::mode::components::robot;

use strict;
use warnings;
use storage::storagetek::sl::snmp::mode::components::resources qw($map_status);

my $mapping = {
    slRobotSerialNum    => { oid => '.1.3.6.1.4.1.1211.1.15.4.10.1.5' },
    slRobotStatusEnum   => { oid => '.1.3.6.1.4.1.1211.1.15.4.10.1.8', map => $map_status },
};
my $oid_slRobotEntry = '.1.3.6.1.4.1.1211.1.15.4.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_slRobotEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking robots");
    $self->{components}->{robot} = {name => 'robots', total => 0, skip => 0};
    return if ($self->check_filter(section => 'robot'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_slRobotEntry}})) {
        next if ($oid !~ /^$mapping->{slRobotStatusEnum}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_slRobotEntry}, instance => $instance);

        next if ($self->check_filter(section => 'robot', instance => $instance));
        $self->{components}->{robot}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("robot '%s' status is '%s' [instance: %s].",
                                    $result->{slRobotSerialNum}, $result->{slRobotStatusEnum},
                                    $instance
                                    ));
        my $exit = $self->get_severity(label => 'status', section => 'robot', value => $result->{slRobotStatusEnum});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Robot '%s' status is '%s'",
                                                             $result->{slRobotSerialNum}, $result->{slRobotStatusEnum}));
        }
    }
}

1;