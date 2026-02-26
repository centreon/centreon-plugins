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

package network::waystream::snmp::mode::components::voltage;

use strict;
use warnings;

my %map_status = (
    -3 => 'na',
    -1 => 'failed',
    0  => 'ok',
    1  => 'high',
    2  => 'low',
    3  => 'notPresent',
    4  => 'disabled'
);

my $mapping = {
    VoltChannel      => { oid => '.1.3.6.1.4.1.9303.4.1.2.2.1.1' },# wsVoltChannel
    Volt             => { oid => '.1.3.6.1.4.1.9303.4.1.2.2.1.3' },# wsTempMeasured
    VoltStatus       => { oid => '.1.3.6.1.4.1.9303.4.1.2.2.1.6', map => \%map_status },# wsVoltStatus
    VoltHighCritical => { oid => '.1.3.6.1.4.1.9303.4.1.2.2.1.5' },# wsTempThresholdHigh
    VoltLowCritical  => { oid => '.1.3.6.1.4.1.9303.4.1.2.2.1.4' },# wsTempThresholdLow
};

my $oid_voltageEntry = '.1.3.6.1.4.1.9303.4.1.2.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_voltageEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_voltageEntry}})) {
        next if ($oid !~ /^$mapping->{VoltChannel}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_voltageEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $result->{Volt} = $result->{Volt} * 0.001;

        $self->{output}->output_add(
            long_msg => sprintf("voltage '%s' status is '%s' [instance = %s] [value = %s]",
                $result->{VoltChannel}, $result->{VoltStatus}, $instance,
                $result->{Volt})
        );

        my $exit = $self->get_severity(label => 'default1', section => 'voltage', value => $result->{VoltStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Voltage '%s' status is '%s'", $result->{VoltChannel}, $result->{VoltStatus})
            );
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'voltage',
            instance => $instance,
            value    => $result->{Volt}
        );

        if ($checked == 0) {
            $result->{VoltLowCritical} = (defined($result->{VoltLowCritical}) && $result->{VoltLowCritical} =~ /[0-9]/) ?
                $result->{VoltLowCritical} * 0.001 : '';
            $result->{VoltHighCritical} = (defined($result->{VoltHighCritical}) && $result->{VoltHighCritical} =~ /[0-9]/) ?
                $result->{VoltHighCritical} * 0.001 : '';
            my $warn_th = undef;
            my $crit_th = $result->{VoltLowCritical} . ':' . $result->{VoltHighCritical};
            $self->{perfdata}->threshold_validate(
                label => 'warning-voltage-instance-' . $instance, value => $warn_th
            );
            $self->{perfdata}->threshold_validate(
                label => 'critical-voltage-instance-' . $instance, value => $crit_th
            );

            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit2,
                short_msg => sprintf("Voltage '%s' is %s", $result->{VoltChannel}, $result->{Volt})
            );
        }
        $self->{output}->perfdata_add(
            label     => 'voltage',
            unit      => 'V',
            nlabel    => 'hardware.sensor.voltage.volt',
            instances => $result->{VoltChannel},
            value     => sprintf('%.2f', $result->{Volt}),
            warning   => $warn,
            critical  => $crit,
        );
    }
}

1;
