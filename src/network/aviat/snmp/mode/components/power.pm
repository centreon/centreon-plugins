#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::aviat::snmp::mode::components::power;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking power");
    $self->{components}->{power} = { name => 'power', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'power'));

    foreach (@{$self->{perfs}}) {
        next if ($_->{unit} !~ /^dB/i);
        
        next if ($self->check_filter(section => 'power', instance => $_->{instance}, name => $_->{slotName} . ' ' . $_->{name}));
        $self->{components}->{power}->{total}++;

        my $value = $_->{reading};
        $value /= $_->{scale} if ($_->{scale} > 0 || $_->{scale} < 1);

        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor power '%s' is %s %s [slot: %s]%s",
                $_->{name},
                $value,
                $_->{unit},
                $_->{slotName},
                defined($self->{option_results}->{display_instances}) ? ' [instance: ' . $_->{instance} . ']' : ''
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'power', instance => $_->{instance}, name => $_->{slotName} . ' ' . $_->{name}, value => $value);
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Sensor power '%s' is %s %s [slot: %s]", $_->{name}, $value, $_->{unit}, $_->{slotName})
            );
        }

        $self->{output}->perfdata_add(
            unit => $_->{unit},
            nlabel => 'sensor.power.' . $_->{unit},
            instances => [$_->{slotName}, $_->{name}],
            value => $value,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
