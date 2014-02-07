################################################################################
# Copyright 2005-2014 MERETHIS
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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    0 => ['non recoverable', 'CRITICAL'], 
    2 => ['critical', 'CRITICAL'], 
    4 => ['non critical', 'WARNING'], 
    255 => ['nominal', 'OK'],
);

sub check {
    my ($self) = @_;

    my $oid_systemHealthStat = '.1.3.6.1.4.1.2.3.51.3.1.4.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_systemHealthStat], nothing_quit => 1);
    
    $self->{components}->{global} = {name => 'system health', total => 1};
    $self->{output}->output_add(long_msg => sprintf("System health status is '%s'.", 
                                                    ${$states{$result->{$oid_systemHealthStat}}}[0]));
    if (${$states{$result->{$oid_systemHealthStat}}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$result->{$oid_systemHealthStat}}}[1],
                                    short_msg => sprintf("System health status is '%s'.", 
                                                         ${$states{$result->{$oid_systemHealthStat}}}[0]));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;