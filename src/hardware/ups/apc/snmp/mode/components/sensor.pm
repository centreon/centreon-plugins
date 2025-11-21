#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::components::sensor;

use strict;
use warnings;

my $map_alarm_status = {
    1 => 'uioNormal', 2 => 'uioWarning', 3 => 'uioCritical', 4 => 'sensorStatusNotApplicable'
};
my $map_iem_status = {
    1 => 'disconnected', 2 => 'connected'
};
my $map_iem_unit = {
    1 => 'celsius', 2 => 'fahrenheit'
};

my $mapping = {
    uioSensorStatusSensorName      => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.3' },
    uioSensorStatusTemperatureDegC => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.6' },
    uioSensorStatusHumidity        => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.7' },
    uioSensorStatusAlarmStatus     => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.9', map => $map_alarm_status }
};
my $mapping_iem = {
    iemStatusProbeName         => { oid => '.1.3.6.1.4.1.318.1.1.10.2.3.2.1.2' },
    iemStatusProbeStatus       => { oid => '.1.3.6.1.4.1.318.1.1.10.2.3.2.1.3', map => $map_iem_status },
    iemStatusProbeCurrentTemp  => { oid => '.1.3.6.1.4.1.318.1.1.10.2.3.2.1.4' },
    iemStatusProbeTempUnits    => { oid => '.1.3.6.1.4.1.318.1.1.10.2.3.2.1.5', map => $map_iem_unit },
    iemStatusProbeCurrentHumid => { oid => '.1.3.6.1.4.1.318.1.1.10.2.3.2.1.6' }
};

my $oid_uioSensorStatusEntry = '.1.3.6.1.4.1.318.1.1.25.1.2.1';
my $oid_iemStatusProbesEntry = '.1.3.6.1.4.1.318.1.1.10.2.3.2.1';
my $oid_upsBasicIdentModel = '.1.3.6.1.4.1.318.1.1.1.1.1.1.0';
my $oid_upsBasicIdentFamilyName = '.1.3.6.1.4.1.318.1.1.1.1.1.3.0';

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        {
            oid   => $oid_uioSensorStatusEntry,
            start => $mapping->{uioSensorStatusSensorName}->{oid},
            end   => $mapping->{uioSensorStatusAlarmStatus}->{oid}
        },
        {
            oid   => $oid_iemStatusProbesEntry,
            start => $mapping_iem->{iemStatusProbeName}->{oid},
            end   => $mapping_iem->{iemStatusProbeCurrentHumid}->{oid}
        };
}

sub check_uoi {
    my ($self) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_uioSensorStatusEntry}})) {
        next if ($oid !~ /^$mapping->{uioSensorStatusSensorName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_uioSensorStatusEntry},
            instance => $instance
        );
        $instance = 'universal-' . $1;

        next if ($self->check_filter(section => 'sensor', instance => $instance));

        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "universal sensor '%s' status is '%s' [instance = %s] [temperature = %s C] [humidity = %s %%]",
                $result->{uioSensorStatusSensorName}, $result->{uioSensorStatusAlarmStatus}, $instance,
                $result->{uioSensorStatusTemperatureDegC} != -1 ? $result->{uioSensorStatusTemperatureDegC} : '-',
                $result->{uioSensorStatusHumidity} != -1 ? $result->{uioSensorStatusHumidity} : '-'
            )
        );
        $exit = $self->get_severity(section => 'sensor', value => $result->{uioSensorStatusAlarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "universal sensor '%s' status is '%s'",
                    $result->{uioSensorStatusSensorName},
                    $result->{uioSensorStatusAlarmStatus})
            );
        }

        if ($result->{uioSensorStatusTemperatureDegC} != -1) {
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section  => 'temperature',
                instance => $instance,
                value    => $result->{uioSensorStatusTemperatureDegC}
            );

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf(
                        "universal sensor temperature '%s' is %s C",
                        $result->{uioSensorStatusSensorName},
                        $result->{uioSensorStatusTemperatureDegC}
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel    => 'sensor.universal.temperature.celsius',
                unit      => 'C',
                instances => $result->{uioSensorStatusSensorName},
                value     => $result->{uioSensorStatusTemperatureDegC},
                warning   => $warn,
                critical  => $crit
            );
        }

        next if ($result->{uioSensorStatusHumidity} == -1);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'humidity',
            instance => $instance,
            value    => $result->{uioSensorStatusHumidity}
        );

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "universal sensor humidity '%s' is %s %%",
                    $result->{uioSensorStatusSensorName},
                    $result->{uioSensorStatusHumidity}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel    => 'sensor.universal.humidity.percentage',
            unit      => '%',
            instances => $result->{uioSensorStatusSensorName},
            value     => $result->{uioSensorStatusHumidity},
            warning   => $warn,
            critical  => $crit,
            min       => 0, max => 100
        );
    }
}

sub check_iem {
    my ($self) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_iemStatusProbesEntry}})) {
        next if ($oid !~ /^$mapping_iem->{iemStatusProbeName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping_iem,
            results  => $self->{results}->{$oid_iemStatusProbesEntry},
            instance => $instance
        );
        $instance = 'integrated-' . $1;

        next if ($self->check_filter(section => 'sensor', instance => $instance));

        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "integrated sensor '%s' status is '%s' [instance = %s] [temperature = %s %s] [humidity = %s %%]",
                $result->{iemStatusProbeName}, $result->{iemStatusProbeStatus}, $instance,
                $result->{iemStatusProbeCurrentTemp} != -1 ? $result->{iemStatusProbeCurrentTemp} : '-',
                $result->{iemStatusProbeTempUnits},
                $result->{iemStatusProbeCurrentHumid} != -1 ? $result->{iemStatusProbeCurrentHumid} : '-'
            )
        );
        $exit = $self->get_severity(section => 'sensor', value => $result->{iemStatusProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "integrated sensor '%s' status is '%s'",
                    $result->{iemStatusProbeName},
                    $result->{iemStatusProbeStatus})
            );
        }

        next if ($result->{iemStatusProbeStatus} eq 'disconnected');

        if ($result->{iemStatusProbeCurrentTemp} != -1) {
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section  => 'temperature',
                instance => $instance,
                value    => $result->{iemStatusProbeCurrentTemp}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf(
                        "integrated sensor temperature '%s' is %s %s",
                        $result->{iemStatusProbeName},
                        $result->{iemStatusProbeCurrentTemp},
                        $result->{iemStatusProbeTempUnits}
                    )
                );
            }

            $self->{output}->perfdata_add(
                unit      => $result->{iemStatusProbeTempUnits} eq 'celsius' ? 'C' : 'F',
                nlabel    => 'sensor.integrated.temperature.' . $result->{iemStatusProbeTempUnits},
                instances => $result->{iemStatusProbeName},
                value     => $result->{iemStatusProbeCurrentTemp},
                warning   => $warn,
                critical  => $crit
            );
        }

        next if ($result->{iemStatusProbeCurrentHumid} == -1);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'humidity',
            instance => $instance,
            value    => $result->{iemStatusProbeCurrentHumid}
        );
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "integrated sensor humidity '%s' is %s %%",
                    $result->{iemStatusProbeName},
                    $result->{iemStatusProbeCurrentHumid}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel    => 'sensor.integrated.humidity.percentage',
            unit      => '%',
            instances => $result->{iemStatusProbeName},
            value     => $result->{iemStatusProbeCurrentHumid},
            warning   => $warn,
            critical  => $crit,
            min       => 0, max => 100
        );
    }
}

sub check_galaxy_vs_temp {
    my ($self) = @_;

    my ($instance, $name) = (0, 'ambient');
    my $oid_ambientCurrentTemp = '.1.3.6.1.4.1.318.1.1.1.13.11.1.0';
    my $result = $self->{snmp}->get_leef(oids => [ $oid_ambientCurrentTemp ], nothing_quit => 1);
    my $temperature = $result->{$oid_ambientCurrentTemp} / 10;

    return if ($self->check_filter(section => 'temperature', instance => $instance, name => $name));
    $self->{components}->{sensor}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' [instance = %s, value = %s C]",
            $name,
            $instance,
            $temperature)
    );

    my ($exit, $warn, $crit) = $self->get_severity_numeric(
        section  => 'temperature',
        instance => $instance,
        name     => $name,
        value    => $temperature
    );

    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity  => $exit,
            short_msg => sprintf("temperature '%s' is %s C", $name, $temperature)
        );
    }

    $self->{output}->perfdata_add(
        unit      => 'C',
        nlabel    => 'sensor.ambient.temperature.celsius',
        instances => $name,
        value     => $temperature,
        warning   => $warn,
        critical  => $crit
    );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking sensors');
    $self->{components}->{sensor} = { name => 'sensors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sensor'));


    check_uoi($self);
    check_iem($self);

    # Check if this is Galaxy VS model
    my $result = $self->{snmp}->get_leef( oids => [ $oid_upsBasicIdentFamilyName, $oid_upsBasicIdentModel, ] );
    my $galaxy_vs = grep { defined && /Galaxy VS/ } %$result;

    # if the model is an Galaxy VS we use other MIB for the temperature sensor
    check_galaxy_vs_temp($self) if $galaxy_vs;
}

1;
