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

package storage::emc::DataDomain::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

my %conditions = (
    0 => ['absent', 'CRITICAL'], 
    1 => ['ok', 'OK'], 
    2 => ['not found', 'UNKNOWN'], 
);

sub check {
    my ($self) = @_;

    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperatures");
    return if ($self->check_exclude('temperatures'));
    
    my $oid_temperatureSensorEntry = '.1.3.6.1.4.1.19746.1.1.2.1.1.1';
    my $oid_tempSensorDescription = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.3';
    my $oid_tempSensorCurrentValue = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.4';
    my $oid_tempSensorStatus = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_temperatureSensorEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_tempSensorCurrentValue\.(\d+)\.(\d+)$/);
        my ($enclosure_id, $sensor_index) = ($1, $2);
    
        my $temp_descr = centreon::plugins::misc::trim($result->{$oid_tempSensorDescription . '.' . $enclosure_id . '.' . $sensor_index});
        my $temp_value = $result->{$oid_tempSensorCurrentValue . '.' . $enclosure_id . '.' . $sensor_index};
        my $temp_status = $result->{$oid_tempSensorStatus . '.' . $enclosure_id . '.' . $sensor_index};

        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is %s [enclosure = %d, sensor = %d, current_value = %s].", 
                                    $temp_descr, ${$conditions{$temp_status}}[0], $enclosure_id, $sensor_index, $temp_value));
        if (!$self->{output}->is_status(litteral => 1, value => ${$conditions{$temp_status}}[1], compare => 'ok')) {
            $self->{output}->output_add(severity => ${$conditions{$temp_status}}[1],
                                        short_msg => sprintf("Temperature '%s' status is %s", $temp_descr, ${$conditions{$temp_status}}[0]));
        }
        
        $self->{output}->perfdata_add(label => 'temp_' . $enclosure_id . '_' . $sensor_index, unit => 'C',
                                      value => $temp_value,
                                      );
    }
}

1;