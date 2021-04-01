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

package centreon::common::foundry::snmp::mode::components::board;

use strict;
use warnings;

my $mapping_board_status = {
    0 => 'moduleEmpty', 2 => 'moduleGoingDown', 3 => 'moduleRejected',
    4 => 'moduleBad', 8 => 'moduleConfigured', 9 => 'moduleComingUp',
    10 => 'moduleRunning'
};

my $mapping = {
    snAgentBrdMainBrdDescription => { oid => '.1.3.6.1.4.1.1991.1.1.2.2.1.1.2' },
    snAgentBrdModuleStatus       => { oid => '.1.3.6.1.4.1.1991.1.1.2.2.1.1.12', map => $mapping_board_status }
};
sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $mapping->{snAgentBrdMainBrdDescription}->{oid} },
        { oid => $mapping->{snAgentBrdModuleStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking boards');
    $self->{components}->{board} = { name => 'boards', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'board'));

    my $result = {
        %{$self->{results}->{ $mapping->{snAgentBrdMainBrdDescription}->{oid} }},
        %{$self->{results}->{ $mapping->{snAgentBrdModuleStatus}->{oid} }}
    };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($oid !~ /^$mapping->{snAgentBrdModuleStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $result, instance => $instance);

        next if ($self->check_filter(section => 'board', instance => $instance));
        $self->{components}->{board}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "board '%s' status is '%s' [instance: %s].",
                $result->{snAgentBrdMainBrdDescription},
                $result->{snAgentBrdModuleStatus},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'board', value => $result->{snAgentBrdModuleStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "board '%s' status is '%s'",
                    $result->{snAgentBrdMainBrdDescription},
                    $result->{snAgentBrdModuleStatus}
                )
            );
        }
    }
}

1;
