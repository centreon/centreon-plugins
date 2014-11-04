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

my %map_conditions = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
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

    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking temperatures");
    return if ($self->check_exclude(section => 'temperature'));
    
    my $oid_cpqRackCommonEnclosureTempSensorIndex = '.1.3.6.1.4.1.232.22.2.3.1.2.1.3';
    my $oid_cpqRackCommonEnclosureTempSensorEnclosureName = '.1.3.6.1.4.1.232.22.2.3.1.2.1.4';
    my $oid_cpqRackCommonEnclosureTempLocation = '.1.3.6.1.4.1.232.22.2.3.1.2.1.5';
    my $oid_cpqRackCommonEnclosureTempCurrent = '.1.3.6.1.4.1.232.22.2.3.1.2.1.6';
    my $oid_cpqRackCommonEnclosureTempThreshold = '.1.3.6.1.4.1.232.22.2.3.1.2.1.7';
    my $oid_cpqRackCommonEnclosureTempCondition = '.1.3.6.1.4.1.232.22.2.3.1.2.1.8';
    my $oid_cpqRackCommonEnclosureTempType = '.1.3.6.1.4.1.232.22.2.3.1.2.1.9';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureTempSensorIndex);
    return if (scalar(keys %$result) <= 0);

	$self->{snmp}->load(oids => [$oid_cpqRackCommonEnclosureTempSensorEnclosureName, 
                                                   $oid_cpqRackCommonEnclosureTempLocation,
                                                   $oid_cpqRackCommonEnclosureTempCurrent, $oid_cpqRackCommonEnclosureTempThreshold,
                                                   $oid_cpqRackCommonEnclosureTempCondition, $oid_cpqRackCommonEnclosureTempType],
                                          instances => [keys %$result]);
	my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.(\d+)$/;
        my $temp_index = $1;
        my $temp_name = $result2->{$oid_cpqRackCommonEnclosureTempSensorEnclosureName . '.' . $temp_index};
        my $temp_location = $result2->{$oid_cpqRackCommonEnclosureTempLocation . '.' . $temp_index};
        my $temp_current = $result2->{$oid_cpqRackCommonEnclosureTempCurrent . '.' . $temp_index};
        my $temp_threshold = $result2->{$oid_cpqRackCommonEnclosureTempThreshold . '.' . $temp_index};
        my $temp_condition = $result2->{$oid_cpqRackCommonEnclosureTempCondition . '.' . $temp_index};
        my $temp_type = $result2->{$oid_cpqRackCommonEnclosureTempType . '.' . $temp_index};
        
		if ($temp_current == -1) {
			$self->{output}->output_add(long_msg => sprintf("Skipping instance $temp_index: current -1"));
			next;
		}
        
        next if ($self->check_exclude(section => 'temperature', instance => $temp_index));
		
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature %d status is %s [name: %s, location: %s] (value = %s, threshold = %s%s).",
                                    $temp_index, $map_conditions{$temp_condition},
                                    $temp_name, $temp_location,
                                    $temp_current, $temp_threshold,
                                    defined($map_temp_type{$temp_type}) ? ", status type = " . $map_temp_type{$temp_type} : ''));
        my $exit = $self->get_severity(section => 'temperature', value => $map_conditions{$temp_condition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature %d status is %s",
                                          $temp_index, $map_conditions{$temp_condition}));
        }
        
        $self->{output}->perfdata_add(label => "temp_" . $temp_index, unit => 'C',
                                      value => $temp_current,
                                      warning => $temp_threshold);
    }
}

1;
