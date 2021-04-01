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

package centreon::common::ibm::nos::snmp::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my $oid_hwTemperatureWarn = '.1.3.6.1.4.1.26543.2.5.1.3.1.22.0';
    my $oid_hwTemperatureShut = '.1.3.6.1.4.1.26543.2.5.1.3.1.23.0';
    my $results = $self->{snmp}->get_leef(oids => [$oid_hwTemperatureWarn, $oid_hwTemperatureShut]);

    return if (!defined($results->{$oid_hwTemperatureWarn}));

    my $instance = 'system';
    # .1.3.6.1.4.1.20301.2.5.1.3.1.41.1.1.20.1 = STRING: "44 C (Warn at 66 C / Recover at 61 C)"
    # .1.3.6.1.4.1.20301.2.5.1.3.1.41.1.1.21.1 = STRING: "44 C (Shutdown at 72 C / Recover at 67 C)"
    $results->{$oid_hwTemperatureWarn} =~ /^([.0-9]+)\s*C\s*\(Warn(?:ing)?\s*at\s*([.0-9]+)\s*C/i;
    my ($temperature, $warning_mib) = ($1, $2);
    $results->{$oid_hwTemperatureShut} =~ /^([.0-9]+)\s*C\s*\(Shutdown\s*at\s*([.0-9]+)\s*C/i;
    $temperature = $1 if ($1 > $temperature);
    my $critical_mib = ($warning_mib + $2) / 2;

    if ($warning_mib == $critical_mib) { #seen on some chassis !
        $warning_mib -= 10;
        $critical_mib -= 5;
    }

    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(long_msg => 
        sprintf(
            "temperature '%s' is %.1f C [instance: %s]",
             $instance,
             $temperature,
             $instance
        )
    );

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temperature);
    if ($checked == 0) {
        $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warning_mib);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $critical_mib);
        $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
        $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        $exit = $self->{perfdata}->threshold_check(
            value => $temperature,
            threshold => [
                { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
            ]
        );
    }

    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Temperature '%s' is %.1f C",
                $instance,
                $temperature
            )
        );
    }

    $self->{output}->perfdata_add(
        unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        instances => 'system',
        value => $temperature,
        warning => $warn,
        critical => $crit
    );
}

1;
