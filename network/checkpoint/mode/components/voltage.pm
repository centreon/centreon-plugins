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

package network::checkpoint::mode::components::voltage;

use strict;
use warnings;
 
my %map_states_voltage = (
    0 => 'false',
    1 => 'true',
    2 => 'reading error',
);

my $mapping = {
    voltageSensorName => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.2' },
    voltageSensorValue => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.3' },
    voltageSensorStatus => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.6', map => \%map_states_voltage },
};
my $oid_voltageSensorEntry = '.1.3.6.1.4.1.2620.1.6.7.8.3.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_voltageSensorEntry, start => $mapping->{voltageSensorName}->{oid}, end => $mapping->{voltageSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_voltageSensorEntry}})) {
        next if ($oid !~ /^$mapping->{voltageSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_voltageSensorEntry}, instance => $instance);
    
        next if ($self->check_exclude(section => 'voltage', instance => $instance));
        next if ($result->{voltageSensorName} !~ /^[0-9a-zA-Z ]+$/); # sometimes there is some wrong values in hex 
     
        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' sensor out of range status is '%s' [instance: %s]",
                                        $result->{voltageSensorName}, $result->{voltageSensorStatus}, $instance));
        my $exit = $self->get_severity(section => 'voltage', value => $result->{voltageSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s/%s' sensor out of range status is '%s'", $result->{voltageSensorName}, $instance, $result->{voltageSensorStatus}));
        }
        
        if (defined($result->{voltageSensorValue}) && $result->{voltageSensorValue} =~ /^[0-9\.]+$/) {
            $self->{output}->perfdata_add(label => 'volt_' . $result->{voltageSensorName} . '_' . $instance, unit => 'V', 
                                          value => sprintf("%.2f", $result->{voltageSensorValue}));
        }
    }
}

1;
