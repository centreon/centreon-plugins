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

package hardware::server::hp::bladechassis::snmp::mode::components::temperature;

use strict;
use warnings;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

my %map_temp_type = (
    1 => 'other',
    5 => 'blowout',
    9 => 'caution',
    15 => 'critical',
);

sub check {
    my ($self) = @_;

    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperatures");
    return if ($self->check_exclude('temperatures'));
    
    my $oid_cpqRackCommonEnclosureTempSensorIndex = '.1.3.6.1.4.1.232.22.2.3.1.2.1.3';
    my $oid_cpqRackCommonEnclosureTempSensorEnclosureName = '.1.3.6.1.4.1.232.22.2.3.1.2.1.4';
    my $oid_cpqRackCommonEnclosureTempLocation = '.1.3.6.1.4.1.232.22.2.3.1.2.1.5';
    my $oid_cpqRackCommonEnclosureTempCurrent = '.1.3.6.1.4.1.232.22.2.3.1.2.1.6';
    my $oid_cpqRackCommonEnclosureTempThreshold = '.1.3.6.1.4.1.232.22.2.3.1.2.1.7';
    my $oid_cpqRackCommonEnclosureTempCondition = '.1.3.6.1.4.1.232.22.2.3.1.2.1.8';
    my $oid_cpqRackCommonEnclosureTempType = '.1.3.6.1.4.1.232.22.2.3.1.2.1.9';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureTempSensorIndex);
    return if (scalar(keys %$result) <= 0);

    my $result2 = $self->{snmp}->get_leef(oids => [$oid_cpqRackCommonEnclosureTempSensorEnclosureName, 
                                                   $oid_cpqRackCommonEnclosureTempLocation,
                                                   $oid_cpqRackCommonEnclosureTempCurrent, $oid_cpqRackCommonEnclosureTempThreshold,
                                                   $oid_cpqRackCommonEnclosureTempCondition, $oid_cpqRackCommonEnclosureTempType],
                                          instances => [keys %$result]);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $temp_index = $1;
        my $temp_name = $result->{$oid_cpqRackCommonEnclosureTempSensorEnclosureName . '.' . $temp_index};
        my $temp_location = $result->{$oid_cpqRackCommonEnclosureTempLocation . '.' . $temp_index};
        my $temp_current = $result->{$oid_cpqRackCommonEnclosureTempCurrent . '.' . $temp_index};
        my $temp_threshold = $result->{$oid_cpqRackCommonEnclosureTempThreshold . '.' . $temp_index};
        my $temp_condition = $result->{$oid_cpqRackCommonEnclosureTempCondition . '.' . $temp_index};
        my $temp_type = $result->{$oid_cpqRackCommonEnclosureTempType . '.' . $temp_index};
        
        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature %d status is %s [name: %s, location: %s] (value = %s, threshold = %s%s).",
                                    $temp_index, ${$conditions{$temp_condition}}[0],
                                    $temp_name, $temp_location,
                                    $temp_current, $temp_threshold,
                                    defined($map_temp_type{$temp_type}) ? ", status type = " . $map_temp_type{$temp_type} : ''));
        if ($temp_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$temp_condition}}[1],
                                        short_msg => sprintf("Temperature %d status is %s",
                                          $temp_index, ${$conditions{$temp_condition}}[0]));
        }
        
        $self->{output}->perfdata_add(label => "temp_" . $temp_index, unit => 'C',
                                      value => $temp_current,
                                      warning => $temp_threshold);
    }
}

1;