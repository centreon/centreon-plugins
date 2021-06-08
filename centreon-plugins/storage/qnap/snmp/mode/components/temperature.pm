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

package storage::qnap::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    legacy => {
        cpu_temp    => { oid => '.1.3.6.1.4.1.24681.1.2.5' }, # cpu-Temperature
        system_temp => { oid => '.1.3.6.1.4.1.24681.1.2.6' }  # systemTemperature
    },
    ex => {
        cpu_temp    => { oid => '.1.3.6.1.4.1.24681.1.3.5' }, # cpu-TemperatureEX
        system_temp => { oid => '.1.3.6.1.4.1.24681.1.3.6' }  # systemTemperatureEX
    },
    es => {
        cpu_temp    => { oid => '.1.3.6.1.4.1.24681.2.2.5' }, # es-CPU-Temperature
        system_temp => { oid => '.1.3.6.1.4.1.24681.2.2.6' }  # es-SystemTemperature1
    }
};

sub load {}

sub check_temp_result {
    my ($self, %options) = @_;

    $options{result}->{cpu_temp} = defined($options{result}->{cpu_temp}) ? $options{result}->{cpu_temp} : 'unknown';
    if ($options{result}->{cpu_temp} =~ /([0-9]+)\s*C?/ && !$self->check_filter(section => 'temperature', instance => 'cpu')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "cpu temperature is '%s' degree centigrade",
                $value
            )
        );
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'cpu', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "CPU temperature is '%s' degree centigrade", $value
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => 'cpu',
            value => $value
        );
    }

    $options{result}->{system_temp} = defined($options{result}->{system_temp}) ? $options{result}->{system_temp} : 'unknown';
    if ($options{result}->{system_temp} =~ /([0-9]+)\s*C?/ && !$self->check_filter(section => 'temperature', instance => 'system')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "system temperature is '%s' degree centigrade",
                $value
            )
        );
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'system', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "System temperature is '%s' degree centigrade", $value
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => 'system',
            value => $value
        );
    }
}

sub check_temp_es {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{es}})) ]
    );
    my $result = $self->{snmp}->map_instance(mapping => $mapping->{es}, results => $snmp_result, instance => 0);
    check_temp_result($self, result => $result);
}

sub check_temp {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{ex}}), values(%{$mapping->{legacy}})) ],
    );
    my $result = $self->{snmp}->map_instance(mapping => $mapping->{ex}, results => $snmp_result, instance => 0);
    if (defined($result->{cpu_temp})) {
        check_temp_result($self, result => $result);
    } else {
        $result = $self->{snmp}->map_instance(mapping => $mapping->{legacy}, results => $snmp_result, instance => 0);
        check_temp_result($self, result => $result);
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    if ($self->{is_es} == 1) {
        check_temp_es($self);
    } else {
        check_temp($self);
    }
}

1;
