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

package network::stormshield::api::mode::components::fan;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    my ($exit, $warn, $crit, $checked);
    foreach my $label (keys %{$self->{results}}) {
        next if ($label !~ /FANS_fan_(\d+)/i);
        my $instance = 'fan' . $1;
        my $num = $1;
        next if ($self->check_filter(section => 'fan', instance => $instance));

        next if ($self->{results}->{$label}->{Status} !~ /\d+/);

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' speed is %s rpm [instance: %s]",
                $num, $self->{results}->{$label}->{Status}, $instance
            )
        );

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $self->{results}->{$label}->{Status});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' speed is '%s' rpm", $num, $self->{results}->{$label}->{Status}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm',
            unit => 'rpm',
            instances => $instance,
            value => $self->{results}->{$label}->{Status},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
