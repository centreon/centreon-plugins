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

package hardware::sensors::jacarta::snmp::mode::components::humidity;

use strict;
use warnings;
use hardware::sensors::jacarta::snmp::mode::components::resources qw(%map_default_status %map_state);

sub load {}

sub check_inSeptPro {
    my ($self) = @_;

    my $mapping = {
        name    => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.2' }, # isDeviceMonitorHumidityName
        current => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.3' }, # isDeviceMonitorHumidity
        alarm   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1.4', map => \%map_default_status } # isDeviceMonitorHumidityAlarm
    };
    my $mapping_config = {
        lowWarning        => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.3' }, # isDeviceConfigHumidityLowWarning
        lowCritical       => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.4' }, # isDeviceConfigHumidityLowCritical
        highWarning       => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.5' }, # isDeviceConfigHumidityHighWarning
        highCritical      => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.6' }, # isDeviceConfigHumidityHighCritical
        lowWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.9', map => \%map_state }, # isDeviceConfigHumidityLowWarningState
        lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.10', map => \%map_state }, # isDeviceConfigHumidityLowCriticalState
        highWarningState  => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.11', map => \%map_state }, # isDeviceConfigHumidityHighWarningState
        highCriticalState => { oid => '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1.12', map => \%map_state } # isDeviceConfigHumidityHighCriticalState
    };
    my $oid_humEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.1.2.1'; # isDeviceMonitorHumidityEntry
    my $oid_configHumEntry = '.1.3.6.1.4.1.19011.1.3.2.1.3.2.3.1'; # isDeviceConfigHumidityEntry

    my $snmp_result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_humEntry, end => $mapping->{alarm}->{oid} } ,
            { oid => $oid_configHumEntry, start => $mapping_config->{lowWarning}->{oid}, end => $mapping_config->{lowWarning}->{highCriticalState} }
        ]
    );

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$snmp_result->{$oid_humEntry}})) {
        next if ($oid !~ /^$mapping->{alarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_humEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping_config, results => $snmp_result->{$oid_configHumEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;
        
        $result->{current} *= 0.01;
        $self->{output}->output_add(
            long_msg => sprintf(
                    "humidity '%s' status is '%s' [instance: %s] [value: %s]",
                    $result->{name},
                    $result->{alarm},
                    $instance, 
                    $result->{current}
                )
            );
        
        my $exit = $self->get_severity(label => 'default', section => 'humidity', value => $result->{alarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Humdity '%s' status is '%s'", $result->{name}, $result->{alarm})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{current});
        if ($checked == 0) {
            $result2->{lowWarning} = ($result2->{lowWarningState} eq 'enabled') ? $result2->{lowWarning} * 0.01 : '';
            $result2->{lowCritical} = ($result2->{lowCriticalState} eq 'enabled') ? $result2->{lowCritical} * 0.01 : '';
            $result2->{highWarning} = ($result2->{highWarningState} eq 'enabled') ? $result2->{highWarning} * 0.01 : '';
            $result2->{highCritical} = ($result2->{highCriticalState} eq 'enabled') ? $result2->{highCritical} * 0.01 : '';
            my $warn_th = $result2->{lowWarning} . ':' . $result2->{highWarning};
            my $crit_th = $result2->{lowCritical} . ':' . $result2->{highCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Humdity '%s' is %s %%", $result->{name}, $result->{current})
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.humidity.percentage',
            unit => '%',
            instances => $result->{name},
            value => $result->{current},
            warning => $warn,
            critical => $crit,
            min => 0, max => 100
        );
    }
}

sub check_inSept {
    my ($self) = @_;

    my $devices = $self->getInSeptDevices();

    my $mapping = {
        current => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.3.2.1.5' }, # inSeptsensorMonitorDeviceHumidity
        alarm   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.3.2.1.6', map => \%map_default_status } # inSeptsensorMonitorDeviceHumidityAlarm
    };
    my $mapping_config = {
        1 => {
            name              => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.1' }, # inSeptsensorConfigSensor1HumdityName
            lowWarning        => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.2' }, # inSeptsensorConfigSensor1HumidityLowWarning
            lowCritical       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.3' }, # inSeptsensorConfigSensor1HumidityLowCritical
            highWarning       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.4' }, # inSeptsensorConfigSensor1HumidityHighWarning
            highCritical      => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.5' }, # inSeptsensorConfigSensor1HumidityHighCritical
            lowWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.8', map => \%map_state },  # inSeptsensorConfigSensor1HumidityLowWarningStatus
            lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.9', map => \%map_state },  # inSeptsensorConfigSensor1HumidityLowCriticalStatus
            highWarningState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.10', map => \%map_state }, # inSeptsensorConfigSensor1HumidityHighWarningStatus
            highCriticalState => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.3.4.11', map => \%map_state }  # inSeptsensorConfigSensor1HumidityHighCriticalStatus
        },
        2 => {
            name              => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.1' }, # inSeptsensorConfigSensor2HumdityName
            lowWarning        => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.2' }, # inSeptsensorConfigSensor2HumidityLowWarning
            lowCritical       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.3' }, # inSeptsensorConfigSensor2HumidityLowCritical
            highWarning       => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.4' }, # inSeptsensorConfigSensor2HumidityHighWarning
            highCritical      => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.5' }, # inSeptsensorConfigSensor2HumidityHighCritical
            lowWarningState   => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.8', map => \%map_state },  # inSeptsensorConfigSensor2HumidityLowWarningStatus
            lowCriticalState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.9', map => \%map_state },  # inSeptsensorConfigSensor2HumidityLowCriticalStatus
            highWarningState  => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.10', map => \%map_state }, # inSeptsensorConfigSensor2HumidityHighWarningStatus
            highCriticalState => { oid => '.1.3.6.1.4.1.19011.1.3.1.1.4.4.4.11', map => \%map_state }  # inSeptsensorConfigSensor2HumidityHighCriticalStatus
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

        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;

        $result->{current} *= 0.1;
        $self->{output}->output_add(
            long_msg => sprintf(
                    "humidity '%s' status is '%s' [instance: %s] [value: %s]",
                    $result2->{name},
                    $result->{alarm},
                    $instance, 
                    $result->{current}
                )
            );
        
        my $exit = $self->get_severity(label => 'default', section => 'humidity', value => $result->{alarm});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Humdity '%s' status is '%s'", $result2->{name}, $result->{alarm})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{current});
        if ($checked == 0) {
            $result2->{lowWarning} = ($result2->{lowWarningState} eq 'enabled') ? $result2->{lowWarning} * 0.1 : '';
            $result2->{lowCritical} = ($result2->{lowCriticalState} eq 'enabled') ? $result2->{lowCritical} * 0.1 : '';
            $result2->{highWarning} = ($result2->{highWarningState} eq 'enabled') ? $result2->{highWarning} * 0.1 : '';
            $result2->{highCritical} = ($result2->{highCriticalState} eq 'enabled') ? $result2->{highCritical} * 0.1 : '';
            my $warn_th = $result2->{lowWarning} . ':' . $result2->{highWarning};
            my $crit_th = $result2->{lowCritical} . ':' . $result2->{highCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Humdity '%s' is %s %%", $result2->{name}, $result->{current})
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.humidity.percentage',
            unit => '%',
            instances => $result2->{name},
            value => $result->{current},
            warning => $warn,
            critical => $crit,
            min => 0, max => 100
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidities");
    $self->{components}->{humidity} = {name => 'humidities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    check_inSeptPro($self) if ($self->{inSeptPro} == 1);
    check_inSept($self) if ($self->{inSept} == 1);
}

1;
