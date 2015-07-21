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

package hardware::server::dell::openmanage::mode::components::logicaldrive;

use strict;
use warnings;

my %state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
    15 => 'resynching',
    24 => 'rebuild',
    26 => 'formatting',
    35 => 'initializing',
);

my %layout = (
    1 => 'Concatened',
    2 => 'RAID-0',
    3 => 'RAID-1',
    4 => 'RAID-2',
    5 => 'RAID-3',
    6 => 'RAID-4',
    7 => 'RAID-5',
    8 => 'RAID-6',
    9 => 'RAID-7',
    10 => 'RAID-10',
    11 => 'RAID-30',
    12 => 'RAID-50',
    13 => 'Add spares', 
    14 => 'Delete logical',
    15 => 'Transform logical',
    18 => 'RAID-0-plus-1 - Mylex only',
    19 => 'Concatened RAID 1',
    20 => 'Concatened RAID 5',
    21 => 'no RAID',
    22 => 'RAID Morph - Adapted only',
);

my %componentStatus = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Logical Drives");
    $self->{components}->{logicaldrive} = {name => 'logical drives', total => 0};
    return if ($self->check_exclude('logicaldrive'));
   
    my $oid_diskName = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.2';
    my $oid_diskDeviceName = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.3';
    my $oid_diskState = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.4';
    my $oid_diskLengthInMB = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.6';
    my $oid_diskLayout = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.13';
    my $oid_diskComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.140.1.1.20';

    my $result = $self->{snmp}->get_table(oid => $oid_diskName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_diskDeviceName, $oid_diskState, $oid_diskLengthInMB, $oid_diskLayout, $oid_diskComponentStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $disk_Index = $1;
        
        my $disk_Name = $result->{$key};
        my $disk_DeviceName =  $result2->{$oid_diskDeviceName . '.' . $disk_Index};
        my $disk_State = $result2->{$oid_diskState . '.' . $disk_Index};
        my $disk_LengthInMB = $result2->{$oid_diskLengthInMB . '.' . $disk_Index};
        my $disk_Layout = $result2->{$oid_diskLayout . '.' . $disk_Index};
        my $disk_ComponentStatus = $result2->{$oid_diskComponentStatus . '.' . $disk_Index};
    
        $self->{components}->{logicaldrive}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("logical drive %s status is %s, state is %s, layout is %s, size is %d MB [device: %s, index: %d].",
                                    $disk_Name, ${$componentStatus{$disk_ComponentStatus}}[0], $state{$disk_State},
                                    $layout{$disk_Layout}, $disk_LengthInMB, $disk_DeviceName, $disk_Index
                                    ));

        if ($disk_ComponentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$componentStatus{$disk_ComponentStatus}}[1],
                                        short_msg => sprintf("logical drive %s status is %s [device: %s, index: %d]",
                                           $disk_Name, ${$componentStatus{$disk_ComponentStatus}}[0], $disk_DeviceName, $disk_Index));
        }

    }
}

1;
