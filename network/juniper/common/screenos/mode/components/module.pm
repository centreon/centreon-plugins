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
# Authors : Stephane Duret <sduret@merethis.com>
#
####################################################################################

package network::juniper::common::screenos::mode::components::module;

use strict;
use warnings;

my %map_status = (
    1 => 'active',
    2 => 'inactive'
);

sub check {
    my ($self) = @_;

    $self->{components}->{modules} = {name => 'modules', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking modules");
    return if ($self->check_exclude(section => 'modules'));
    
    my $oid_nsSlotEntry = '.1.3.6.1.4.1.3224.21.5.1';
    my $oid_nsSlotType = '.1.3.6.1.4.1.3224.21.5.1.2';
    my $oid_nsSlotStatus = '.1.3.6.1.4.1.3224.21.5.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_nsSlotEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_nsSlotStatus\.(\d+)$/);
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'modules', instance => $instance));
        $self->{components}->{modules}->{total}++;
    
        my $type = $result->{$oid_nsSlotType . '.' . $instance};
        my $status = $result->{$oid_nsSlotStatus . '.' . $instance};
        
        $self->{output}->output_add(long_msg => sprintf("Module '%s' status is %s [instance: %s].", 
                                    $type, $map_status{$status}, $instance));
        if ($status != 1) {
            $self->{output}->output_add(severity =>  'CRITICAL',
                                        short_msg => sprintf("Module '%s' status is %s", 
                                                             $type, $map_status{$status}));
        }
    }
}

1;
