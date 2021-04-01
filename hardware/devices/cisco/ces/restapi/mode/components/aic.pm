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

package hardware::devices::cisco::ces::restapi::mode::components::aic;

use strict;
use warnings;

#<Connectors item="1">
#    <Microphone item="1">
#        <EcReferenceDelay item="1">0</EcReferenceDelay>
#    </Microphone>
#    <Microphone item="2">
#        <EcReferenceDelay item="1">0</EcReferenceDelay>
#    </Microphone>
#</Connectors>

sub check_aic {
    my ($self, %options) = @_;

    foreach (@{$options{entry}->{ $options{element} }}) {
        my $instance = $options{element} . ':' . $_->{item};

        my $ec_reference_delay = ref($_->{EcReferenceDelay}) eq 'HASH' ? $_->{EcReferenceDelay}->{content} : $_->{EcReferenceDelay};
        next if (!defined($_->{ConnectionStatus}) && !defined($ec_reference_delay));

        next if ($self->check_filter(section => 'aic', instance => $instance));
        $self->{components}->{aic}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "audio input connector '%s' connection status is '%s' [instance: %s, latency: %s ms]",
                $instance,
                defined($_->{ConnectionStatus}) ? $_->{ConnectionStatus} : 'n/a',
                $instance,
                defined($ec_reference_delay) ? $ec_reference_delay : '-'
            )
        );

        if (defined($_->{ConnectionStatus})) {
            my $exit = $self->get_severity(label => 'connection_status', section => 'aic.status', value => $_->{ConnectionStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("audio input connector '%s' connection status is '%s'", $instance, $_->{ConnectionStatus})
                );
            }
        }

        if (defined($ec_reference_delay)) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'aiclatency', instance => $instance, value => $ec_reference_delay);

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "audio input connector '%s' latency is %s ms",
                        $instance, $ec_reference_delay
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => 'ms',
                nlabel => 'component.audio.input.connector.latency.milliseconds',
                instances => [$options{element}, $_->{item}],
                value => $ec_reference_delay,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking audio input connectors');
    $self->{components}->{aic} = { name => 'audio input connectors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'aic'));

    check_aic(
        $self,
        entry => $self->{results}->{Audio}->{Input}->{Connectors},
        element => 'Microphone',
        instance => 'item'
    );
    check_aic(
        $self,
        entry => $self->{results}->{Audio}->{Input}->{Connectors},
        element => 'HDMI',
        instance => 'item'
    );
}

1;
