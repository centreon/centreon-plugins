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

package hardware::devices::cisco::ces::restapi::mode::components::aoc;

use strict;
use warnings;

sub check_aoc {
    my ($self, %options) = @_;

    foreach (@{$options{entry}->{ $options{element} }}) {
        my $instance = $options{element} . ':' . $_->{item};

        next if (!defined($_->{ConnectionStatus}) && !defined($_->{DelayMs}));

        next if ($self->check_filter(section => 'aoc', instance => $instance));
        $self->{components}->{aoc}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "audio output connector '%s' connection status is '%s' [instance: %s, delay: %s ms]",
                $instance,
                defined($_->{ConnectionStatus}) ? $_->{ConnectionStatus} : 'n/a',
                $instance,
                defined($_->{DelayMs}) ? $_->{DelayMs} : '-'
            )
        );

        if (defined($_->{ConnectionStatus})) {
            my $exit = $self->get_severity(label => 'connection_status', section => 'aoc.status', value => $_->{ConnectionStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("audio output connector '%s' connection status is '%s'", $instance, $_->{ConnectionStatus})
                );
            }
        }

        if (defined($_->{DelayMs})) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'aocdelay', instance => $instance, value => $_->{DelayMs});

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "audio output connector '%s' delay is %s ms",
                        $instance, $_->{EcReferenceDelay}
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => 'ms',
                nlabel => 'component.audio.output.connector.delay.milliseconds',
                instances => [$options{element}, $_->{item}],
                value => $_->{DelayMs},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking audio output connectors');
    $self->{components}->{aoc} = { name => 'audio output connectors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'aoc'));

    # since CE 9.4
    check_aoc(
        $self,
        entry => $self->{results}->{Audio}->{Output}->{Connectors},
        element => 'HDMI',
        instance => 'item'
    );
    # since CE 9.4
    check_aoc(
        $self,
        entry => $self->{results}->{Audio}->{Output}->{Connectors},
        element => 'InternalSpeaker',
        instance => 'item'
    );
    # since CE 8.1
    check_aoc(
        $self,
        entry => $self->{results}->{Audio}->{Output}->{Connectors},
        element => 'Line',
        instance => 'item'
    );
}

1;
