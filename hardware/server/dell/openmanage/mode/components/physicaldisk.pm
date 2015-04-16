################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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
