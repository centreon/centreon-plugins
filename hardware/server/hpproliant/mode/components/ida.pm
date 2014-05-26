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

package hardware::server::hpproliant::mode::components::ida;

use strict;
use warnings;

# In 'CPQIDA-MIB.mib'

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

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
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
    8 => 'raid50',
    9 => 'raid60',
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
    15 => 'multipathAccessDegraded',
    16 => 'erasing'
);

my %pdrive_status_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'predictiveFailure',
    5 => 'erasing',
    6 => 'eraseDone',
    7 => 'eraseQueued',
);

sub array_controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da controller");
    $self->{components}->{dactl} = {name => 'da controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'dactl'));
    
    my $oid_cpqDaCntlrIndex = '.1.3.6.1.4.1.232.3.2.2.1.1.1';
    my $oid_cpqDaCntlrModel = '.1.3.6.1.4.1.232.3.2.2.1.1.2';
    my $oid_cpqDaCntlrSlot = '.1.3.6.1.4.1.232.3.2.2.1.1.5';
    my $oid_cpqDaCntlrCondition = '.1.3.6.1.4.1.232.3.2.2.1.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqDaCntlrIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqDaCntlrModel, $oid_cpqDaCntlrSlot,
                                 $oid_cpqDaCntlrCondition],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $da_model = $result2->{$oid_cpqDaCntlrModel . '.' . $instance};
        my $da_slot = $result2->{$oid_cpqDaCntlrSlot . '.' . $instance};
        my $da_condition = $result2->{$oid_cpqDaCntlrCondition . '.' . $instance};

        next if ($self->check_exclude(section => 'dactl', instance => $instance));
        $self->{components}->{dactl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da controller %s [slot: %s, model: %s] status is %s.", 
                                    $instance, $da_slot, $model_map{$da_model},
                                    ${$conditions{$da_condition}}[0]));
        if (${$conditions{$da_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$da_condition}}[1],
                                        short_msg => sprintf("da controller %d is %s", 
                                            $instance, ${$conditions{$da_condition}}[0]));
        }
    }
}

sub array_accelerator {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da accelerator boards");
    $self->{components}->{daacc} = {name => 'da accelerator boards', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'daacc'));
    
    my $oid_cpqDaAccelCntlrIndex = '.1.3.6.1.4.1.232.3.2.2.2.1.1';
    my $oid_cpqDaAccelStatus = '.1.3.6.1.4.1.232.3.2.2.2.1.2';
    my $oid_cpqDaAccelCondition = '.1.3.6.1.4.1.232.3.2.2.2.1.9';
    my $oid_cpqDaAccelBattery = '.1.3.6.1.4.1.232.3.2.2.2.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqDaAccelCntlrIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqDaAccelStatus, $oid_cpqDaAccelCondition,
                                 $oid_cpqDaAccelBattery],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $accel_status = $result2->{$oid_cpqDaAccelStatus . '.' . $instance};
        my $accel_condition = $result2->{$oid_cpqDaAccelCondition . '.' . $instance};
        my $accel_battery = $result2->{$oid_cpqDaAccelBattery . '.' . $instance};

        next if ($self->check_exclude(section => 'daacc', instance => $instance));
        $self->{components}->{daacc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da controller accelerator %s [status: %s, battery status: %s] condition is %s.", 
                                    $instance, $accelstatus_map{$accel_status}, ${$conditionsbattery{$accel_battery}}[0],
                                    ${$conditions{$accel_condition}}[0]));
        if (${$conditions{$accel_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$accel_condition}}[1],
                                        short_msg => sprintf("da controller accelerator %d is %s", 
                                            $instance, ${$conditions{$accel_condition}}[0]));
        }
        if (${$conditionsbattery{$accel_battery}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditionsbattery{$accel_battery}}[1],
                                        short_msg => sprintf("da controller accelerator %d battery is %s", 
                                            $instance, ${$conditionsbattery{$accel_battery}}[0]));
        }
    }
}

sub logical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da logical drives");
    $self->{components}->{daldrive} = {name => 'da logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'daldrive'));
    
    my $oid_cpqDaLogDrvCondition = '.1.3.6.1.4.1.232.3.2.3.1.1.11';
    my $oid_cpqDaLogDrvStatus = '.1.3.6.1.4.1.232.3.2.3.1.1.4';
    my $oid_cpqDaLogDrvFaultTol = '.1.3.6.1.4.1.232.3.2.3.1.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqDaLogDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqDaLogDrvStatus,
                                 $oid_cpqDaLogDrvFaultTol],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $ldrive_status = $result2->{$oid_cpqDaLogDrvStatus . '.' . $instance};
        my $ldrive_condition = $result->{$key};
        my $ldrive_faultol = $result2->{$oid_cpqDaLogDrvFaultTol . '.' . $instance};

        next if ($self->check_exclude(section => 'daldrive', instance => $instance));
        $self->{components}->{daldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da logical drive %s [fault tolerance: %s, status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $ldrive_fault_tolerance_map{$ldrive_faultol}, 
                                    $ldrive_status_map{$ldrive_status},
                                    ${$conditions{$ldrive_condition}}[0]));
        if (${$conditions{$ldrive_condition}}[1] ne 'OK') {
            if ($ldrive_status_map{$ldrive_status} =~ /rebuild|recovering|recovery|expanding|queued/i) {
                $self->{output}->output_add(severity => 'WARNING',
                                            short_msg => sprintf("da logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            } else {
                $self->{output}->output_add(severity => ${$conditions{$ldrive_condition}}[1],
                                            short_msg => sprintf("da logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            }
        }
    }
}

sub physical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da physical drives");
    $self->{components}->{dapdrive} = {name => 'da physical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'dapdrive'));
    
    my $oid_cpqDaPhyDrvCondition = '.1.3.6.1.4.1.232.3.2.5.1.1.37';
    my $oid_cpqDaPhyDrvStatus = '.1.3.6.1.4.1.232.3.2.5.1.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqDaPhyDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqDaPhyDrvStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $pdrive_status = $result2->{$oid_cpqDaPhyDrvStatus . '.' . $instance};
        my $pdrive_condition = $result->{$key};

        next if ($self->check_exclude(section => 'dapdrive', instance => $instance));
        $self->{components}->{dapdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da physical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $pdrive_status_map{$pdrive_status},
                                    ${$conditions{$pdrive_condition}}[0]));
        if (${$conditions{$pdrive_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$pdrive_condition}}[1],
                                       short_msg => sprintf("da physical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$pdrive_condition}}[0]));
        }
    }
}

1;