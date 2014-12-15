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

package hardware::sensors::sensorip::snmp::mode::components::sp;

use strict;
use warnings;

my %map_sp_status = (
    1 => 'noStatus',
    2 => 'normal',
    3 => 'warning',
    4 => 'critical',
    5 => 'sensorError',
);
my $oid_spStatus = '.1.3.6.1.4.1.3854.1.1.2';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_spStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sp");
    $self->{components}->{sp} = {name => 'sp', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sp'));

    my $instance = 0;
    my $sp_status = defined($map_sp_status{$self->{results}->{$oid_spStatus}->{$oid_spStatus . '.' . $instance}}) ?
                            $map_sp_status{$self->{results}->{$oid_spStatus}->{$oid_spStatus . '.' . $instance}} : 'unknown';

    return if ($self->check_exclude(section => 'sp', instance => $instance));
    return if ($sp_status =~ /noStatus/i && 
             $self->absent_problem(section => 'sp', instance => $instance));
    
    $self->{components}->{sp}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("Sensor probe '%s' status is '%s'",
                                $instance, $sp_status));
    my $exit = $self->get_severity(section => 'sp', value => $sp_status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Sensor probe '%s' status is '%s'", $instance, $sp_status));
    }
}

1;