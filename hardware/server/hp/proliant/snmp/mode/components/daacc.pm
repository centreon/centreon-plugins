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

package hardware::server::hp::proliant::snmp::mode::components::daacc;

use strict;
use warnings;

my %map_daacc_status = (
    1 => 'other',
    2 => 'invalid',
    3 => 'enabled',
    4 => 'tmpDisabled',
    5 => 'permDisabled',
);
my %map_daacc_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_daaccbattery_condition = (
    1 => 'other', 
    2 => 'ok',
    3 => 'recharging', 
    4 => 'failed',
    5 => 'degraded',
    6 => 'not present',
);

# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaAccelStatus => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.2', map => \%map_daacc_status },
};
my $mapping2 = {
    cpqDaAccelBattery => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.6', map => \%map_daaccbattery_condition },
};
my $mapping3 = {
    cpqDaAccelCondition => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.9', map => \%map_daacc_condition },
};
my $oid_cpqDaAccelStatus = '.1.3.6.1.4.1.232.3.2.2.2.1.2';
my $oid_cpqDaAccelBattery = '.1.3.6.1.4.1.232.3.2.2.2.1.6';
my $oid_cpqDaAccelCondition = '.1.3.6.1.4.1.232.3.2.2.2.1.9';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqDaAccelStatus }, { oid => $oid_cpqDaAccelBattery }, { oid => $oid_cpqDaAccelCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da accelerator boards");
    $self->{components}->{daacc} = {name => 'da accelerator boards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'daacc'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaAccelCondition}})) {
        next if ($oid !~ /^$mapping3->{cpqDaAccelCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaAccelStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaAccelBattery}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$oid_cpqDaAccelCondition}, instance => $instance);

        next if ($self->check_filter(section => 'daacc', instance => $instance));
        $self->{components}->{daacc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da controller accelerator '%s' [status: %s, battery status: %s] condition is %s.", 
                                    $instance, $result->{cpqDaAccelStatus}, $result2->{cpqDaAccelBattery},
                                    $result3->{cpqDaAccelCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'daacc', value => $result3->{cpqDaAccelCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da controller accelerator '%s' is %s", 
                                            $instance, $result3->{cpqDaAccelCondition}));
        }
        $exit = $self->get_severity(section => 'daaccbattery', value => $result2->{cpqDaAccelBattery});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da controller accelerator '%s' battery is %s", 
                                            $instance, $result2->{cpqDaAccelBattery}));
        }
    }
}

1;