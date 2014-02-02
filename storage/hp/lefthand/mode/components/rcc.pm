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

package storage::hp::lefthand::mode::components::rcc;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{rcc} = {name => 'raid controller caches', total => 0};
    $self->{output}->output_add(long_msg => "Checking raid controller cache");
    return if ($self->check_exclude('rcc'));
    
    my $rcc_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.90.0";
    my $rcc_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.2"; # begin .1
    my $rcc_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.90";
    my $rcc_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.91";
    my $bbu_enabled_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.50"; # 1 mean 'enabled'
    my $bbu_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.22';
    my $bbu_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.23"; # 1 mean 'ok'
    return if ($self->{global_information}->{$rcc_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$rcc_name_oid, $rcc_state_oid,
                                 $rcc_status_oid, $bbu_enabled_oid, $bbu_state_oid, $bbu_status_oid],
                        begin => 1, end => $self->{global_information}->{$rcc_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_raid = $self->{global_information}->{$rcc_count_oid};
    for (my $i = 1; $i <= $number_raid; $i++) {
        my $raid_name = $result->{$rcc_name_oid . "." . $i};
        my $raid_state = $result->{$rcc_state_oid . "." . $i};
        my $raid_status = $result->{$rcc_status_oid . "." . $i};
        my $bbu_enabled = $result->{$bbu_enabled_oid . "." . $i};
        my $bbu_state = $result->{$bbu_state_oid . "." . $i};
        my $bbu_status = $result->{$bbu_status_oid . "." . $i};
        
       $self->{components}->{rcc}->{total}++;
        
        if ($raid_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Raid Controller Caches '" .  $raid_name . "' problem '" . $raid_state . "'");
        }
        $self->{output}->output_add(long_msg => "Raid Controller Caches '" .  $raid_name . "' status = '" . $raid_status  . "', state = '" . $raid_state . "'");
        if ($bbu_enabled == 1) {
            if ($bbu_status != 1) {
                 $self->{output}->output_add(severity => 'CRITICAL', 
                                             short_msg => "BBU '" .  $raid_name . "' problem '" . $bbu_state . "'");
            }
            $self->{output}->output_add(long_msg => "   BBU status = '" . $bbu_status  . "', state = '" . $bbu_state . "'");
        } else {
            $self->{output}->output_add(long_msg => "   BBU disabled");
        }
    }
}

1;