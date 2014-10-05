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

package hardware::server::hp::proliant::snmp::mode::components::fca;

use strict;
use warnings;

# In 'CPQFCA-MIB.mib'

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
);

my %model_map = (
    1 => 'other',
    2 => 'fchc-p',
    3 => 'fchc-e',
    4 => 'fchc64',
    5 => 'sa-sam',
    6 => 'fca-2101',
    7 => 'sw64-33',
    8 => 'fca-221x',
    9 => 'dpfcmc',
    10 => 'fca-2404',
    11 => 'fca-2214',
    12 => 'a7298a',
    13 => 'fca-2214dc',
    14 => 'a6826a',
    15 => 'fcmcG3',
    16 => 'fcmcG4',
    17 => 'ab46xa',
    18 => 'fc-generic',
    19 => 'fca-1143',
    20 => 'fca-1243',
    21 => 'fca-2143',
    22 => 'fca-2243',
    23 => 'fca-1050',
    24 => 'fca-lpe1105',
    25 => 'fca-qmh2462',
    26 => 'fca-1142sr',
    27 => 'fca-1242sr',
    28 => 'fca-2142sr',
    29 => 'fca-2242sr',
    30 => 'fcmc20pe',
    31 => 'fca-81q',
    32 => 'fca-82q',
    33 => 'fca-qmh2562',
    34 => 'fca-81e',
    35 => 'fca-82e',
    36 => 'fca-1205',
);

my %hostctlstatus_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'shutdown',
    5 => 'loopDegraded',
    6 => 'loopFailed',
    7 => 'notConnected',
);

my %external_model_map = (
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

my %externalctlstatus_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'offline',
    5 => 'redundantPathOffline',
    6 => 'notConnected',
);

my %externalrole_map = (
    1 => 'other',
    2 => 'notDuplexed',
    3 => 'active',
    4 => 'backup',
);

my %accelstatus_map = (
    1 => 'other',
    2 => 'invalid',
    3 => 'enabled',
    4 => 'tmpDisabled',
    5 => 'permDisabled',
);

my %conditionsbattery = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['recharging', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
    5 => ['degraded', 'WARNING'],
    6 => ['not present', 'OK'],
);

my %ldrive_fault_tolerance_map = (
    1 => 'other',
    2 => 'none',
    3 => 'mirroring',
    4 => 'dataGuard',
    5 => 'distribDataGuard',
    7 => 'advancedDataGuard',
);

my %ldrive_status_map = (
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
    15 => 'hardError',
);

my %pdrive_status_map = (
    1 => 'other',
    2 => 'unconfigured',
    3 => 'ok',
    4 => 'threshExceeded',
    5 => 'predictiveFailure',
    6 => 'failed',
    7 => 'unsupportedDrive',
);

sub host_array_controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca host controller");
    $self->{components}->{fcahostctl} = {name => 'fca host controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcahostctl'));
    
    my $oid_cpqFcaHostCntlrIndex = '.1.3.6.1.4.1.232.16.2.7.1.1.1';
    my $oid_cpqFcaHostCntlrSlot = '.1.3.6.1.4.1.232.16.2.7.1.1.2';
    my $oid_cpqFcaHostCntlrStatus = '.1.3.6.1.4.1.232.16.2.7.1.1.4';
    my $oid_cpqFcaHostCntlrModel = '.1.3.6.1.4.1.232.16.2.7.1.1.3';
    my $oid_cpqFcaHostCntlrCondition = '.1.3.6.1.4.1.232.16.2.7.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqFcaHostCntlrIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqFcaHostCntlrSlot, $oid_cpqFcaHostCntlrStatus,
                                 $oid_cpqFcaHostCntlrCondition],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $fca_index = $1;
        my $fca_status = $result2->{$oid_cpqFcaHostCntlrStatus . '.' . $instance};
        my $fca_model = $result2->{$oid_cpqFcaHostCntlrModel . '.' . $instance};
        my $fca_slot = $result2->{$oid_cpqFcaHostCntlrSlot . '.' . $instance};
        my $fca_condition = $result2->{$oid_cpqFcaHostCntlrCondition . '.' . $instance};
        
        next if ($self->check_exclude(section => 'fcahostctl', instance => $instance));
        $self->{components}->{fcahostctl}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fca host controller %s [slot: %s, model: %s, status: %s] condition is %s.", 
                                    $fca_index, $fca_slot, $model_map{$fca_model}, $hostctlstatus_map{$fca_status},
                                    ${$conditions{$fca_condition}}[0]));
        if (${$conditions{$fca_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$fca_condition}}[1],
                                        short_msg => sprintf("fca host controller %s is %s", 
                                            $fca_index, ${$conditions{$fca_condition}}[0]));
        }
    }
}

sub external_array_controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca external controller");
    $self->{components}->{fcaexternalctl} = {name => 'fca external controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcaexternalctl'));
    
    my $oid_cpqFcaCntlrCondition = '.1.3.6.1.4.1.232.16.2.2.1.1.6';
    my $oid_cpqFcaCntlrModel = '.1.3.6.1.4.1.232.16.2.2.1.1.3';
    my $oid_cpqFcaCntlrStatus = '.1.3.6.1.4.1.232.16.2.2.1.1.5';
    my $oid_cpqFcaCntlrCurrentRole = '.1.3.6.1.4.1.232.16.2.2.1.1.10';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqFcaCntlrCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqFcaCntlrModel, $oid_cpqFcaCntlrStatus,
                                 $oid_cpqFcaCntlrCurrentRole],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $fca_box_index = $1;
        my $fca_box_slot = $2;
        my $instance = $1 . '.' . $2;

        my $fca_status = $result2->{$oid_cpqFcaCntlrStatus . '.' . $instance};
        my $fca_model = $result2->{$oid_cpqFcaCntlrModel . '.' . $instance};
        my $fca_role = $result2->{$oid_cpqFcaCntlrCurrentRole . '.' . $instance};
        my $fca_condition = $result->{$key};
        
        next if ($self->check_exclude(section => 'fcaexternalctl', instance => $instance));
        $self->{components}->{fcaexternalctl}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fca external controller %s [model: %s, status: %s, role: %s] condition is %s.", 
                                    $fca_box_index . ':' . $fca_box_slot,
                                    $external_model_map{$fca_model}, $externalctlstatus_map{$fca_status}, $externalrole_map{$fca_role},
                                    ${$conditions{$fca_condition}}[0]));
        if (${$conditions{$fca_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$fca_condition}}[1],
                                        short_msg => sprintf("fca external controller %s is %s", 
                                            $fca_box_index . ':' . $fca_box_slot, ${$conditions{$fca_condition}}[0]));
        }
    }
}

sub external_array_accelerator {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca external accelerator boards");
    $self->{components}->{fcaexternalacc} = {name => 'fca external accelerator boards', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcaexternalacc'));
    
    my $oid_cpqFcaAccelCondition = '.1.3.6.1.4.1.232.16.2.2.2.1.9';
    my $oid_cpqFcaAccelStatus = '.1.3.6.1.4.1.232.16.2.2.2.1.3';
    my $oid_cpqFcaAccelBatteryStatus = '.1.3.6.1.4.1.232.16.2.2.2.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqFcaAccelCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqFcaAccelStatus, $oid_cpqFcaAccelBatteryStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $fca_box_index = $1;
        my $fca_box_slot = $2;
        my $instance = $1 . '.' . $2;

        my $accel_status = $result2->{$oid_cpqFcaAccelStatus . '.' . $instance};
        my $accel_condition = $result->{$key};
        my $accel_battery = $result2->{$oid_cpqFcaAccelBatteryStatus . '.' . $instance};
        
        next if ($self->check_exclude(section => 'fcaexternalacc', instance => $instance));
        $self->{components}->{fcaexternalacc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca external accelerator boards %s [status: %s, battery status: %s] condition is %s.", 
                                    $fca_box_index . ':' . $fca_box_slot, 
                                    $accelstatus_map{$accel_status}, ${$conditionsbattery{$accel_battery}}[0],
                                    ${$conditions{$accel_condition}}[0]));
        if (${$conditions{$accel_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$accel_condition}}[1],
                                        short_msg => sprintf("fca external accelerator boards %s is %s", 
                                            $$fca_box_index . ':' . $fca_box_slot, ${$conditions{$accel_condition}}[0]));
        }
        if (${$conditionsbattery{$accel_battery}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditionsbattery{$accel_battery}}[1],
                                        short_msg => sprintf("fca external accelerator boards %s battery is %s", 
                                            $fca_box_index . ':' . $fca_box_slot, ${$conditionsbattery{$accel_battery}}[0]));
        }
    }
}

sub logical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca logical drives");
    $self->{components}->{fcaldrive} = {name => 'fca logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcaldrive'));
    
    my $oid_cpqFcaLogDrvCondition = '.1.3.6.1.4.1.232.16.2.3.1.1.11';
    my $oid_cpqFcaLogDrvStatus = '.1.3.6.1.4.1.232.16.2.3.1.1.4';
    my $oid_cpqFcaLogDrvFaultTol = '.1.3.6.1.4.1.232.16.2.3.1.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqFcaLogDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqFcaLogDrvStatus,
                                 $oid_cpqFcaLogDrvFaultTol],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $box_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $ldrive_status = $result2->{$oid_cpqFcaLogDrvStatus . '.' . $instance};
        my $ldrive_condition = $result->{$key};
        my $ldrive_faultol = $result2->{$oid_cpqFcaLogDrvFaultTol . '.' . $instance};
        
        next if ($self->check_exclude(section => 'fcaldrive', instance => $instance));
        $self->{components}->{fcaldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca logical drive %s [fault tolerance: %s, status: %s] condition is %s.", 
                                    $box_index . ':' . $drive_index,
                                    $ldrive_fault_tolerance_map{$ldrive_faultol}, 
                                    $ldrive_status_map{$ldrive_status},
                                    ${$conditions{$ldrive_condition}}[0]));
        if (${$conditions{$ldrive_condition}}[1] ne 'OK') {
            if ($ldrive_status_map{$ldrive_status} =~ /rebuild|recovering|expand/i) {
                $self->{output}->output_add(severity => 'WARNING',
                                            short_msg => sprintf("fca logical drive %s is %s", 
                                                $box_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            } else {
                $self->{output}->output_add(severity => ${$conditions{$ldrive_condition}}[1],
                                            short_msg => sprintf("fca logical drive %s is %s", 
                                                $box_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            }
        }
    }
}

sub physical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca physical drives");
    $self->{components}->{fcapdrive} = {name => 'fca physical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcapdrive'));
    
    my $oid_cpqFcaPhyDrvCondition = '.1.3.6.1.4.1.232.16.2.5.1.1.31';
    my $oid_cpqFcaPhyDrvStatus = '.1.3.6.1.4.1.232.16.2.5.1.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqFcaPhyDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqFcaPhyDrvStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $box_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $pdrive_status = $result2->{$oid_cpqFcaPhyDrvStatus . '.' . $instance};
        my $pdrive_condition = $result->{$key};
        
        next if ($self->check_exclude(section => 'fcapdrive', instance => $instance));
        $self->{components}->{fcapdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca physical drive %s [status: %s] condition is %s.", 
                                    $box_index . ':' . $drive_index,
                                    $pdrive_status_map{$pdrive_status},
                                    ${$conditions{$pdrive_condition}}[0]));
        if (${$conditions{$pdrive_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$pdrive_condition}}[1],
                                       short_msg => sprintf("fca physical drive %s is %s", 
                                                $box_index . ':' . $drive_index, ${$conditions{$pdrive_condition}}[0]));
        }
    }
}

1;