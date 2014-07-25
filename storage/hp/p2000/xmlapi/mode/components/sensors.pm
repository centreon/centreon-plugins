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

package storage::hp::p2000::xmlapi::mode::components::sensors;

use strict;
use warnings;

my @conditions = (
    ['^warning|not installed|unavailable$' => 'WARNING'],
    ['^error|unrecoverable$' => 'CRITICAL'],
    ['^unknown|unsupported$' => 'UNKNOWN'],
);

my %sensor_type = (
    # 2 it's other. Can be ok or '%'. Need to regexp
    3 => { unit => 'C' },
    6 => { unit => 'V' },
    9 => { unit => 'V' },
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensor'));
    
    # We don't use status-numeric. Values are buggy !!!???
    my $results = $self->{p2000}->get_infos(cmd => 'show sensor-status', 
                                            base_type => 'sensors',
                                            key => 'sensor-name', 
                                            properties_name => '^(value|sensor-type|status)$');

    foreach my $sensor_id (keys %$results) {
        next if ($self->check_exclude(section => 'sensor', instance => $sensor_id));
        $self->{components}->{sensor}->{total}++;
        
        my $state = $results->{$sensor_id}->{status};
        
        $results->{$sensor_id}->{value} =~ /\s*([0-9\.,]+)\s*(\S*)\s*/;
        my ($value, $unit) = ($1, $2);
        if (defined($sensor_type{$results->{$sensor_id}->{'sensor-type'}})) {
            $unit = $sensor_type{$results->{$sensor_id}->{'sensor-type'}}->{unit};
        }
        
        $self->{output}->output_add(long_msg => sprintf("sensor '%s' status is %s (value: %s %s).",
                                                        $sensor_id, $state, $value, $unit)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("sensor '%s' status is %s",
                                                        $sensor_id, $state));
                last;
            }
        }
        
        $self->{output}->perfdata_add(label => $sensor_id, unit => $unit,
                                      value => $value);
    }
}

1;