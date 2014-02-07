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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{fans} = {name => 'fans', total => 0};
    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude('fans'));
    
    my $oid_fanEntry = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1';
    my $oid_fanDescr = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1.2';
    my $oid_fanSpeed = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_fanEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_fanDescr\.(\d+)$/;
        my $instance = $1;
    
        my $fan_descr = centreon::plugins::misc($result->{$oid_fanDescr . '.' . $instance});
        my $fan_speed = centreon::plugins::misc($result->{$oid_fanSpeed . '.' . $instance});

        $self->{components}->{fans}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' speed is %s.", 
                                    $fan_descr, $fan_speed));
        if ($fan_speed =~ /offline/i) {
            $self->{output}->output_add(severity =>  'WARNING',
                                        short_msg => sprintf("Fan '%s' is offline", $fan_descr));
        } else {
            $fan_speed =~ /(\d+)/;
            $self->{output}->perfdata_add(label => 'fan_' . $fan_descr, unit => '%',
                                          value => $1,
                                          min => 0, max => 100);
        }
    }
}

1;