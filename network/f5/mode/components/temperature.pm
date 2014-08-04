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

package network::f5::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    return if ($self->check_exclude('temperatures'));

    my $oid_sysChassisTempEntry = '.1.3.6.1.4.1.3375.2.1.3.2.3.2.1';
    my $oid_sysChassisTempTemperature = '.1.3.6.1.4.1.3375.2.1.3.2.3.2.1.2';
   
    my $result = $self->{snmp}->get_table(oid => $oid_sysChassisTempEntry);
    return if (scalar(keys %$result) <= 0); 

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_sysChassisTempTemperature\.(\d+)$/);
        my $instance = $1;
        next if ($self->check_exclude(section => 'temperatures', instance => $instance));
	
        my $exit_code = $self->{perfdata}->threshold_check(value => $result->{$oid_sysChassisTempTemperature . '.' . $instance},
                                                           threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    	$self->{components}->{temperatures}->{total}++;
    	$self->{output}->output_add(severity => $exit_code,long_msg => sprintf("temp_" . $instance . " is %.2f C", $result->{$oid_sysChassisTempTemperature . '.' . $instance}));
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,short_msg => sprintf("temp_" . $instance . " is %.2f C", $result->{$oid_sysChassisTempTemperature . '.' . $instance}));
        }

    	$self->{output}->perfdata_add(label => "temp_" . $instance , unit => 'C', 
                                      value => sprintf("%.2f", $result->{$oid_sysChassisTempTemperature . '.' . $instance}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    }
}

1;
