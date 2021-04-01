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

package hardware::server::hp::proliant::snmp::mode::components::dactl;

use strict;
use warnings;

my %map_controller_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %model_map = (
    1 => 'other',
    2 => 'ida',
    3 => 'idaExpansion',
    4 => 'ida-2',
    5 => 'smart',
    6 => 'smart-2e',
    7 => 'smart-2p',
    8 => 'smart-2sl',
    9 => 'smart-3100es',
    10 => 'smart-3200',
    11 => 'smart-2dh',
    12 => 'smart-221',
    13 => 'sa-4250es',
    14 => 'sa-4200',
    15 => 'sa-integrated',
    16 => 'sa-431',
    17 => 'sa-5300',
    18 => 'raidLc2',
    19 => 'sa-5i',
    20 => 'sa-532',
    21 => 'sa-5312',
    22 => 'sa-641',
    23 => 'sa-642',
    24 => 'sa-6400',
    25 => 'sa-6400em',
    26 => 'sa-6i',
    27 => 'sa-generic',
    29 => 'sa-p600',
    30 => 'sa-p400',
    31 => 'sa-e200',
    32 => 'sa-e200i',
    33 => 'sa-p400i',
    34 => 'sa-p800',
    35 => 'sa-e500',
    36 => 'sa-p700m',
    37 => 'sa-p212',
    38 => 'sa-p410(38)',
    39 => 'sa-p410i',
    40 => 'sa-p411',
    41 => 'sa-b110i',
    42 => 'sa-p712m',
    43 => 'sa-p711m',
    44 => 'sa-p812'
);
# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaCntlrModel => { oid => '.1.3.6.1.4.1.232.3.2.2.1.1.2', map => \%model_map },
};
my $mapping2 = {
    cpqDaCntlrSlot => { oid => '.1.3.6.1.4.1.232.3.2.2.1.1.5' },
    cpqDaCntlrCondition => { oid => '.1.3.6.1.4.1.232.3.2.2.1.1.6', map => \%map_controller_condition },
};
my $oid_cpqDaCntlrEntry = '.1.3.6.1.4.1.232.3.2.2.1.1';
my $oid_cpqDaCntlrModel = '.1.3.6.1.4.1.232.3.2.2.1.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqDaCntlrEntry, start => $mapping2->{cpqDaCntlrSlot}->{oid}, end => $mapping2->{cpqDaCntlrCondition}->{oid} },
        { oid => $oid_cpqDaCntlrModel };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da controller");
    $self->{components}->{dactl} = {name => 'da controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'dactl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaCntlrEntry}})) {
        next if ($oid !~ /^$mapping2->{cpqDaCntlrCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaCntlrModel}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaCntlrEntry}, instance => $instance);

        next if ($self->check_filter(section => 'dactl', instance => $instance));
        $self->{components}->{dactl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da controller '%s' [slot: %s, model: %s] status is %s.", 
                                    $instance, $result2->{cpqDaCntlrSlot}, $result->{cpqDaCntlrModel},
                                    $result2->{cpqDaCntlrCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'dactl', value => $result2->{cpqDaCntlrCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da controller '%s' is %s", 
                                            $instance, $result2->{cpqDaCntlrCondition}));
        }
    }
}

1;