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

package network::paloalto::ssh::mode::components::voltage;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage'));

    foreach (values %{$self->{results}->{power}}) {
        foreach my $entity (@{$_->{entry}}) {
            my $instance = $entity->{description};
            next if ($self->check_filter(section => 'voltage', instance => $instance));
            $self->{components}->{voltage}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "voltage '%s' alarm is '%s' [instance: %s, value: %s V]",
                    $instance,
                    $entity->{alarm},
                    $instance,
                    $entity->{Volts}
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $entity->{alarm});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "voltage '%s' alarm is '%s'",
                        $instance,
                        $entity->{alarm}
                    )
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $entity->{Volts});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("voltage '%s' is %s V", $instance, $entity->{Volts})
                );
            }
            $self->{output}->perfdata_add(
                unit => 'V',
                nlabel => 'hardware.voltage.volt',
                instances => $instance,
                value => $entity->{Volts},
                warning => $warn,
                critical => $crit,
                min => $entity->{min}, max => $entity->{max}
            );
        }
    }
}

1;
