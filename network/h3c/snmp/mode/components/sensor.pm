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

package network::h3c::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_sensor_status = (
    1 => 'notSupported',
    2 => 'normal',
    4 => 'entityAbsent',
    81 => 'sensorError',
    91 => 'hardwareFaulty',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensor'));

    my $mapping = {
        EntityExtErrorStatus => { oid => $self->{branch} . '.19', map => \%map_sensor_status }, 
    };
    my $mapping2 = {
        EntityExtTemperature => { oid => $self->{branch} . '.12' },
        EntityExtTemperatureThreshold => { oid => $self->{branch} . '.13' },
    };

    my @instances = $self->get_instance_class(class => { 8 => 1 });
    return if (scalar(@instances) == 0);
    
    $self->{snmp}->load(oids => [$mapping2->{EntityExtTemperature}->{oid}, $mapping2->{EntityExtTemperatureThreshold}->{oid}],
                        instances => [@instances]);
    my $results = $self->{snmp}->get_leef();
    
    my ($exit, $warn, $crit, $checked);
    foreach my $instance (sort @instances) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$self->{branch} . '.19'}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $results, instance => $instance);
        
        next if ($self->check_exclude(section => 'sensor', instance => $instance));
        if ($result->{EntityExtErrorStatus} =~ /entityAbsent/i) {
            $self->absent_problem(section => 'sensor', instance => $instance);
            next;
        }
        
        next if (!(defined($result2->{EntityExtTemperatureThreshold}) && 
                 $result2->{EntityExtTemperatureThreshold} > 0 && $result2->{EntityExtTemperatureThreshold} < 65535)); 
        
        my $name = $self->get_long_name(instance => $instance);
        $self->{components}->{sensor}->{total}++;
        
        if (defined($result2->{EntityExtTemperatureThreshold}) && 
            $result2->{EntityExtTemperatureThreshold} > 0 && $result2->{EntityExtTemperatureThreshold} < 65535) {
            $self->{output}->output_add(long_msg => sprintf("Sensor '%s' status is '%s' [instance = %s]",
                                                            $name, $result->{EntityExtErrorStatus}, $instance));
            $exit = $self->get_severity(section => 'sensor', value => $result->{EntityExtErrorStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sensor '%s' status is '%s'", $name, $result->{EntityExtErrorStatus}));
            }
            
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result2->{EntityExtTemperature});
            if ($checked == 0) {
                my $crit_th = '~:' . $result2->{EntityExtTemperatureThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => undef);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result2->{EntityExtTemperature}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                    { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature sensor '%s' is %s degree centigrade", $name, $result2->{EntityExtTemperature}));
            }
            $self->{output}->perfdata_add(label => 'temp_' . $instance, unit => 'C', 
                                          value => $result2->{EntityExtTemperature},
                                          warning => $warn,
                                          critical => $crit,
                                          );
        }
    }
}

1;