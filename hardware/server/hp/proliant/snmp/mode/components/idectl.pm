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

package hardware::server::hp::proliant::snmp::mode::components::idectl;

use strict;
use warnings;
use centreon::plugins::misc;

# In 'CPQIDE-MIB.mib'
my %map_controller_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
);

my %map_controller_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my $mapping = {
    cpqIdeControllerModel => { oid => '.1.3.6.1.4.1.232.14.2.3.1.1.3' },
    cpqIdeControllerSlot => { oid => '.1.3.6.1.4.1.232.14.2.3.1.1.5' },
    cpqIdeControllerStatus => { oid => '.1.3.6.1.4.1.232.14.2.3.1.1.6', map => \%map_controller_status },
    cpqIdeControllerCondition => { oid => '.1.3.6.1.4.1.232.14.2.3.1.1.7', map => \%map_controller_condition },
};
my $oid_cpqIdeControllerEntry = '.1.3.6.1.4.1.232.14.2.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqIdeControllerEntry, start => $mapping->{cpqIdeControllerModel}->{oid}, end => $mapping->{cpqIdeControllerCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ide controllers");
    $self->{components}->{idectl} = {name => 'ide controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'idectl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqIdeControllerEntry}})) {
        next if ($oid !~ /^$mapping->{cpqIdeControllerCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqIdeControllerEntry}, instance => $instance);
        $result->{cpqIdeControllerModel} = centreon::plugins::misc::trim($result->{cpqIdeControllerModel});

        next if ($self->check_filter(section => 'idectl', instance => $instance));
        $self->{components}->{idectl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ide controller '%s' [slot: %s, model: %s, status: %s] condition is %s.", 
                                    $instance, $result->{cpqIdeControllerSlot}, $result->{cpqIdeControllerModel}, $result->{cpqIdeControllerStatus},
                                    $result->{cpqIdeControllerCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'idectl', value => $result->{cpqIdeControllerCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("ide controller '%s' is %s", 
                                            $instance, $result->{cpqIdeControllerCondition}));
        }
    }
}

1;