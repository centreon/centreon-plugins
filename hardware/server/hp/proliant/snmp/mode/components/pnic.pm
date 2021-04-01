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

package hardware::server::hp::proliant::snmp::mode::components::pnic;

use strict;
use warnings;

my %map_pnic_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_pnic_role = (
    1 => "unknown",
    2 => "primary",
    3 => "secondary",
    4 => "member",
    5 => "txRx",
    6 => "tx",
    7 => "standby",
    8 => "none",
    255 => "notApplicable",
);
my %map_nic_state = (
    1 => "unknown",
    2 => "ok",
    3 => "standby",
    4 => "failed",
);
my %map_pnic_status = (
    1 => "unknown",
    2 => "ok",
    3 => "generalFailure",
    4 => "linkFailure",
);
my %map_nic_duplex = (
    1 => "unknown",
    2 => "half",
    3 => "full",
);
# In MIB 'CPQNIC-MIB.mib'
my $mapping = {
    cpqNicIfPhysAdapterRole => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.3', map => \%map_pnic_role },
};
my $mapping2 = {
    cpqNicIfPhysAdapterDuplexState  => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.11', map => \%map_nic_duplex },
    cpqNicIfPhysAdapterCondition => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.12', map => \%map_pnic_condition },
    cpqNicIfPhysAdapterState => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.13', map => \%map_nic_state },
    cpqNicIfPhysAdapterStatus => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.14', map => \%map_pnic_status },
};
my $oid_cpqNicIfPhysAdapterEntry = '.1.3.6.1.4.1.232.18.2.3.1.1';
my $oid_cpqNicIfPhysAdapterRole = '.1.3.6.1.4.1.232.18.2.3.1.1.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqNicIfPhysAdapterEntry, start => $mapping2->{cpqNicIfPhysAdapterDuplexState}->{oid}, end => $mapping2->{cpqNicIfPhysAdapterStatus}->{oid} },
        { oid => $oid_cpqNicIfPhysAdapterRole };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking physical nics");
    $self->{components}->{pnic} = {name => 'physical nics', total => 0, skip => 0};
    return if ($self->check_filter(section => 'pnic'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqNicIfPhysAdapterEntry}})) {
        next if ($oid !~ /^$mapping2->{cpqNicIfPhysAdapterCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqNicIfPhysAdapterRole}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqNicIfPhysAdapterEntry}, instance => $instance);

        next if ($self->check_filter(section => 'pnic', instance => $instance));
        $self->{components}->{pnic}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("physical nic '%s' [duplex: %s, role: %s, state: %s, status: %s] condition is %s.", 
                                    $instance, $result2->{cpqNicIfPhysAdapterDuplexState}, $result->{cpqNicIfPhysAdapterRole},
                                    $result2->{cpqNicIfPhysAdapterState}, $result2->{cpqNicIfPhysAdapterStatus},
                                    $result2->{cpqNicIfPhysAdapterCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'pnic', value => $result2->{cpqNicIfPhysAdapterCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("physical nic '%s' is %s", 
                                            $instance, $result2->{cpqNicIfPhysAdapterCondition}));
        }
    }
}

1;