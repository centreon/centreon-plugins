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

package hardware::sensors::jacarta::snmp::mode::components::humidity;

use strict;
use warnings;
use hardware::sensors::jacarta::snmp::mode::components::resources qw(%map_default_status %map_state);

my $mapping = {
    isDeviceMonitorHumidityName  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.2' },
    isDeviceMonitorHumidity      => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.3' },
    isDeviceMonitorHumidityAlarm => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.4', map => \%map_default_status },
};
my $mapping2 = {
    isDeviceConfigHumidityLowWarning     => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.3' },
    isDeviceConfigHumidityLowCritical    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.4' },
    isDeviceConfigHumidityHighWarning    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.5' },
    isDeviceConfigHumidityHighCritical   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.6' },
    isDeviceConfigHumidityLowWarningState    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.9', map => \%map_state },
    isDeviceConfigHumidityLowCriticalState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.10', map => \%map_state },
    isDeviceConfigHumidityHighWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.11', map => \%map_state },
    isDeviceConfigHumidityHighCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.12', map => \%map_state },
};
my $oid_isDeviceMonitorHumidityEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1';
my $oid_isDeviceConfigHumidityEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_isDeviceMonitorHumidityEntry }, { oid => $oid_isDeviceConfigHumidityEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidities");
    $self->{components}->{humidity} = {name => 'humidities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_isDeviceMonitorHumidityEntry}})) {
        next if ($oid !~ /^$mapping->{isDeviceMonitorHumidityAlarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_isDeviceMonitorHumidityEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_isDeviceConfigHumidityEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;
        
        $result->{isDeviceMonitorHumidity} *= 0.01;
        $self->{output}->output_add(long_msg => sprintf("humidity '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{isDeviceMonitorHumidityName}, $result->{isDeviceMonitorHumidityAlarm}, $instance, 
                                    $result->{isDeviceMonitorHumidity}));
        
        my $exit = $self->get_severity(label => 'default', section => 'humidity', value => $result->{isDeviceMonitorHumidityAlarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Humdity '%s' status is '%s'", $result->{isDeviceMonitorHumidityName}, $result->{isDeviceMonitorHumidityAlarm}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{isDeviceMonitorHumidity});
        if ($checked == 0) {
            $result2->{isDeviceConfigHumidityLowWarning} = ($result2->{isDeviceConfigHumidityLowWarningState} eq 'enabled') ?
                $result2->{isDeviceConfigHumidityLowWarning} * 0.01 : '';
            $result2->{isDeviceConfigHumidityLowCritical} = ($result2->{isDeviceConfigHumidityLowCriticalState} eq 'enabled') ?
                $result2->{isDeviceConfigHumidityLowCritical} * 0.01 : '';
            $result2->{isDeviceConfigHumidityHighWarning} = ($result2->{isDeviceConfigHumidityHighWarningState} eq 'enabled') ?
                $result2->{isDeviceConfigHumidityHighWarning} * 0.01 : '';
            $result2->{isDeviceConfigHumidityHighCritical} = ($result2->{isDeviceConfigHumidityHighCriticalState} eq 'enabled') ?
                $result2->{isDeviceConfigHumidityHighCritical} * 0.01 : '';
            my $warn_th = $result2->{isDeviceConfigHumidityLowWarning} . ':' . $result2->{isDeviceConfigHumidityHighWarning};
            my $crit_th = $result2->{isDeviceConfigHumidityLowCritical} . ':' . $result2->{isDeviceConfigHumidityHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Humdity '%s' is %s %%", $result->{isDeviceMonitorHumidityName}, $result->{isDeviceMonitorHumidity}));
        }
        $self->{output}->perfdata_add(
            label => 'humidity', unit => '%',
            nlabel => 'hardware.humidity.percentage',
            instances => $result->{isDeviceMonitorHumidityName},
            value => $result->{isDeviceMonitorHumidity},
            warning => $warn,
            critical => $crit,
            min => 0, max => 100
        );
    }
}

1;
