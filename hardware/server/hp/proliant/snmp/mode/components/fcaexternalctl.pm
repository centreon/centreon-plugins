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

package hardware::server::hp::proliant::snmp::mode::components::fcaexternalctl;

use strict;
use warnings;

my %map_fcaexternalctl_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'offline',
    5 => 'redundantPathOffline',
    6 => 'notConnected',
);

my %map_fcaexternalctl_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %model_map = (
    1 => 'other',
    2 => 'fibreArray',
    3 => 'msa1000',
    4 => 'smartArrayClusterStorage',
    5 => 'hsg80',
    6 => 'hsv110',
    7 => 'msa500G2',
    8 => 'msa20',
    9 => 'msa1510i',
);

my %map_role = (
    1 => 'other',
    2 => 'notDuplexed',
    3 => 'active',
    4 => 'backup',
);

# In 'CPQFCA-MIB.mib'    
my $mapping = {
    cpqFcaCntlrModel => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.3', map => \%model_map },
    cpqFcaCntlrStatus => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.5', map => \%map_fcaexternalctl_status },
    cpqFcaCntlrCondition => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.6', map => \%map_fcaexternalctl_condition },
};
my $mapping2 = {
    cpqFcaCntlrCurrentRole => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.10', map => \%map_role },
};
my $oid_cpqFcaCntlrEntry = '.1.3.6.1.4.1.232.16.2.2.1.1';
my $oid_cpqFcaCntlrCurrentRole = '.1.3.6.1.4.1.232.16.2.2.1.1.10';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqFcaCntlrEntry, start => $mapping->{cpqFcaCntlrModel}->{oid}, end => $mapping->{cpqFcaCntlrCondition}->{oid} },
        { oid => $oid_cpqFcaCntlrCurrentRole };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca external controller");
    $self->{components}->{fcaexternalctl} = {name => 'fca external controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fcaexternalctl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqFcaCntlrEntry}})) {
        next if ($oid !~ /^$mapping->{cpqFcaCntlrCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqFcaCntlrEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqFcaCntlrCurrentRole}, instance => $instance);

        next if ($self->check_filter(section => 'fcaexternalctl', instance => $instance));
        $self->{components}->{fcaexternalctl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca external controller '%s' [model: %s, status: %s, role: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqFcaCntlrModel}, $result->{cpqFcaCntlrStatus}, $result2->{cpqFcaCntlrCurrentRole},
                                    $result->{cpqFcaCntlrCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'fcaexternalctl', value => $result->{cpqFcaCntlrCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fca external controller '%s' is %s", 
                                            $instance, $result->{cpqFcaCntlrCondition}));
        }
    }
}

1;