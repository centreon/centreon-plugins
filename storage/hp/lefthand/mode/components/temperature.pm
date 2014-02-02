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

package storage::hp::lefthand::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{temperature} = {name => 'temperature sensors', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperature sensors");
    return if ($self->check_exclude('temperature'));
    
    my $temperature_sensor_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.120.0";
    my $temperature_sensor_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.2";
    my $temperature_sensor_value_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.3";
    my $temperature_sensor_critical_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.4";
    my $temperature_sensor_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.5"; # warning. lower than critical
    my $temperature_sensor_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.90";
    my $temperature_sensor_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.91";
    return if ($self->{global_information}->{$temperature_sensor_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$temperature_sensor_name_oid, $temperature_sensor_value_oid,
                                 $temperature_sensor_critical_oid, $temperature_sensor_limit_oid, $temperature_sensor_state_oid, $temperature_sensor_status_oid],
                        begin => 1, end => $self->{global_information}->{$temperature_sensor_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_temperature = $self->{global_information}->{$temperature_sensor_count_oid};
    for (my $i = 1; $i <= $number_temperature; $i++) {
        my $ts_name = $result->{$temperature_sensor_name_oid . "." . $i};
        my $ts_value = $result->{$temperature_sensor_value_oid . "." . $i};
        my $ts_critical = $result->{$temperature_sensor_critical_oid . "." . $i};
        my $ts_limit = $result->{$temperature_sensor_limit_oid . "." . $i};
        my $ts_state = $result->{$temperature_sensor_state_oid . "." . $i};
        my $ts_status = $result->{$temperature_sensor_status_oid . "." . $i};
        
        $self->{components}->{temperature}->{total}++;
        
        if ($ts_value >= $ts_critical) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' too high");
        } elsif ($ts_value >= $ts_limit) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' over the limit");
        }
        $self->{output}->output_add(long_msg => "Temperature sensor '" .  $ts_name . "' value = '" . $ts_value  . "' (limit >= $ts_limit, critical >= $ts_critical)");
        $self->{output}->perfdata_add(label => $ts_name . "_temp",
                                      value => $ts_value,
                                      warning => $ts_limit, critical => $ts_critical);
 
        if ($ts_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' problem '" . $ts_state . "'");
        }
        $self->{output}->output_add(long_msg => "Temperature sensor '" .  $ts_name . "' status = '" . $ts_status  . "', state = '" . $ts_state . "'");
    }
}

1;