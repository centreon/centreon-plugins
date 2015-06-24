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

package centreon::common::cisco::standard::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temperature_state = (
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical', 
    4 => 'shutdown',
    5 => 'not present',
    6 => 'not functioning',
);

# In MIB 'CISCO-ENVMON-MIB'
my $mapping = {
    ciscoEnvMonTemperatureStatusDescr => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.2' },
    ciscoEnvMonTemperatureStatusValue => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.3' },
    ciscoEnvMonTemperatureThreshold => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.4' },
    ciscoEnvMonTemperatureState => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.6', map => \%map_temperature_state },
};
my $oid_ciscoEnvMonTemperatureStatusEntry = '.1.3.6.1.4.1.9.9.13.1.3.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_ciscoEnvMonTemperatureStatusEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ciscoEnvMonTemperatureStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ciscoEnvMonTemperatureState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ciscoEnvMonTemperatureStatusEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is %s [instance: %s] [value: %s C]", 
                                    $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureState},
                                    $instance, $result->{ciscoEnvMonTemperatureStatusValue}));
        my $exit = $self->get_severity(section => 'temperature', value => $result->{ciscoEnvMonTemperatureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s", 
                                                             $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureState}));
        }
     
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{ciscoEnvMonTemperatureStatusValue});
        if ($checked == 0) {
            my $warn_th = undef;
            my $crit_th = '~:' . $result->{ciscoEnvMonTemperatureThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s degree centigrade", $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureStatusValue}));
        }
        $self->{output}->perfdata_add(label => "temp_" . $result->{ciscoEnvMonTemperatureStatusDescr}, unit => 'C',
                                      value => $result->{ciscoEnvMonTemperatureStatusValue},
                                      warning => $warn,
                                      critical => $crit);
    }
}

1;