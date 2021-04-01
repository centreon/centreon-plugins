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

package hardware::server::hp::proliant::snmp::mode::components::lnic;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_lnic_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_lnic_status = (
    1 => "unknown",
    2 => "ok",
    3 => "primaryFailed",
    4 => "standbyFailed",
    5 => "groupFailed",
    6 => "redundancyReduced",
    7 => "redundancyLost",
);

# In MIB 'CPQNIC-MIB.mib'
my $mapping = {
    cpqNicIfLogMapDescription => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.3' },
};
my $mapping2 = {
    cpqNicIfLogMapAdapterCount => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.5' },
};
my $mapping3 = {
    cpqNicIfLogMapCondition  => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.10', map => \%map_lnic_condition },
    cpqNicIfLogMapStatus => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.11', map => \%map_lnic_status },
};
my $oid_cpqNicIfLogMapEntry = '.1.3.6.1.4.1.232.18.2.2.1.1';
my $oid_cpqNicIfLogMapDescription = '.1.3.6.1.4.1.232.18.2.2.1.1.3';
my $oid_cpqNicIfLogMapAdapterCount = '.1.3.6.1.4.1.232.18.2.2.1.1.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqNicIfLogMapEntry, start => $mapping3->{cpqNicIfLogMapCondition}->{oid}, end => $mapping3->{cpqNicIfLogMapStatus}->{oid} },
        { oid => $oid_cpqNicIfLogMapDescription }, { oid => $oid_cpqNicIfLogMapAdapterCount };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking logical nics");
    $self->{components}->{lnic} = {name => 'logical nics', total => 0, skip => 0};
    return if ($self->check_filter(section => 'lnic'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqNicIfLogMapEntry}})) {
        next if ($oid !~ /^$mapping3->{cpqNicIfLogMapCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqNicIfLogMapDescription}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqNicIfLogMapAdapterCount}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$oid_cpqNicIfLogMapEntry}, instance => $instance);

        next if ($self->check_filter(section => 'lnic', instance => $instance));
        $self->{components}->{lnic}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("logical nic '%s' [adapter count: %s, description: %s, status: %s] condition is %s.", 
                                    $instance, $result2->{cpqNicIfLogMapAdapterCount}, centreon::plugins::misc::trim($result->{cpqNicIfLogMapDescription}),
                                    $result3->{cpqNicIfLogMapStatus},
                                    $result3->{cpqNicIfLogMapCondition}));
        my $exit = $self->get_severity(section => 'lnic', value => $result3->{cpqNicIfLogMapCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("logical nic '%s' is %s", 
                                            $instance, $result3->{cpqNicIfLogMapCondition}));
        }
    }
}

1;
