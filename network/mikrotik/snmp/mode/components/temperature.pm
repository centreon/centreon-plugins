#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    mtxrHlTemperature => { oid => '.1.3.6.1.4.1.14988.1.1.3.10' },
    mtxrHlProcessorTemperature => { oid => '.1.3.6.1.4.1.14988.1.1.3.11' },
};

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature");
    $self->{components}->{temperature} = {name => 'temperature', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    my $instance = 0;
    my ($exit, $warn, $crit, $checked);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
    
    if (defined($result->{mtxrHlTemperature}) && $result->{mtxrHlTemperature} =~ /[0-9]+/) {
        
        $self->{output}->output_add(long_msg => sprintf("Temperature is '%s' C", $result->{mtxrHlTemperature} / 10));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => '1', value => $result->{mtxrHlTemperature} / 10);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature is '%s' C", $result->{mtxrHlTemperature} / 10));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => 'system',
            value => $result->{mtxrHlTemperature} / 10,
            warning => $warn,
            critical => $crit
        );
        $self->{components}->{temperature}->{total}++;
    }
    if (defined($result->{mtxrHlProcessorTemperature}) && $result->{mtxrHlProcessorTemperature} =~ /[0-9]+/) {
        
        $self->{output}->output_add(long_msg => sprintf("Processor temperature is '%s' C", $result->{mtxrHlProcessorTemperature} / 10));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => '2', value => $result->{mtxrHlProcessorTemperature} / 10);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Processor temperature is '%s' C", $result->{mtxrHlProcessorTemperature} / 10));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => 'processor',
            value => $result->{mtxrHlProcessorTemperature} / 10,
            warning => $warn,
            critical => $crit
        );
        $self->{components}->{temperature}->{total}++;
    }
}

1;
