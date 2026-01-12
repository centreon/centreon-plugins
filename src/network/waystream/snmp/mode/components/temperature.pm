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

package network::waystream::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_status = (
    -1 => 'failed',
    0  => 'ok',
    1  => 'high',
    2  => 'low',
    4  => 'disabled'
);

my $mapping = {
    TempSensor       => { oid => '.1.3.6.1.4.1.9303.4.1.2.1.1.1' },# wsTempSensor
    TempDegree       => { oid => '.1.3.6.1.4.1.9303.4.1.2.1.1.2' },# wsTempMeasured
    TempStatus       => { oid => '.1.3.6.1.4.1.9303.4.1.2.1.1.7', map => \%map_status },# wsTempStatus
    TempHighCritical => { oid => '.1.3.6.1.4.1.9303.4.1.2.1.1.6' },# wsTempThresholdHigh
    TempLowCritical  => { oid => '.1.3.6.1.4.1.9303.4.1.2.1.1.5' },# wsTempThresholdLow
};

my $oid_temperatureEntry = '.1.3.6.1.4.1.9303.4.1.2.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_temperatureEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureEntry}})) {
        next if ($oid !~ /^$mapping->{TempSensor}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_temperatureEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{TempDegree} = $result->{TempDegree} * 0.01;

        $self->{output}->output_add(
            long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                $result->{TempSensor}, $result->{TempStatus}, $instance,
                $result->{TempDegree})
        );

        my $exit = $self->get_severity(label => 'default1', section => 'temperature', value => $result->{TempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Temperature '%s' status is '%s'", $result->{TempSensor}, $result->{TempStatus})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'temperature',
            instance => $instance,
            value    => $result->{TempDegree}
        );

        if ($checked == 0) {
            $result->{TempLowCritical} = (defined($result->{TempLowCritical}) && $result->{TempLowCritical} =~ /[0-9]/) ?
                $result->{TempLowCritical} * 0.01 : '';
            $result->{TempHighCritical} = (defined($result->{TempHighCritical}) && $result->{TempHighCritical} =~ /[0-9]/) ?
                $result->{TempHighCritical} * 0.01 : '';
            my $warn_th = undef;
            my $crit_th = $result->{TempLowCritical} . ':' . $result->{TempHighCritical};
            $self->{perfdata}->threshold_validate(
                label => 'warning-temperature-instance-' . $instance, value => $warn_th
            );
            $self->{perfdata}->threshold_validate(
                label => 'critical-temperature-instance-' . $instance, value => $crit_th
            );

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit2,
                short_msg => sprintf("Temperature '%s' is %s", $result->{TempSensor}, $result->{TempDegree})
            );
        }
        $self->{output}->perfdata_add(
            label     => 'temperature',
            unit      => 'C',
            nlabel    => 'hardware.sensor.temperature.celsius',
            instances => $result->{TempSensor},
            value     => sprintf('%.2f', $result->{TempDegree}),
            warning   => $warn,
            critical  => $crit,
        );
    }
}

1;
