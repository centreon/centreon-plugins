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

package storage::hp::storeonce::4::restapi::mode::components::fan;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fan', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $entry (@{$self->{subsystems}->{fan}}) {
        my $instance = $entry->{name};
        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [speed: %s]",
                $entry->{name},
                $entry->{status},
                $entry->{speed}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $entry->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $entry->{name}, $entry->{status}
                )
            );
        }
        
        next if (!defined($entry->{speed}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $entry->{speed});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "fan '%s' '%s' speed is %s rpm",
                    $entry->{name},
                    $entry->{speed}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm',
            unit => 'rpm',
            instances => $entry->{name},
            value => $entry->{speed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
