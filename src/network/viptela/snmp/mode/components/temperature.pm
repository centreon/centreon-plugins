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

package network::viptela::snmp::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach (@{$self->{results}}) {
        next if ($_->{type} ne 'temperature');
        my $instance = 'temperature.' . $_->{name};
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        my $measure = '-';
        $measure = $1 if ($_->{measure} =~ /(\d+)\s+degrees\s+C/);

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance: %s, value: %s]",
                $_->{name},
                $_->{status},
                $instance,
                $measure
            )
        );
        $exit = $self->get_severity(label => 'default', section => 'temperature', value => $_->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("temperature '%s' status is '%s'", $_->{name}, $_->{status})
            );
        }

        next if ($measure eq '-');

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $_->{measure});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("temperature '%s' is '%s' C", $_->{name}, $measure)
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $_->{name},
            value => $measure,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
