#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::ibm::bladecenter::snmp::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my $oid_hwTemperatureWarn = '.1.3.6.1.4.1.26543.2.5.1.3.1.22.0';
    my $oid_hwTemperatureShut = '.1.3.6.1.4.1.26543.2.5.1.3.1.23.0';
    my $results = $self->{snmp}->get_leef(oids => [$oid_hwTemperatureWarn, $oid_hwTemperatureShut], nothing_quit => 1);

    # .1.3.6.1.4.1.20301.2.5.1.3.1.41.1.1.20.1 = STRING: "44 C (Warn at 66 C / Recover at 61 C)"
    # .1.3.6.1.4.1.20301.2.5.1.3.1.41.1.1.21.1 = STRING: "44 C (Shutdown at 72 C / Recover at 67 C)"
    $results->{$oid_hwTemperatureWarn} =~ /^([.0-9]+)\s*C\s*\(Warn(?:ing)?\s*at\s*([.0-9]+)\s*C/i;
    my $temperature = $1;
    my $warning = $2;
    $results->{$oid_hwTemperatureShut} =~ /^([.0-9]+)\s*C\s*\(Shutdown\s*at\s*([.0-9]+)\s*C/i;
    if ($1 > $temperature) {
        $temperature = $1;
    }
    my $critical = ($warning + $2) / 2;

    $self->{components}->{temperature}->{total}++;
        
    $self->{output}->output_add(long_msg => 
        sprintf(
            "Temperature is %.1f C",
             $temperature
        )
    );

    my $exit = 'OK';
    if ($temperature >= $warning) {
        $exit = 'WARNING';
    }
    if ($temperature >= $critical) {
        $exit = 'CRITICAL';
    }
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Temperature is %.1f C",
                $temperature
            )
        );
    }

    $self->{output}->perfdata_add(
        label => 'temperature', unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        instances => 'system',
        value => $temperature,
        warning => $warning,
        critical => $critical
    );
}

1;
