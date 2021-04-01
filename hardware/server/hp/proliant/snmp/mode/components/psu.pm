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

package hardware::server::hp::proliant::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %map_present = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);

my %map_redundant = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);

my %map_psu_status = (
    1  => 'noError',
    2  => 'generalFailure',
    3  => 'bistFailure',
    4  => 'fanFailure',
    5  => 'tempFailure',
    6  => 'interlockOpen',
    7  => 'epromFailed',
    8  => 'vrefFailed',
    9  => 'dacFailed',
    10 => 'ramTestFailed',
    11 => 'voltageChannelFailed',
    12 => 'orringdiodeFailed',
    13 => 'brownOut',
    14 => 'giveupOnStartup',
    15 => 'nvramInvalid',
    16 => 'calibrationTableInvalid',
);

# In MIB 'CPQHLTH-MIB.mib'
my $mapping = {
    cpqHeFltTolPowerSupplyPresent => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.3', map => \%map_present },
    cpqHeFltTolPowerSupplyCondition => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.4', map => \%map_psu_condition },
    cpqHeFltTolPowerSupplyStatus => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.5', map => \%map_psu_status },
    cpqHeFltTolPowerSupplyMainVoltage => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.6' },
    cpqHeFltTolPowerSupplyCapacityUsed => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.7' },
    cpqHeFltTolPowerSupplyCapacityMaximum => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.8' },
    cpqHeFltTolPowerSupplyRedundant => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.9' },
};
my $mapping2 = {
    cpqHeFltTolPowerSupplyRedundantPartner => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.17' },
};
my $oid_cpqHeFltTolPowerSupplyEntry = '.1.3.6.1.4.1.232.6.2.9.3.1';
my $oid_cpqHeFltTolPowerSupplyRedundantPartner = '.1.3.6.1.4.1.232.6.2.9.3.1.17';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqHeFltTolPowerSupplyEntry, start => $mapping->{cpqHeFltTolPowerSupplyPresent}->{oid}, end => $mapping->{cpqHeFltTolPowerSupplyRedundant}->{oid} },
        { oid => $oid_cpqHeFltTolPowerSupplyRedundantPartner };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHeFltTolPowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHeFltTolPowerSupplyPresent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHeFltTolPowerSupplyEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqHeFltTolPowerSupplyRedundantPartner}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{cpqHeFltTolPowerSupplyPresent} !~ /present/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("powersupply '%s' status is %s [redundance: %s, redundant partner: %s] (status %s).",
                                    $instance, $result->{cpqHeFltTolPowerSupplyCondition},
                                    $result->{cpqHeFltTolPowerSupplyRedundant}, 
                                    defined($result2->{cpqHeFltTolPowerSupplyRedundantPartner}) ? $result2->{cpqHeFltTolPowerSupplyRedundantPartner} : 'unknown',
                                    $result->{cpqHeFltTolPowerSupplyStatus}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{cpqHeFltTolPowerSupplyCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("powersupply '%s' status is %s",
                                           $instance, $result->{cpqHeFltTolPowerSupplyCondition}));
        }
        
        $self->{output}->perfdata_add(
            label => 'psu_power', unit => 'W',
            nlabel => 'hardware.powersupply.power.watt',
            instances => $instance,
            value => $result->{cpqHeFltTolPowerSupplyCapacityUsed},
            critical => $result->{cpqHeFltTolPowerSupplyCapacityMaximum}
        );
        $self->{output}->perfdata_add(
            label => 'psu_voltage', unit => 'V',
            nlabel => 'hardware.powersupply.voltage.volt',
            instances => $instance,
            value => $result->{cpqHeFltTolPowerSupplyMainVoltage}
        );
    }
}

1;
