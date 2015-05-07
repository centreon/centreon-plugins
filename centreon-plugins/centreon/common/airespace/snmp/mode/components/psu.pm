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

package centreon::common::airespace::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    0 => 'not operational', 
    1 => 'operational', 
);

# In MIB 'AIRESPACE-SWITCHING-MIB'
my $oid_agentSwitchInfoGroup = '.1.3.6.1.4.1.14179.1.1.3';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_agentSwitchInfoGroup };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
 
    foreach my $instances ([1, 3], [2, 5]) {
        next if (!defined($self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . $$instances[1] . '.0' }));
        my $present = $self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . ($$instances[1] - 1) . '.0' };
        my $operational = $map_psu_status{ $self->{results}->{$oid_agentSwitchInfoGroup}->{ $oid_agentSwitchInfoGroup . '.' . $$instances[1] . '.0' } };

        next if ($self->check_exclude(section => 'psu', instance => $$instances[0]));
        next if ($present =~ /0/i && 
                 $self->absent_problem(section => 'psu', instance => $$instances[0]));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s.",
                                                        $$instances[1], $operational));
        my $exit = $self->get_severity(section => 'psu', value => $operational);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s.",
                                                             $$instances[1], $operational));
        }
    }
}

1;