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

package network::aruba::aoscx::restapi::mode::components::fan;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $subsystem_name (keys %{$self->{subsystems}}) {
        foreach my $endpoint (@{$self->{subsystems}->{$subsystem_name}->{fans}}) {
            my $entry = $self->{custom}->request(full_endpoint => $endpoint);
            my $instance = $subsystem_name . ':' . $entry->{name};
            next if ($self->check_filter(section => 'fan', instance => $instance));
            $self->{components}->{fan}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "fan '%s' subsystem '%s' status is %s [instance: %s, speed: %s]",
                    $entry->{name},
                    $subsystem_name,
                    $entry->{status},
                    $instance,
                    $entry->{rpm}
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'fan', value => $entry->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "fan '%s' subsystem '%s' status is %s",
                        $entry->{name}, $subsystem_name, $entry->{status}
                    )
                );
            }
            
            next if (!defined($entry->{rpm}));

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $entry->{rpm});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "fan '%s' subsystem '%s' speed is %s rpm",
                        $entry->{name},
                        $subsystem_name,
                        $entry->{rpm}
                    )
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.fan.speed.rpm',
                unit => 'rpm',
                instances => [$subsystem_name, $entry->{name}],
                value => $entry->{rpm},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
