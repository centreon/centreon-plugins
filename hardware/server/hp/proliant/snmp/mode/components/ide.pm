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

package hardware::server::hp::proliant::snmp::mode::components::ide;

use strict;
use warnings;
use centreon::plugins::misc;

# In 'CPQIDE-MIB.mib'

my %controllerstatus_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
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
    3 => 'degraded',
    4 => 'rebuilding',
    5 => 'failed',
);

my %pdrive_status_map = (
    1 => 'other',
    2 => 'ok',
    3 => 'smartError',
    4 => 'failed',
);

sub controller {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ide controllers");
    $self->{components}->{idectl} = {name => 'ide controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'idectl'));
    
    my $oid_cpqIdeControllerIndex = '.1.3.6.1.4.1.232.14.2.3.1.1.1';
    my $oid_cpqIdeControllerCondition = '.1.3.6.1.4.1.232.14.2.3.1.1.7';
    my $oid_cpqIdeControllerModel = '.1.3.6.1.4.1.232.14.2.3.1.1.3';
    my $oid_cpqIdeControllerSlot = '.1.3.6.1.4.1.232.14.2.3.1.1.5';
    my $oid_cpqIdeControllerStatus = '.1.3.6.1.4.1.232.14.2.3.1.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqIdeControllerIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqIdeControllerCondition, $oid_cpqIdeControllerModel,
                                 $oid_cpqIdeControllerSlot, $oid_cpqIdeControllerStatus],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $ide_model = centreon::plugins::misc::trim($result2->{$oid_cpqIdeControllerModel . '.' . $instance});
        my $ide_slot = $result2->{$oid_cpqIdeControllerSlot . '.' . $instance};
        my $ide_condition = $result2->{$oid_cpqIdeControllerCondition . '.' . $instance};
        my $ide_status = $result2->{$oid_cpqIdeControllerStatus . '.' . $instance};

        next if ($self->check_exclude(section => 'idectl', instance => $instance));
        $self->{components}->{idectl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ide controller %s [slot: %s, model: %s, status: %s] condition is %s.", 
                                    $instance, $ide_slot, $ide_model, $controllerstatus_map{$ide_status},
                                    ${$conditions{$ide_condition}}[0]));
        if (${$conditions{$ide_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$ide_condition}}[1],
                                        short_msg => sprintf("ide controller %d is %s", 
                                            $instance, ${$conditions{$ide_condition}}[0]));
        }
    }
}

sub logical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ide logical drives");
    $self->{components}->{ideldrive} = {name => 'ide logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'ideldrive'));
    
    my $oid_cpqIdeLogicalDriveCondition = '.1.3.6.1.4.1.232.14.2.6.1.1.6';
    my $oid_cpqIdeLogicalDriveStatus = '.1.3.6.1.4.1.232.14.2.6.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqIdeLogicalDriveCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqIdeLogicalDriveStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $ldrive_status = $result2->{$oid_cpqIdeLogicalDriveStatus . '.' . $instance};
        my $ldrive_condition = $result->{$key};

        next if ($self->check_exclude(section => 'ideldrive', instance => $instance));
        $self->{components}->{ideldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ide logical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $ldrive_status_map{$ldrive_status},
                                    ${$conditions{$ldrive_condition}}[0]));
        if (${$conditions{$ldrive_condition}}[1] ne 'OK') {
            if ($ldrive_status_map{$ldrive_status} =~ /rebuild/i) {
                $self->{output}->output_add(severity => 'WARNING',
                                            short_msg => sprintf("ide logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            } else {
                $self->{output}->output_add(severity => ${$conditions{$ldrive_condition}}[1],
                                            short_msg => sprintf("ide logical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$ldrive_condition}}[0]));
            }
        }
    }
}

sub physical_drive {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ide physical drives");
    $self->{components}->{idepdrive} = {name => 'ide physical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'idepdrive'));
    
    my $oid_cpqIdeAtaDiskCondition = '.1.3.6.1.4.1.232.14.2.4.1.1.7';
    my $oid_cpqIdeAtaDiskStatus = '.1.3.6.1.4.1.232.14.2.4.1.1.6';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqIdeAtaDiskCondition);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqIdeAtaDiskStatus],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my $controller_index = $1;
        my $drive_index = $2;
        my $instance = $1 . '.' . $2;

        my $pdrive_status = $result2->{$oid_cpqIdeAtaDiskStatus . '.' . $instance};
        my $pdrive_condition = $result->{$key};

        next if ($self->check_exclude(section => 'idepdrive', instance => $instance));
        $self->{components}->{idepdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ide physical drive %s [status: %s] condition is %s.", 
                                    $controller_index . ':' . $drive_index,
                                    $pdrive_status_map{$pdrive_status},
                                    ${$conditions{$pdrive_condition}}[0]));
        if (${$conditions{$pdrive_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$pdrive_condition}}[1],
                                       short_msg => sprintf("ide physical drive %s is %s", 
                                                $controller_index . ':' . $drive_index, ${$conditions{$pdrive_condition}}[0]));
        }
    }
}

1;