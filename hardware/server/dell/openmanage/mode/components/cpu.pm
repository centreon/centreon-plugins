#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::openmanage::mode::components::cpu;

use strict;
use warnings;

my %status = (
    1 => ['other', 'CRITICAL'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %statusState = (
    1 => 'other',
    2 => 'unknown',
    3 => 'enabled',
    4 => 'userDisabled',
    5 => 'biosDisabled',
    6 => 'idle',
);

my %statusReading = (
    1 => 'internalError',
    2 => 'thermalTrip',
    32 => 'configurationError',
    128 => 'Present',
    256 => 'Disabled',
    512 => 'terminatorPresent',
    1024 => 'throttled',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking Processor Units");
    $self->{components}->{cpu} = {name => 'CPUs', total => 0};
    return if ($self->check_exclude('cpu'));
   
    my $oid_cpuStatus = '.1.3.6.1.4.1.674.10892.1.1100.30.1.5';
    my $oid_cpuManufacturerName = '.1.3.6.1.4.1.674.10892.1.1100.30.1.8';
    my $oid_cpuStatusState = '.1.3.6.1.4.1.674.10892.1.1100.30.1.9';
    my $oid_cpuCurrentSpeed = '.1.3.6.1.4.1.674.10892.1.1100.30.1.12';
    my $oid_cpuBrandName = '.1.3.6.1.4.1.674.10892.1.1100.30.1.23';
    my $oid_cpuChassis = '.1.3.6.1.4.1.674.10892.1.1100.32.1.1';
    my $oid_cpuStatusReading = '.1.3.6.1.4.1.674.10892.1.1100.32.1.6';

    my $result = $self->{snmp}->get_table(oid => $oid_cpuStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_cpuManufacturerName, $oid_cpuStatusState, $oid_cpuCurrentSpeed, $oid_cpuBrandName, $oid_cpuChassis, $oid_cpuStatusReading],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $cpu_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $cpu_Index;
        
        my $cpu_Status = $result->{$key};
        my $cpu_ManufacturerName = $result2->{$oid_cpuManufacturerName . '.' . $instance};
        my $cpu_StatusState = $result2->{$oid_cpuStatusState . '.' . $instance};
        my $cpu_CurrentSpeed = $result2->{$oid_cpuCurrentSpeed . '.' . $instance};
        my $cpu_BrandName = $result2->{$oid_cpuBrandName . '.' . $instance};
        my $cpu_Chassis = $result2->{$oid_cpuChassis . '.' . $instance};
        my $cpu_StatusReading =  $result2->{$oid_cpuStatusReading . '.' . $instance};
        
        $self->{components}->{cpu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("cpu %d status is %s, state is %s, current speed is %d MHz [model: %s].",
                                    $cpu_Index, ${$status{$cpu_Status}}[0], $statusState{$cpu_StatusState},
                                    $cpu_CurrentSpeed, $cpu_BrandName
                                    ));

        if ($cpu_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$cpu_Status}}[1],
                                        short_msg => sprintf("cpu %d status is %s",
                                           $cpu_Index, ${$status{$cpu_Status}}[0]));
        }

    }
}

1;
