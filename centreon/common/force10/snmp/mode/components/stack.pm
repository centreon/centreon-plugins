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

package centreon::common::force10::snmp::mode::components::stack;

use strict;
use warnings;

my $map_unit_status = {
    1 => 'ok', 2 => 'unsupported', 3 => 'codeMismatch', 4 => 'configMismatch',
    5 => 'unitDown', 6 => 'notPresent'
};

my $mapping = {
    sseries => {
        status      => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.2.1.8', map => $map_unit_status }, # chStackUnitStatus
        temperature => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.2.1.14' } # chStackUnitTemp
    },
    mseries => {
        status      => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.1.1.8', map => $map_unit_status }, # chStackUnitStatus
        temperature => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.1.1.14' } # chStackUnitTemp
    },
    os9 => {
        status      => { oid => '.1.3.6.1.4.1.6027.3.26.1.3.4.1.8', map => $map_unit_status }, # dellNetStackUnitStatus
        temperature => { oid => '.1.3.6.1.4.1.6027.3.26.1.3.4.1.13' } # dellNetStackUnitTemp
    }
};
my $stack_table = {
    sseries => '.1.3.6.1.4.1.6027.3.10.1.2.2.1',
    mseries => '.1.3.6.1.4.1.6027.3.19.1.2.1.1',
    os9     => '.1.3.6.1.4.1.6027.3.26.1.3.4.1'
};

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        { oid => $stack_table->{sseries}, start => $mapping->{sseries}->{status}->{oid}, end => $mapping->{sseries}->{temperature}->{oid} },
        { oid => $stack_table->{mseries}, start => $mapping->{mseries}->{status}->{oid}, end => $mapping->{mseries}->{temperature}->{oid} },
        { oid => $stack_table->{os9}, start => $mapping->{os9}->{status}->{oid}, end => $mapping->{os9}->{temperature}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking stack');
    $self->{components}->{stack} = { name => 'stack', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'stack'));

    foreach my $name (keys %$stack_table) {
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $stack_table->{$name} }})) {
            next if ($oid !~ /^$mapping->{$name}->{status}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $self->{snmp}->map_instance(mapping => $mapping->{$name}, results => $self->{results}->{ $stack_table->{$name} }, instance => $instance);

            next if ($result->{status} =~ /absent/i && 
                     $self->absent_problem(section => 'stack', instance => $instance));
            next if ($self->check_filter(section => 'stack', instance => $instance));
            $self->{components}->{stack}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "stack '%s' status is '%s' [instance: %s, temperature: %s]", 
                    $instance,
                    $result->{status}, 
                    $instance,
                    $result->{temperature}
                )
            );
            my $exit = $self->get_severity(section => 'stack', value => $result->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Stack '%s' status is '%s'", 
                        $instance, $result->{status}
                    )
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperature});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("stack '%s' temperature is %s C", $instance, $result->{temperature})
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.stack.temperature.celsius',
                unit => 'C',
                instances => $instance,
                value => $result->{temperature},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
