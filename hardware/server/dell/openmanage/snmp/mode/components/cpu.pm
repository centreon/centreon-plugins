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

package hardware::server::dell::openmanage::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);
my %map_statusState = (
    1 => 'other',
    2 => 'unknown',
    3 => 'enabled',
    4 => 'userDisabled',
    5 => 'biosDisabled',
    6 => 'idle',
);

# In MIB '10892.mib'
my $mapping = {
    processorDeviceStatus => { oid => '.1.3.6.1.4.1.674.10892.1.1100.30.1.5', map => \%map_status },
};
my $mapping2 = {
    processorDeviceManufacturerName => { oid => '.1.3.6.1.4.1.674.10892.1.1100.30.1.8' },
    processorDeviceStatusState => { oid => '.1.3.6.1.4.1.674.10892.1.1100.30.1.9', map => \%map_statusState },
};
my $mapping3 = {
    processorDeviceCurrentSpeed => { oid => '.1.3.6.1.4.1.674.10892.1.1100.30.1.12' }, # in mHz
};
my $mapping4 = {
    processorDeviceBrandName => { oid => '.1.3.6.1.4.1.674.10892.1.1100.30.1.23' },
};
my $oid_processorDeviceTableEntry = '.1.3.6.1.4.1.674.10892.1.1100.30.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{processorDeviceStatus}->{oid} }, 
        { oid => $oid_processorDeviceTableEntry, start => $mapping2->{processorDeviceManufacturerName}->{oid}, end => $mapping2->{processorDeviceStatusState}->{oid} }, 
        { oid => $mapping3->{processorDeviceCurrentSpeed}->{oid} }, { oid => $mapping4->{processorDeviceBrandName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking processor units");
    $self->{components}->{cpu} = {name => 'CPUs', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{processorDeviceStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping->{processorDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{processorDeviceStatus}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_processorDeviceTableEntry}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{processorDeviceCurrentSpeed}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{processorDeviceBrandName}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'cpu', instance => $instance));
        
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Cpu '%s' status is '%s' [instance: %s, manufacturer name: %s, brand name: %s, state: %s, speed: %s]",
                                    $instance, $result->{processorDeviceStatus}, $instance, 
                                    $result2->{processorDeviceManufacturerName}, 
                                    defined($result4->{processorDeviceBrandName}) ? $result4->{processorDeviceBrandName} : '-',
                                    $result2->{processorDeviceStatusState}, $result3->{processorDeviceCurrentSpeed}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'cpu', value => $result->{processorDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cpu '%s' status is '%s'",
                                           $instance, $result->{processorDeviceStatus}));
        }
    }
}

1;
