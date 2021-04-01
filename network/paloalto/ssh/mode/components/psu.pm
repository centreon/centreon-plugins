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

package network::paloalto::ssh::mode::components::psu;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach (values %{$self->{results}->{'power-supply'}}) {
        foreach my $entity (@{$_->{entry}}) {
            my $instance = $entity->{description};
            next if ($self->check_filter(section => 'psu', instance => $instance));
            $self->{components}->{psu}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s' alarm is '%s' [instance: %s]",
                    $instance,
                    $entity->{alarm},
                    $instance
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'psu', value => $entity->{alarm});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "power supply '%s' alarm is '%s'",
                        $instance,
                        $entity->{alarm}
                    )
                );
            }
        }
    }
}

1;
