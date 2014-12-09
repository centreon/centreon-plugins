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

package storage::emc::DataDomain::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_temp_status = ();
my ($oid_tempSensorDescription, $oid_tempSensorCurrentValue, $oid_tempSensorStatus);
my $oid_temperatureSensorEntry = '.1.3.6.1.4.1.19746.1.1.2.1.1.1';

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_tempSensorDescription = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.4';
        $oid_tempSensorCurrentValue = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.5';
        $oid_tempSensorStatus = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.6';
        %map_temp_status = (0 => 'failed', 1 => 'ok', 2 => 'notfound', 3 => 'overheatWarning',
                            4 => 'overheatCritical');
    } else {
        $oid_tempSensorDescription = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.3';
        $oid_tempSensorCurrentValue = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.4';
        $oid_tempSensorStatus = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.5';
        %map_temp_status = (0 => 'absent', 1 => 'ok', 2 => 'notfound');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_temperatureSensorEntry}}) {
        next if ($oid !~ /^$oid_tempSensorStatus\.(.*)$/);
        my $instance = $1;
        my $temp_descr = defined($self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorDescription . '.' . $instance}) ? 
                            centreon::plugins::misc::trim($self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorDescription . '.' . $instance}) : 'unknown';
        my $temp_status = defined($map_temp_status{$self->{results}->{$oid_temperatureSensorEntry}->{$oid}}) ?
                            $map_temp_status{$self->{results}->{$oid_temperatureSensorEntry}->{$oid}} : 'unknown';
        my $temp_value = $self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorCurrentValue . '.' . $instance};

        next if ($self->check_exclude(section => 'temperature', instance => $instance));
        next if ($temp_status =~ /absent|notfound/i && 
                 $self->absent_problem(section => 'temperature', instance => $instance));
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance = %s]",
                                    $temp_descr, $temp_status, $instance));
        my $exit = $self->get_severity(section => 'temperature', value => $temp_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $temp_descr, $temp_status));
        }

        if (defined($temp_value) && $temp_value =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temp_value);
            $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %s degree centigrade", $temp_descr, $temp_value));
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $temp_descr, $temp_value));
            }
            $self->{output}->perfdata_add(label => 'temp_' . $instance, unit => 'C', 
                                          value => $temp_value,
                                          warning => $warn,
                                          critical => $crit,
                                          );
        }
    }
}

1;