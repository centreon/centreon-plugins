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

package network::mikrotik::snmp::mode::components::current;

use strict;
use warnings;
use network::mikrotik::snmp::mode::components::resources qw($map_gauge_unit $mapping_gauge);

my $mapping = {
    mtxrHlCurrent => { oid => '.1.3.6.1.4.1.14988.1.1.3.13' }
};

sub load {}

sub check_current {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        long_msg => sprintf(
            "current '%s' is %s A",
            $options{name},
            $options{value}
        )
    );

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'current', instance => $options{name}, value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("Current '%s' is %s A", $options{name}, $options{value})
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'hardware.current.ampere',
        unit => 'A',
        instances => $options{name},
        value => $options{value},
        warning => $warn,
        critical => $crit
    );
    $self->{components}->{current}->{total}++;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking current");
    $self->{components}->{current} = { name => 'current', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'current'));

    foreach (keys %{$self->{results}}) {
        next if (! /^$mapping_gauge->{unit}->{oid}\.(\d+)/);
        next if ($map_gauge_unit->{ $self->{results}->{$_} } ne 'dA');
        my $result = $self->{snmp}->map_instance(mapping => $mapping_gauge, results => $self->{results}, instance => $1);
        next if ($self->check_filter(section => 'current', instance => $result->{name}));
        check_current(
            $self,
            value => $result->{value} / 10,
            name => $result->{name}
        );
    }

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => 0);
    if (defined($result->{mtxrHlCurrent}) && ! $self->check_filter(section => 'current', instance => 'system')) {
        check_current(
            $self,
            value => $result->{mtxrHlCurrent} / 1000,
            name => 'system'
        );
    }
}

1;
