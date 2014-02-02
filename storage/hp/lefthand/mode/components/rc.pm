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

package storage::hp::lefthand::mode::components::rc;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{rc} = {name => 'raid controllers', total => 0};
    $self->{output}->output_add(long_msg => "Checking raid controllers");
    return if ($self->check_exclude('rc'));
    
    my $rc_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.4.3.0";
    my $rc_name_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.2';
    my $rc_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.90';
    my $rc_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.91';
    return if ($self->{global_information}->{$rc_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$rc_name_oid, $rc_state_oid,
                                 $rc_status_oid],
                        begin => 1, end => $self->{global_information}->{$rc_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_rc = $self->{global_information}->{$rc_count_oid};
    for (my $i = 1; $i <= $number_rc; $i++) {
        my $rc_name = $result->{$rc_name_oid . "." . $i};
        my $rc_state = $result->{$rc_state_oid . "." . $i};
        my $rc_status = $result->{$rc_status_oid . "." . $i};
        
        $self->{components}->{rc}->{total}++;
        
        if ($rc_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Raid Device (Controller) '" .  $rc_name . "' problem '" . $rc_state . "'");
        }
        $self->{output}->output_add(long_msg => "Raid Device (Controller) '" .  $rc_name . "' status = '" . $rc_status  . "', state = '" . $rc_state . "'");
    }
}

1;