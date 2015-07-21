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

package hardware::server::dell::openmanage::mode::components::physicaldisk;

use strict;
use warnings;

my %state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
    7 => 'recovering',
    11 => 'removed',
    15 => 'resynching',
    24 => 'rebuild',
    25 => 'noMedia',
    26 => 'formatting',
    28 => 'diagnostics',
    35 => 'initializing',
);

my %spareState = (
    1 => 'memberVD',
    2 => 'memberDG',
    3 => 'globalHostSpare',
    4 => 'dedicatedHostSpare',
    5 => 'notASpare',
);

my %componentStatus = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %smartAlertIndication = (
    1 => ['no', 'OK'],
    2 => ['yes', 'WARNING'],
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Physical Disks");
    $self->{components}->{physicaldisk} = {name => 'physical disks', total => 0};
    return if ($self->check_exclude('physicaldisk'));
   
    my $oid_diskName = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.2';
    my $oid_diskState = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.4';
    my $oid_diskLengthInMB = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.11';
    my $oid_diskSpareState = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.22';
    my $oid_diskComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.24';
    my $oid_diskSmartAlertIndication  = '.1.3.6.1.4.1.674.10893.1.20.130.4.1.31';

    my $result = $self->{snmp}->get_table(oid => $oid_diskName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_diskState, $oid_diskLengthInMB, $oid_diskSpareState, $oid_diskComponentStatus, $oid_diskSmartAlertIndication],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $disk_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $disk_Index;
        
        my $disk_Name = $result->{$key};
        my $disk_State = $result2->{$oid_diskState . '.' . $instance};
        my $disk_LengthInMB = $result2->{$oid_diskLengthInMB . '.' . $instance};
        my $disk_SpareState = $result2->{$oid_diskSpareState . '.' . $instance};
        my $disk_ComponentStatus = $result2->{$oid_diskComponentStatus . '.' . $instance};
	my $disk_SmartAlertIndication = $result2->{$oid_diskSmartAlertIndication . '.' . $instance};
        
        $self->{components}->{physicaldisk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("physical disk '%s' status is %s, state is %s, predictive failure alert %s, spare state is %s, size is %d MB [index: %d].",
                                    $disk_Name, ${$componentStatus{$disk_ComponentStatus}}[0], $state{$disk_State}, ${$smartAlertIndication{$disk_SmartAlertIndication}}[0],
                                    $spareState{$disk_SpareState}, $disk_LengthInMB, $disk_Index
                                    ));
	
	if ($disk_SmartAlertIndication !=1) {
            $self->{output}->output_add(severity =>  ${$smartAlertIndication{$disk_SmartAlertIndication}}[1],
                                        short_msg => sprintf("physical disk '%s' has received a predictive failure alert [index: %d]",
                                           $disk_Name, $disk_Index));
        }

        if ($disk_ComponentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$componentStatus{$disk_ComponentStatus}}[1],
                                        short_msg => sprintf("physical disk '%s' status is %s [index: %d]",
                                           $disk_Name, ${$componentStatus{$disk_ComponentStatus}}[0], $disk_Index));
        }

    }
}

1;
