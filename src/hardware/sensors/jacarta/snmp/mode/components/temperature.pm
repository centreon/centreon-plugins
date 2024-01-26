#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

sub load {}

sub check_inSeptPro {
    my ($self) = @_;

    my $mapping = {
        name    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.2' }, # isDeviceMonitorTemperatureName
        current => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.3' }, # isDeviceMonitorTemperature
        alarm   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1.4', map => \%map_default_status } # isDeviceMonitorTemperatureAlarm
    };
    my $mapping_config = {
        lowWarning    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.3' }, # isDeviceConfigTemperatureLowWarning
        lowCritical    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.4' }, # isDeviceConfigTemperatureLowCritical
        highWarning    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.5' }, # isDeviceConfigTemperatureHighWarning
        highCritical   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.6' }, # isDeviceConfigTemperatureHighCritical
        lowWarningState    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.9', map => \%map_state }, # isDeviceConfigTemperatureLowWarningState
        lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.10', map => \%map_state }, # isDeviceConfigTemperatureLowCriticalState
        highWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.11', map => \%map_state }, # isDeviceConfigTemperatureHighWarningState
        highCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1.12', map => \%map_state } # isDeviceConfigTemperatureHighCriticalState
    };

    my $oid_tempEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.1.1.1'; # isDeviceMonitorTemperatureEntry
    my $oid_configTempEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.2.2.1'; # isDeviceConfigTemperatureEntry

    my $snmp_result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_tempEntry, end => $mapping->{alarm}->{oid} } ,
            { oid => $oid_configTempEntry, start => $mapping_config->{lowWarning}->{oid}, end => $mapping_config->{lowWarning}->{highCriticalState} }
        ]
    );

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$snmp_result->{$oid_tempEntry}})) {
        next if ($oid !~ /^$mapping->{alarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_tempEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping_config, results => $snmp_result->{$oid_configTempEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{current} *= 0.01;
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance: %s] [value: %s]",
                $result->{name}, $result->{alarm}, $instance, 
                $result->{current}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{alarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Temperature '%s' status is '%s'", $result->{name}, $result->{alarm})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{current});
        if ($checked == 0) {
            $result2->{lowWarning} = ($result2->{lowWarningState} eq 'enabled') ? $result2->{lowWarning} * 0.01 : '';
            $result2->{lowCritical} = ($result2->{lowCriticalState} eq 'enabled') ? $result2->{lowCritical} * 0.01 : '';
            $result2->{highWarning} = ($result2->{highWarningState} eq 'enabled') ? $result2->{highWarning} * 0.01 : '';
            $result2->{highCritical} = ($result2->{highCriticalState} eq 'enabled') ? $result2->{highCritical} * 0.01 : '';
            my $warn_th = $result2->{lowWarning} . ':' . $result2->{highWarning};
            my $crit_th = $result2->{lowCritical} . ':' . $result2->{highCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Temperature '%s' is %s %s", $result->{name}, $result->{current}, $self->{temperature_unit})
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.' . (($self->{temperature_unit} eq 'C') ? 'celsius' : 'fahrenheit'),
            unit => $self->{temperature_unit},
            instances => $result->{name},
            value => $result->{current},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check_inSept {
    my ($self) = @_;

    my $devices = $self->getInSeptDevices();

    my $mapping = {
        current => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.3.2.1.3' }, # inSeptsensorMonitorDeviceTemperature
        alarm   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.3.2.1.4', map => \%map_default_status } # inSeptsensorMonitorDeviceTemperatureAlarm
    };
    my $mapping_config = {
        1 => {
            name              => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.1' }, # inSeptsensorConfigSensor1TemperatureName
            lowWarning        => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.2' }, # inSeptsensorConfigSensor1TemperatureLowWarning
            lowCritical       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.3' }, # inSeptsensorConfigSensor1TemperatureLowCritical
            highWarning       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.4' }, # inSeptsensorConfigSensor1TemperatureHighWarning
            highCritical      => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.5' }, # inSeptsensorConfigSensor1TemperatureHighCritical
            lowWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.8', map => \%map_state },  # inSeptsensorConfigSensor1TemperatureLowWarningStatus
            lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.9', map => \%map_state },  # inSeptsensorConfigSensor1TemperatureLowCriticalStatus
            highWarningState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.10', map => \%map_state }, # inSeptsensorConfigSensor1TemperatureHighWarningStatus
            highCriticalState => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.3.11', map => \%map_state }  # inSeptsensorConfigSensor1TemperatureHighCriticalStatus
        },
        2 => {
            name              => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.1' }, # inSeptsensorConfigSensor2TemperatureName
            lowWarning        => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.2' }, # inSeptsensorConfigSensor2TemperatureLowWarning
            lowCritical       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.3' }, # inSeptsensorConfigSensor2TemperatureLowCritical
            highWarning       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.4' }, # inSeptsensorConfigSensor2TemperatureHighWarning
            highCritical      => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.5' }, # inSeptsensorConfigSensor2TemperatureHighCritical
            lowWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.8', map => \%map_state },  # inSeptsensorConfigSensor2TemperatureLowWarningStatus
            lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.9', map => \%map_state },  # inSeptsensorConfigSensor2TemperatureLowCriticalStatus
            highWarningState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.10', map => \%map_state }, # inSeptsensorConfigSensor2TemperatureHighWarningStatus
            highCriticalState => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.3.11', map => \%map_state }  # inSeptsensorConfigSensor2TemperatureHighCriticalStatus
        }
    };
    my $oid_sensorEntry = '.1.3.6.1.4.1.19011.1.3.1.1.3.2.1'; # inSeptsensorMonitorSensorEntry

    my $snmp_result = $self->{snmp}->get_table(oid => $oid_sensorEntry, start => $mapping->{current}->{oid}, end => $mapping->{alarm}->{oid});
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{alarm}->{oid}\.(.*)$/);
        my $instance = $1;

        next if (!defined($devices->{$instance}) || $devices->{$instance}->{state} eq 'disabled');

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my $snmp_config = $self->{snmp}->get_leef(oids => [ map($_->{oid} . '.0', values(%{$mapping_config->{$instance}})) ]);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping_config->{$instance}, results => $snmp_config, instance => 0);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{current} *= 0.1;
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance: %s] [value: %s]",
                $result2->{name}, $result->{alarm}, $instance, 
                $result->{current}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{alarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Temperature '%s' status is '%s'", $result2->{name}, $result->{alarm})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{current});
        if ($checked == 0) {
            $result2->{lowWarning} = ($result2->{lowWarningState} eq 'enabled') ? $result2->{lowWarning} * 0.1 : '';
            $result2->{lowCritical} = ($result2->{lowCriticalState} eq 'enabled') ? $result2->{lowCritical} * 0.1 : '';
            $result2->{highWarning} = ($result2->{highWarningState} eq 'enabled') ? $result2->{highWarning} * 0.1 : '';
            $result2->{highCritical} = ($result2->{highCriticalState} eq 'enabled') ? $result2->{highCritical} * 0.1 : '';
            my $warn_th = $result2->{lowWarning} . ':' . $result2->{highWarning};
            my $crit_th = $result2->{lowCritical} . ':' . $result2->{highCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Temperature '%s' is %s %s", $result2->{name}, $result->{current}, $self->{temperature_unit})
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.' . (($self->{temperature_unit} eq 'C') ? 'celsius' : 'fahrenheit'),
            unit => $self->{temperature_unit},
            instances => $result2->{name},
            value => $result->{current},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    check_inSeptPro($self) if ($self->{inSeptPro} == 1);
    check_inSept($self) if ($self->{inSept} == 1);
}

1;
