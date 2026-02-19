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

package network::aviat::snmp::mode::components::voltage;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking voltage");
    $self->{components}->{voltage} = { name => 'voltage', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage'));

    foreach (@{$self->{perfs}}) {
        next if ($_->{unit} !~ /volt/i);
        
        next if ($self->check_filter(section => 'voltage', instance => $_->{instance}, name => $_->{slotName} . ' ' . $_->{name}));
        $self->{components}->{voltage}->{total}++;

        my $value = $_->{reading};
        $value /= $_->{scale} if ($_->{scale} > 0 || $_->{scale} < 1);

        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor voltage '%s' is %s V [slot: %s]%s",
                $_->{name},
                $value,
                $_->{slotName},
                defined($self->{option_results}->{display_instances}) ? ' [instance: ' . $_->{instance} . ']' : ''
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $_->{instance}, name => $_->{slotName} . ' ' . $_->{name}, value => $value);
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Sensor voltage '%s' is %s V [slot: %s]", $_->{name}, $value, $_->{slotName})
            );
        }

        $self->{output}->perfdata_add(
            unit => 'V',
            nlabel => 'sensor.voltage.volt',
            instances => [$_->{slotName}, $_->{name}],
            value => $value,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
