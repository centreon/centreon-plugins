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

package hardware::server::dell::idrac::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (
    1 => 'other', 
    2 => 'unknown', 
    3 => 'ok', 
    4 => 'nonCriticalUpper', 
    5 => 'criticalUpper', 
    6 => 'nonRecoverableUpper', 
    7 => 'nonCriticalLower', 
    8 => 'criticalLower', 
    9 => 'nonRecoverableLower', 
    10 => 'failed',
);
my %map_temp_state = (
    1 => 'unknown', 
    2 => 'enabled', 
    4 => 'notReady', 
    6 => 'enabledAndNotReady',
);
my %map_temp_type = (
    1 => 'temperatureProbeTypeIsOther', 
    2 => 'temperatureProbeTypeIsUnknown', 
    3 => 'temperatureProbeTypeIsAmbientESM', 
    16 => 'temperatureProbeTypeIsDiscrete',
);

my $mapping = {
    temperatureProbeStateSettings => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.4', map => \%map_temp_state },
    temperatureProbeStatus => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.5', map => \%map_temp_status },
    temperatureProbeReading => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.6' },
    temperatureProbeType => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.7', map => \%map_temp_type },
    temperatureProbeLocationName => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.8' },
    temperatureProbeUpperCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.10' },
    temperatureProbeUpperNonCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.10' },
    temperatureProbeLowerNonCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.11' },
    temperatureProbeLowerCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.12' },
};
my $oid_temperatureProbeTableEntry = '.1.3.6.1.4.1.674.10892.5.4.700.20.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_temperatureProbeTableEntry, begin => $mapping->{temperatureProbeStateSettings}->{oid}, end => $mapping->{temperatureProbeLowerCriticalThreshold}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureProbeTableEntry}})) {
        next if ($oid !~ /^$mapping->{temperatureProbeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureProbeTableEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{temperatureProbeReading} = (defined($result->{temperatureProbeReading})) ? $result->{temperatureProbeReading} / 10 : 'unknown';
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance = %s] [state = %s] [value = %s]",
                                    $result->{temperatureProbeLocationName}, $result->{temperatureProbeStatus}, $instance, 
                                    $result->{temperatureProbeStateSettings}, $result->{temperatureProbeReading}));
        
        my $exit = $self->get_severity(section => 'temperature-state', value => $result->{temperatureProbeStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' state is '%s'", $result->{temperatureProbeLocationName}, $result->{temperatureProbeStateSettings}));
            next;
        }

        $exit = $self->get_severity(section => 'temperature-status', value => $result->{temperatureProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{temperatureProbeLocationName}, $result->{temperatureProbeStatus}));
        }
     
        if (defined($result->{temperatureProbeReading}) && $result->{temperatureProbeReading} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureProbeReading});
            if ($checked == 0) {
                my $warn_th = $result->{temperatureProbeLowerNonCriticalThreshold} . ':' . $result->{temperatureProbeUpperCriticalThreshold};
                my $crit_th = $result->{temperatureProbeLowerCriticalThreshold} . ':' . $result->{temperatureProbeUpperCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result->{temperatureProbeReading}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                     { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $result->{temperatureProbeLocationName}, $result->{temperatureProbeReading}));
            }
            $self->{output}->perfdata_add(label => 'temp_' . $instance, unit => 'C', 
                                          value => $result->{temperatureProbeReading},
                                          warning => $warn,
                                          critical => $crit,
                                          );
        }
    }
}

1;