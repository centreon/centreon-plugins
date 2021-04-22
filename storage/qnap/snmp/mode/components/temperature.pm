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

# In MIB 'NAS.mib'
my $mapping = {
    cpu_temp    => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.4.2' }, # cpu-Temperature
    enclosure   => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.1.2.1.2' }, # enclosureID
    system_temp => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.1.2.1.7' }, # enclosureSystemTemp
};

my $entry = '.1.3.6.1.4.1.24681.1.4.1.1.1.1.1.2';

sub load {
    my ($self) = @_;

    if (defined($self->{option_results}->{legacy})) {
        $mapping = {
            cpu_temp    => { oid => '.1.3.6.1.4.1.24681.1.2.5' }, # cpu-Temperature
            system_temp => { oid => '.1.3.6.1.4.1.24681.1.2.6' }, # systemTemperature
        };
        $entry = '.1.3.6.1.4.1.24681.1.2';
    }

    push @{$self->{request}}, {
        oid => $entry,
        start => defined($self->{option_results}->{legacy}) ? $mapping->{cpu_temp}->{oid} : $mapping->{enclosure}->{oid},
        end => $mapping->{system_temp}->{oid}
    };
    if (!defined($self->{option_results}->{legacy})) {
        push @{$self->{request}}, {
            oid => $mapping->{cpu_temp}->{oid}
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my $result = $self->{snmp}->map_instance(
        mapping => $mapping,
        results => defined($self->{option_results}->{legacy}) ? $self->{results}->{$entry} : $self->{results}->{$mapping->{cpu_temp}->{oid}},
        instance => 0
    );

    $result->{cpu_temp} = defined($result->{cpu_temp}) ? $result->{cpu_temp} : 'unknown';
    if ($result->{cpu_temp} =~ /([0-9]+)\s*C?/ && !$self->check_filter(section => 'temperature', instance => 'cpu')) {
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
                    "CPU Temperature is '%s' degree centigrade", $value
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

    $result->{system_temp} = defined($result->{system_temp}) ? $result->{system_temp} : 'unknown';
    if ($result->{system_temp} =~ /([0-9]+)\s*C/ && !$self->check_filter(section => 'temperature', instance => 'system')) {
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
                    "System Temperature is '%s' degree centigrade", $value
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

    return if defined($self->{option_results}->{legacy});
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$entry}})) {
        next if ($oid !~ /^$mapping->{enclosure}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$entry}, instance => $instance);
        $instance = 'enclosure' . $result->{enclosure};

        next if ($self->check_filter(section => 'temperature', instance => $instance));

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure '%s' [instance: %s] temperature is '%s' degree centigrade", $result->{enclosure}, $instance, $result->{system_temp}
            )
        );

        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{system_temp});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Enclosure '%s' Temperature is '%s' degree centigrade", $result->{enclosure}, $result->{system_temp}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => 'enclosure' . $result->{enclosure},
            value => $result->{system_temp}
        );
    }
}

1;
