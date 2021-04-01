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

package hardware::server::hp::proliant::snmp::mode::components::daldrive;

use strict;
use warnings;

my %map_daldrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_ldrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'unconfigured',
    5 => 'recovering',
    6 => 'readyForRebuild',
    7 => 'rebuilding',
    8 => 'wrongDrive',
    9 => 'badConnect',
    10 => 'overheating',
    11 => 'shutdown',
    12 => 'expanding',
    13 => 'notAvailable',
    14 => 'queuedForExpansion',
    15 => 'multipathAccessDegraded',
    16 => 'erasing',
);
my %map_faulttol = (
    1 => 'other',
    2 => 'none',
    3 => 'mirroring',
    4 => 'dataGuard',
    5 => 'distribDataGuard',
    7 => 'advancedDataGuard',
    8 => 'raid50',
    9 => 'raid60',
);
# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaLogDrvFaultTol => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.3', map => \%map_faulttol },
    cpqDaLogDrvStatus => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.4', map => \%map_ldrive_status },
};
my $mapping2 = {
    cpqDaLogDrvCondition => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.11', map => \%map_daldrive_condition },
};
my $oid_cpqDaLogDrvEntry = '.1.3.6.1.4.1.232.3.2.3.1.1';
my $oid_cpqDaLogDrvCondition = '.1.3.6.1.4.1.232.3.2.3.1.1.11';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqDaLogDrvEntry, start => $mapping->{cpqDaLogDrvFaultTol}->{oid}, end => $mapping->{cpqDaLogDrvStatus}->{oid} },
        { oid => $oid_cpqDaLogDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da logical drives");
    $self->{components}->{daldrive} = {name => 'da logical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'daldrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaLogDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqDaLogDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaLogDrvEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaLogDrvCondition}, instance => $instance);

        next if ($self->check_filter(section => 'daldrive', instance => $instance));
        $self->{components}->{daldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da logical drive '%s' [fault tolerance: %s, condition: %s] status is %s.", 
                                    $instance,
                                    $result->{cpqDaLogDrvFaultTol}, 
                                    $result2->{cpqDaLogDrvCondition},
                                    $result->{cpqDaLogDrvStatus}));
        my $exit = $self->get_severity(section => 'daldrive', value => $result->{cpqDaLogDrvStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da logical drive '%s' is %s", 
                                                $instance, $result->{cpqDaLogDrvStatus}));
        }
    }
}

1;