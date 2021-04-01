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

package hardware::server::hp::proliant::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_cpu_status = (
    1 => 'unknown',
    2 => 'ok',
    3 => 'degraded',
    4 => 'failed',
    5 => 'disabled',
);

# In MIB 'CPQSTDEQ-MIB.mib'
my $mapping = {
    cpqSeCpuSlot => { oid => '.1.3.6.1.4.1.232.1.2.2.1.1.2' },
    cpqSeCpuName => { oid => '.1.3.6.1.4.1.232.1.2.2.1.1.3' },
    cpqSeCpuStatus => { oid => '.1.3.6.1.4.1.232.1.2.2.1.1.6', map => \%map_cpu_status },
    cpqSeCpuSocketNumber => { oid => '.1.3.6.1.4.1.232.1.2.2.1.1.9' },
};
my $oid_cpqSeCpuEntry = '.1.3.6.1.4.1.232.1.2.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqSeCpuEntry, start => $mapping->{cpqSeCpuSlot}->{oid}, end => $mapping->{cpqSeCpuSocketNumber}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqSeCpuEntry}})) {
        next if ($oid !~ /^$mapping->{cpqSeCpuStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqSeCpuEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'cpu', instance => $instance));
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("cpu '%s' [slot: %s, unit: %s, name: %s, socket: %s] status is %s.", 
                                    $instance, $result->{cpqSeCpuSlot}, $result->{cpqSeCpuSlot}, $result->{cpqSeCpuName}, $result->{cpqSeCpuSocketNumber},
                                    $result->{cpqSeCpuStatus}));
        my $exit = $self->get_severity(section => 'cpu', value => $result->{cpqSeCpuStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("cpu '%s' is %s", 
                                            $instance, $result->{cpqSeCpuStatus}));
        }
    }
}

1;