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

package network::mikrotik::snmp::mode::components::temperature;

use strict;
use warnings;
use network::mikrotik::snmp::mode::components::resources qw($map_gauge_unit $mapping_gauge);

my $mapping = {
    mtxrHlTemperature => { oid => '.1.3.6.1.4.1.14988.1.1.3.10' }, # SoC or PCB according to Mikrotik support
    mtxrHlProcessorTemperature => { oid => '.1.3.6.1.4.1.14988.1.1.3.11' }
};

sub load {}

sub check_temperature {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' is %s C",
            $options{name},
            $options{value}
        )
    );

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $options{name}, value => $options{value});
    if ($options{value} == -273) { # RouterOS returns this when the SNMP agent hangs...
        $exit = 'UNKNOWN';
    }
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("Temperature '%s' is %s C", $options{name}, $options{value})
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        instances => $options{name},
        value => $options{value},
        warning => $warn,
        critical => $crit
    );
    $self->{components}->{temperature}->{total}++;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature");
    $self->{components}->{temperature} = { name => 'temperature', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach (keys %{$self->{results}}) {
        next if (! /^$mapping_gauge->{unit}->{oid}\.(\d+)/);
        next if ($map_gauge_unit->{ $self->{results}->{$_} } ne 'celsius');
        my $result = $self->{snmp}->map_instance(mapping => $mapping_gauge, results => $self->{results}, instance => $1);
        next if ($self->check_filter(section => 'temperature', instance => $result->{name}));
        check_temperature(
            $self,
            value => $result->{value},
            name => $result->{name}
        );
    }

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => 0);
    if (defined($result->{mtxrHlTemperature}) && ! $self->check_filter(section => 'temperature', instance => 'system')) {
        check_temperature(
            $self,
            value => $result->{mtxrHlTemperature} / 10,
            name => 'system'
        );
    }
    if (defined($result->{mtxrHlProcessorTemperature}) && ! $self->check_filter(section => 'temperature', instance => 'processor')) {
        check_temperature(
            $self,
            value => $result->{mtxrHlProcessorTemperature} / 10,
            name => 'processor'
        );
    }
}

1;
