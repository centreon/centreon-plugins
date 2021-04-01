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

package centreon::common::airespace::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    0 => 'not operational', 
    1 => 'operational', 
);

# In MIB 'AIRESPACE-SWITCHING-MIB'
my $oid_agentSwitchInfoGroup = '.1.3.6.1.4.1.14179.1.1.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_agentSwitchInfoGroup };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
 
    foreach my $instances ([1, 3], [2, 5]) {
        next if (!defined($self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . $$instances[1] . '.0' }));
        my $present = $self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . ($$instances[1] - 1) . '.0' };
        my $operational = $map_psu_status{ $self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . $$instances[1] . '.0' } };

        next if ($self->check_filter(section => 'psu', instance => $$instances[0]));
        next if ($present =~ /0/i && 
                 $self->absent_problem(section => 'psu', instance => $$instances[0]));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s.",
                                                        $$instances[0], $operational));
        my $exit = $self->get_severity(section => 'psu', value => $operational);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s.",
                                                             $$instances[0], $operational));
        }
    }
}

1;