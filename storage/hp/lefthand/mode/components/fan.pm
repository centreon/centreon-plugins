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

package storage::hp::lefthand::mode::components::fan;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{fan} = {name => 'fans', total => 0};
    $self->{output}->output_add(long_msg => "Checking fan");
    return if ($self->check_exclude('fan'));
    
    my $fan_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.110.0"; # 0 means 'none'
    my $fan_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.2"; # begin .1
    my $fan_speed_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.3"; # dont have
    my $fan_min_speed_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.4"; # dont have
    my $fan_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.90"; # string explained
    my $fan_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.91";
    return if ($self->{global_information}->{$fan_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$fan_name_oid, $fan_name_oid,
                                 $fan_min_speed_oid, $fan_state_oid, $fan_status_oid],
                        begin => 1, end => $self->{global_information}->{$fan_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_fans = $self->{global_information}->{$fan_count_oid};
    for (my $i = 1; $i <= $number_fans; $i++) {
        my $fan_name = $result->{$fan_name_oid . "." . $i};
        my $fan_speed = $result->{$fan_speed_oid . "." . $i};
        my $fan_min_speed = $result->{$fan_min_speed_oid . "." . $i};
        my $fan_status = $result->{$fan_status_oid . "." . $i};
        my $fan_state = $result->{$fan_state_oid . "." . $i};
    
        $self->{components}->{fan}->{total}++;
    
        # Check Fan Speed
        if (defined($fan_speed)) {
            my $low_limit = '';
            if (defined($fan_min_speed)) {
                $low_limit = '@:' . $fan_min_speed;
                if ($fan_speed <= $fan_min_speed) {
                    $self->{output}->output_add(severity => 'CRITICAL', 
                                                short_msg => "Fan '" .  $fan_name . "' speed too low");
                }
            }
            $self->{output}->output_add(long_msg => "Fan '" .  $fan_name . "' speed = '" . $fan_speed  . "' (<= $fan_min_speed)");
            $self->{output}->perfdata_add(label => $fan_name, unit => 'rpm',
                                          value => $fan_speed,
                                          critical => $low_limit);            
        }
        
        if ($fan_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Fan '" .  $fan_name . "' problem '" . $fan_state . "'");
        }
        $self->{output}->output_add(long_msg => "Fan '" .  $fan_name . "' status = '" . $fan_status  . "', state = '" . $fan_state . "'");
    }
}

1;