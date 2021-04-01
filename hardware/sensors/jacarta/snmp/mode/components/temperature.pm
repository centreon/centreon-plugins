#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package hardware::sensors::jacarta::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::jacarta::snmp::mode::components::resources qw(%map_default_status %map_state);

my $mapping = {
    isDeviceMonitorTemperatureName  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.2' },
    isDeviceMonitorTemperature      => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.3' },
    isDeviceMonitorTemperatureAlarm => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.4', map => \%map_default_status },
};
my $mapping2 = {
    isDeviceConfigTemperatureLowWarning     => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.3' },
    isDeviceConfigTemperatureLowCritical    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.4' },
    isDeviceConfigTemperatureHighWarning    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.5' },
    isDeviceConfigTemperatureHighCritical   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.6' },
    isDeviceConfigTemperatureLowWarningState    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.9', map => \%map_state },
    isDeviceConfigTemperatureLowCriticalState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.10', map => \%map_state },
    isDeviceConfigTemperatureHighWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.11', map => \%map_state },
    isDeviceConfigTemperatureHighCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.12', map => \%map_state },
};

my $oid_isDeviceMonitorTemperatureEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1';
my $oid_isDeviceConfigTemperatureEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_isDeviceMonitorTemperatureEntry }, { oid => $oid_isDeviceConfigTemperatureEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_isDeviceMonitorTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{isDeviceMonitorTemperatureAlarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_isDeviceMonitorTemperatureEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_isDeviceConfigTemperatureEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;
        
        $result->{isDeviceMonitorTemperature} *= 0.01;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{isDeviceMonitorTemperatureName}, $result->{isDeviceMonitorTemperatureAlarm}, $instance, 
                                    $result->{isDeviceMonitorTemperature}));
        
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{isDeviceMonitorTemperatureAlarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{isDeviceMonitorTemperatureName}, $result->{isDeviceMonitorTemperatureAlarm}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{isDeviceMonitorTemperature});
        if ($checked == 0) {
            $result2->{isDeviceConfigTemperatureLowWarning} = ($result2->{isDeviceConfigTemperatureLowWarningState} eq 'enabled') ?
                $result2->{isDeviceConfigTemperatureLowWarning} * 0.01 : '';
            $result2->{isDeviceConfigTemperatureLowCritical} = ($result2->{isDeviceConfigTemperatureLowCriticalState} eq 'enabled') ?
                $result2->{isDeviceConfigTemperatureLowCritical} * 0.01 : '';
            $result2->{isDeviceConfigTemperatureHighWarning} = ($result2->{isDeviceConfigTemperatureHighWarningState} eq 'enabled') ?
                $result2->{isDeviceConfigTemperatureHighWarning} * 0.01 : '';
            $result2->{isDeviceConfigTemperatureHighCritical} = ($result2->{isDeviceConfigTemperatureHighCriticalState} eq 'enabled') ?
                $result2->{isDeviceConfigTemperatureHighCritical} * 0.01 : '';
            my $warn_th = $result2->{isDeviceConfigTemperatureLowWarning} . ':' . $result2->{isDeviceConfigTemperatureHighWarning};
            my $crit_th = $result2->{isDeviceConfigTemperatureLowCritical} . ':' . $result2->{isDeviceConfigTemperatureHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s %s", $result->{isDeviceMonitorTemperatureName}, $result->{isDeviceMonitorTemperature}, $self->{temperature_unit}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => $self->{temperature_unit},
            nlabel => 'hardware.temperature.' . (($self->{temperature_unit} eq 'C') ? 'celsius' : 'fahrenheit'),
            instances => $result->{isDeviceMonitorTemperatureName},
            value => $result->{isDeviceMonitorTemperature},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
