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

package hardware::server::hpproliant::mode::components::sas;

use strict;
use warnings;
use centreon::plugins::misc;

# In 'CPQSCSI-MIB.mib'

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
    1 => "other",
    2 => "ok",
    3 => "degraded",
    4 => "rebuilding",
    5 => "failed",
    6 => "offline",
);

my %pdrive_status_map = (
    1 => "other",
    2 => "ok",
    3 => "predictiveFailure",
    4 => "offline",
    5 => "failed",
    6 => "missingWasOk",
    7 => "missingWasPredictiveFailure",
    8 => "missingWasOffline",
    9 => "missingWasFailed",
);

sub controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas controllers");
    $self->{components}->{sasctl} = {name => 'sas controllers', total => 0};
    return if ($self->check_exclude('sasctl'));
    
    my $oid_cpqSasHbaIndex = '.1.3.6.1.4.1.232.5.5.1.1.1.1';
    my $oid_cpqSasHbaCondition = '.1.3.6.1.4.1.232.5.5.1.1.1.5';
    my $oid_cpqSasHbaSlot = '.1.3.6.1.4.1.232.5.5.1.1.1.6';
    my $oid_cpqSasHbaStatus  = '.1.3.6.1.4.1.232.5.5.1.1.1.4';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqSasHbaIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqSasHbaCondition, $oid_cpqSasHbaSlot,
                                 $oid_cpqSasHbaStatus],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $sas_slot = $result2->{$oid_cpqSasHbaSlot . '.' . $instance};
        my $sas_condition = $result2->{$oid_cpqSasHbaCondition . '.' . $instance};
        my $sas_status = $result2->{$oid_cpqSasHbaStatus . '.' . $instance};
        
        $self->{components}->{sasctl}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sas controller %s [slot: %s, status: %s] condition is %s.", 
                                    $instance, $sas_slot, $controllerstatus_map{$sas_status},
                                    ${$conditions{$sas_condition}}[0]));
        if (${$conditions{$sas_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$sas_condition}}[1],
                                        short_msg => sprintf("sas controller %d is %s", 
                                            $instance, ${$conditions{$sas_condition}}[0]));
        }
    }
}

sub logical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas logical drives");
    $self->{components}->{sasldrive} = {name => 'sas logical drives', total => 0};
    return if ($self->check_exclude('sasldrive'));
    
    my $oid_cpqSasLogDrvCondition = '.1.3.6.1.4.1.232.5.5.3.1.1.5';
    my $oid_cpqSasLogDrvStatusValue = '.1.3.6.1.4.1.232.5.5.3.1.1.4';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqSasLogDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqSasLogDrvStatusValue],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $ldrive_status = $result2->{$oid_cpqSasLogDrvStatusValue . '.' . $instance};
        my $ldrive_condition = $result->{$key};
        
        $self->{components}->{sasldrive}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sas logical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $ldrive_status_map{$ldrive_status},
                                    ${$conditions{$ldrive_condition}}[0]));
        if (${$conditions{$ldrive_condition}}[1] ne 'OK') {
            if ($ldrive_status_map{$ldrive_status} =~ /rebuild/i) {
                $self->{output}->output_add(severity => 'WARNING',
                                            short_msg => sprintf("sas logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            } else {
                $self->{output}->output_add(severity => ${$conditions{$ldrive_condition}}[1],
                                            short_msg => sprintf("sas logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            }
        }
    }
}

sub physical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas physical drives");
    $self->{components}->{saspdrive} = {name => 'sas physical drives', total => 0};
    return if ($self->check_exclude('saspdrive'));
    
    my $oid_cpqSasPhyDrvCondition = '.1.3.6.1.4.1.232.5.5.2.1.1.6';
    my $oid_cpqSasPhyDrvStatus = '.1.3.6.1.4.1.232.5.5.2.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqSasPhyDrvCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqSasPhyDrvStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $pdrive_status = $result2->{$oid_cpqSasPhyDrvStatus . '.' . $instance};
        my $pdrive_condition = $result->{$key};
        
        $self->{components}->{saspdrive}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sas physical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $pdrive_status_map{$pdrive_status},
                                    ${$conditions{$pdrive_condition}}[0]));
        if (${$conditions{$pdrive_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$pdrive_condition}}[1],
                                       short_msg => sprintf("sas physical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$pdrive_condition}}[0]));
        }
    }
}

1;