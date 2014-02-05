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
   
    my $oid_cpuStatus = '.1.3.6.1.4.1.674.10892.1.1100.30.1.5.1';
    my $oid_cpuManufacturerName = '.1.3.6.1.4.1.674.10892.1.1100.30.1.8.1';
    my $oid_cpuStatusState = '.1.3.6.1.4.1.674.10892.1.1100.30.1.9.1';
    my $oid_cpuCurrentSpeed = '.1.3.6.1.4.1.674.10892.1.1100.30.1.12.1';
    my $oid_cpuBrandName = '.1.3.6.1.4.1.674.10892.1.1100.30.1.23.1';
    my $oid_cpuChassis = '.1.3.6.1.4.1.674.10892.1.1100.32.1.1.1';
    my $oid_cpuStatusReading = '.1.3.6.1.4.1.674.10892.1.1100.32.1.6.1';

    my $result = $self->{snmp}->get_table(oid => $oid_cpuStatus);
    return if (scalar(keys %$result) <= 0);

    my $result2 = $self->{snmp}->get_leef(oids => [$oid_cpuManufacturerName, $oid_cpuStatusState, $oid_cpuCurrentSpeed, $oid_cpuBrandName, $oid_cpuChassis, $oid_cpuStatusReading],
                                          instances => [keys %$result],
                                          instance_regexp => '(\.\d+)$');
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.(\d+)$/;
        my $cpu_Index = $1;
        
        my $cpu_Status = $result->{$key};
        my $cpu_ManufacturerName = $result2->{$oid_cpuManufacturerName . '.' . $cpu_Index};
        my $cpu_StatusState = $result2->{$oid_cpuStatusState . '.' . $cpu_Index};
        my $cpu_CurrentSpeed = $result->{$oid_cpuCurrentSpeed . '.' . $cpu_Index};
        my $cpu_BrandName = $result2->{$oid_cpuBrandName . '.' . $cpu_Index};
        my $cpu_Chassis = $result2->{$oid_cpuChassis . '.' . $cpu_Index};
        my $cpu_StatusReading =  $result2->{$oid_cpuStatusReading . '.' . $cpu_Index};
        
        $self->{components}->{cpu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("cpu %d status is %s, state is %s, current speed is %d MHz [chassis: %d, Model: %s].",
                                    $cpu_Index, ${$status{$cpu_Status}}[0], ${$statusState{$cpu_StatusState}}[0],
                                    $cpu_CurrentSpeed, $chassis_Index, $cpu_BrandName
                                    ));

        if ($cpu_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$cpu_Status}}[1],
                                        short_msg => sprintf("cpu %d status is %s",
                                           $cpu_Index, ${$status{$cpu_Status}}[0]));
        }

    }
}

1;
