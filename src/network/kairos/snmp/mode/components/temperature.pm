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

package network::microsens::g6::snmp::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperature', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    return if (!defined($self->{results}->{system_temp}) || $self->check_filter(section => 'temperature', instance => 1));

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature system is %s C",
            $self->{results}->{system_temp}
        )
    );
    $self->{components}->{temperature}->{total}++;

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => 'system', value => $self->{results}->{system_temp});            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "temperature system is '%s' C", $self->{results}->{system_temp}
            )
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        instances => 'system',
        value => $self->{results}->{system_temp},
        warning => $warn,
        critical => $crit,
        min => 0
    );
}

1;
