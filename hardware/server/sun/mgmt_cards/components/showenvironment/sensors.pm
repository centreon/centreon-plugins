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

package hardware::server::sun::mgmt_cards::components::showenvironment::sensors;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensors} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensors'));
    
    if ($self->{stdout} =~ /^Current sensors.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Sensor          Status
        #----------------------
        #MB.FF_SCSI       OK

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)(\s{2}|$)/);
            my $sensor_status = defined($2) ? $2 : 'unknown';
            my $sensor_name = defined($1) ? $1 : 'unknown';
            
            next if ($self->check_exclude(section => 'sensors', instance => $sensor_name));
            
            $self->{components}->{sensors}->{total}++;
            $self->{output}->output_add(long_msg => "Current Sensor status '" . $sensor_name . "' is " . $sensor_status);
            my $exit = $self->get_severity(section => 'sensors', value => $sensor_status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => "Current Sensor status '" . $sensor_name . "' is " . $sensor_status);
            }
        }
    }
}

1;