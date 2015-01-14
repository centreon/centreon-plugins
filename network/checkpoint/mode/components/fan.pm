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

package network::checkpoint::mode::components::fan;

use strict;
use warnings;

my %map_states_fan = (
    0 => 'false',
    1 => 'true',
    2 => 'reading error',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    my $oid_fanSpeedSensorEntry = '.1.3.6.1.4.1.2620.1.6.7.8.2.1';
    my $oid_fanSpeedSensorStatus = '.1.3.6.1.4.1.2620.1.6.7.8.2.1.6';
    my $oid_fanSpeedSensorValue = '.1.3.6.1.4.1.2620.1.6.7.8.2.1.3';
    my $oid_fanSpeedSensorName = '.1.3.6.1.4.1.2620.1.6.7.8.2.1.2';
    
    my $result = $self->{snmp}->get_table(oid => $oid_fanSpeedSensorEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_fanSpeedSensorStatus\.(\d+).(\d+)$/);
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'fan', instance => $instance));
          
        my $fan_name = $result->{$oid_fanSpeedSensorName . '.' . $instance};
        my $fan_state = $result->{$oid_fanSpeedSensorStatus . '.' . $instance};

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' sensor out of range status is '%s'",
                                    $fan_name, $map_states_fan{$fan_state}));
        my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' sensor out of range status is '%s'", $fan_name, $map_states_fan{$fan_state}));
        }

        $self->{output}->perfdata_add(label => $fan_name , unit => 'rpm',
                                      value => sprintf("%d", $result->{$oid_fanSpeedSensorValue . '.' . $instance}));
    }
}

1;
