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

package network::paloalto::ssh::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach (values %{$self->{results}->{'thermal'}}) {
        foreach my $entity (@{$_->{entry}}) {
            my $instance = $entity->{description};
            next if ($self->check_filter(section => 'temperature', instance => $instance));
            $self->{components}->{temperature}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "temperature '%s' alarm is '%s' [instance: %s, value: %s C]",
                    $instance,
                    $entity->{alarm},
                    $instance,
                    $entity->{DegreesC}
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $entity->{alarm});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "temperature '%s' alarm is '%s'",
                        $instance,
                        $entity->{alarm}
                    )
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $entity->{DegreesC});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("temperature '%s' is %s C", $instance, $entity->{DegreesC})
                );
            }
            $self->{output}->perfdata_add(
                unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $instance,
                value => $entity->{DegreesC},
                warning => $warn,
                critical => $crit,
                min => $entity->{min}, max => $entity->{max}
            );
        }
    }
}

1;
