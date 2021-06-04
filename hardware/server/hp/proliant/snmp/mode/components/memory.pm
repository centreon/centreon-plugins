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

package hardware::server::hp::proliant::snmp::mode::components::memory;

use strict;
use warnings;

my %map_memory_status = (
    1 => 'other',
    2 => 'notPresent',
    3 => 'present',
    4 => 'good',
    5 => 'add',
    6 => 'upgrade',
    7 => 'missing',
    8 => 'doesNotMatch',
    9 => 'notSupported',
    10 => 'badConfig',
    11 => 'degraded',
    12 => 'spare',
    13 => 'partial',
    14 => 'configError',
    15 => 'trainingFailure'
);

# In MIB 'CPQHLTH-MIB.mib'
my $mapping = {
    cpqHeResMem2Module => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.1' },
    cpqHeResMem2ModuleSize => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.6' },
    cpqHeResMem2ModuleHwLocation => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.13' },
    cpqHeResMem2ModuleStatus => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.19', map => \%map_memory_status }
};
my $oid_cpqHeResMem2ModuleEntry = '.1.3.6.1.4.1.232.6.2.14.13.1';

sub load {
    my ($self) = @_;
    push @{$self->{request}}, { oid => $oid_cpqHeResMem2ModuleEntry, start => $mapping->{cpqHeResMem2Module}->{oid}, end => $mapping->{cpqHeResMem2ModuleStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking memory");
    $self->{components}->{memory} = {name => 'mems', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHeResMem2ModuleEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHeResMem2ModuleStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHeResMem2ModuleEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'memory', instance => $instance));
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("memory '%s' [slot: %s, location: %s, size: %skB] status is %s.", 
                                    $instance, $result->{cpqHeResMem2Module}, $result->{cpqHeResMem2ModuleHwLocation},
                                    $result->{cpqHeResMem2ModuleSize}, $result->{cpqHeResMem2ModuleStatus}));
        my $exit = $self->get_severity(section => 'memory', value => $result->{cpqHeResMem2ModuleStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("memory '%s' is %s", 
                                            $instance, $result->{cpqHeResMem2ModuleStatus}));
        }
    }
}

1;
