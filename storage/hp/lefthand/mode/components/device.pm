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

package storage::hp::lefthand::mode::components::device;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{device} = {name => 'devices', total => 0};
    $self->{output}->output_add(long_msg => "Checking devices");
    return if ($self->check_exclude('device'));
    
    my $device_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.4.1.0";
    my $device_name_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.14';
    my $device_serie_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.7';
    my $device_present_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.90';
    my $device_present_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.91';
    my $device_health_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.17'; # normal, marginal, faulty
    my $device_health_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.18';
    my $device_temperature_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.9';
    my $device_temperature_critical_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.10';
    my $device_temperature_limit_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.11';
    my $device_temperature_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.12';
    return if ($self->{global_information}->{$device_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$device_name_oid, $device_serie_oid,
                                 $device_present_state_oid, $device_present_status_oid,
                                 $device_health_state_oid, $device_health_status_oid,
                                 $device_temperature_oid, $device_temperature_critical_oid,
                                 $device_temperature_limit_oid, $device_temperature_status_oid],
                        begin => 1, end => $self->{global_information}->{$device_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_device = $self->{global_information}->{$device_count_oid};
    for (my $i = 1; $i <= $number_device; $i++) {
        my $device_name = $result->{$device_name_oid . "." . $i};
        my $device_serie = $result->{$device_serie_oid . "." . $i};
        my $device_present_state = $result->{$device_present_state_oid . "." . $i};
        my $device_present_status = $result->{$device_present_status_oid . "." . $i};
        my $device_health_state = $result->{$device_health_state_oid . "." . $i};
        my $device_health_status = $result->{$device_health_status_oid . "." . $i};
        my $device_temperature = $result->{$device_temperature_oid . "." . $i};
        my $device_temperature_critical = $result->{$device_temperature_critical_oid . "." . $i};
        my $device_temperature_limit = $result->{$device_temperature_limit_oid . "." . $i};
        my $device_temperature_status = $result->{$device_temperature_status_oid . "." . $i};
        
        $self->{components}->{device}->{total}++;
        
        $self->{output}->output_add(long_msg => "Storage Device '$device_name' and Serial Number '$device_serie', state = '$device_present_state'");
        # Check if present
        if ($device_present_state =~ /off_and_secured|off_or_removed/i) {
            next;
        }
        
        # Check global health
        if ($device_health_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Storage Device '" .  $device_name . "' Smart Health problem '" . $device_health_state . "'");
        }
        $self->{output}->output_add(long_msg => "    Smart Health status = '" . $device_health_status  . "', Smart Health state = '" . $device_health_state . "'");
        
        # Check temperature
        if ($device_temperature >= $device_temperature_critical) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Device Storage '" . $device_name . "' temperature too high");
        } elsif ($device_temperature >= $device_temperature_limit) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Device Storage '" . $device_name . "' over the limit");
        }
        $self->{output}->output_add(long_msg => "    Temperature value = '" . $device_temperature  . "' (limit >= $device_temperature_limit, critical >= $device_temperature_critical)");
        $self->{output}->perfdata_add(label => $device_name . "_temp",
                                      value => $device_temperature,
                                      warning => $device_temperature_limit, critical => $device_temperature_critical);
    }
}

1;