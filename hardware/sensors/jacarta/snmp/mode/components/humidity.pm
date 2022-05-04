#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
            unit => '%',
            nlabel => 'hardware.humidity.percentage',
            instances => $result->{name},
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
}

1;
