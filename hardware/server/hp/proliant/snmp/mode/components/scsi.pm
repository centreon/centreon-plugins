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

package hardware::server::hp::proliant::snmp::mode::components::scsi;
# In 'CPQSCSI-MIB.mib'

use strict;
use warnings;

my %controllerstatus_map = (
    1 => "other",
    2 => "ok",
    3 => "failed",
);

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
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
    10 => 'degraded',
    11 => 'disabled',
);

my %pdrive_status_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'notConfigured',
    5 => 'badCable',
    6 => 'missingWasOk',
    7 => 'missingWasFailed',
    8 => 'predictiveFailure',
    9 => 'missingWasPredictiveFailure',
    10 => 'offline',
    11 => 'missingWasOffline',
    12 => 'hardError',
);

sub controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi controllers");
    $self->{components}->{scsictl} = {name => 'scsi controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'scsictl'));
    
    my $oid_cpqScsiCntlrCondition = '.1.3.6.1.4.1.232.5.2.2.1.1.12';
    my $oid_cpqScsiCntlrSlot = '.1.3.6.1.4.1.232.5.2.2.1.1.6';
    my $oid_cpqScsiCntlrStatus = '.1.3.6.1.4.1.232.5.2.2.1.1.7';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqScsiCntlrCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqScsiCntlrSlot, $oid_cpqScsiCntlrStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $bus_index = $2;
        my $instance = $1 . '.' . $2;

        my $scsi_slot = $result2->{$oid_cpqScsiCntlrSlot . '.' . $instance};
        my $scsi_condition = $result->{$key};
        my $scsi_status = $result2->{$oid_cpqScsiCntlrStatus . '.' . $instance};
        
        next if ($self->check_exclude(section => 'scsictl', instance => $instance));
        $self->{components}->{scsictl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi controller %s [slot: %s, status: %s] condition is %s.", 
                                    $controller_index . ':' . $bus_index, $scsi_slot, $controllerstatus_map{$scsi_status},
                                    ${$conditions{$scsi_condition}}[0]));
        if (${$conditions{$scsi_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$scsi_condition}}[1],
                                        short_msg => sprintf("scsi controller %d is %s", 
                                            $controller_index . ':' . $bus_index, ${$conditions{$scsi_condition}}[0]));
        }
    }
}

sub logical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi logical drives");
    $self->{components}->{scsildrive} = {name => 'scsi logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'scsildrive'));
    
    my $oid_cpqScsiLogDrvCondition = '.1.3.6.1.4.1.232.5.2.3.1.1.8';
    my $oid_cpqScsiLogDrvStatus = '.1.3.6.1.4.1.232.5.2.3.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqScsiLogDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqScsiLogDrvStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $bus_index = $2;
        my $drive_index = $3;
        my $instance = $1 . '.' . $2 . '.' . $3;

        my $ldrive_status = $result2->{$oid_cpqScsiLogDrvStatus . '.' . $instance};
        my $ldrive_condition = $result->{$key};

        next if ($self->check_exclude(section => 'scsildrive', instance => $instance));
        $self->{components}->{scsildrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi logical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $bus_index . ':' . $drive_index,
                                    $ldrive_status_map{$ldrive_status},
                                    ${$conditions{$ldrive_condition}}[0]));
        if (${$conditions{$ldrive_condition}}[1] ne 'OK') {
            if ($ldrive_status_map{$ldrive_status} =~ /rebuild|recovering/i) {
                $self->{output}->output_add(severity => 'WARNING',
                                            short_msg => sprintf("scsi logical drive %s is %s", 
                                                $controller_index . ':' . $bus_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            } else {
                $self->{output}->output_add(severity => ${$conditions{$ldrive_condition}}[1],
                                            short_msg => sprintf("scsi logical drive %s is %s", 
                                                $controller_index . ':' . $bus_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            }
        }
    }
}

sub physical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi physical drives");
    $self->{components}->{scsipdrive} = {name => 'scsi physical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'scsipdrive'));
    
    my $oid_cpqScsiPhyDrvCondition = '.1.3.6.1.4.1.232.5.2.4.1.1.26';
    my $oid_cpqScsiPhyDrvStatus = '.1.3.6.1.4.1.232.5.2.4.1.1.9';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqScsiPhyDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqScsiPhyDrvStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $bus_index = $2;
        my $drive_index = $3;
        my $instance = $1 . '.' . $2 . '.' . $3;

        my $pdrive_status = $result2->{$oid_cpqScsiPhyDrvStatus . '.' . $instance};
        my $pdrive_condition = $result->{$key};

        next if ($self->check_exclude(section => 'scsipdrive', instance => $instance));
        $self->{components}->{scsipdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi physical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $bus_index . ':' . $drive_index,
                                    $pdrive_status_map{$pdrive_status},
                                    ${$conditions{$pdrive_condition}}[0]));
        if (${$conditions{$pdrive_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$pdrive_condition}}[1],
                                       short_msg => sprintf("scsi physical drive %s is %s", 
                                                $controller_index . ':' . $bus_index . ':' . $drive_index, ${$conditions{$pdrive_condition}}[0]));
        }
    }
}

1;