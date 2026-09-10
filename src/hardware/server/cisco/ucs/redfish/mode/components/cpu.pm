#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::redfish::mode::components::cpu;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{cpu}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking CPUs');
    $self->{components}->{cpu} = { name => 'cpus', total => 0, skip => 0 };
    return if $self->check_filter(section => 'cpu');

    for my $cpu (@{$self->{data}->{cpu}}) {
        my $id     = $cpu->{'Id'}     // 'unknown';
        my $socket = $cpu->{'Socket'} // $id;
        my $model  = $cpu->{'Model'}  // 'unknown';
        my $health = $cpu->{Status}->{Health} // 'Unknown';
        my $state  = $cpu->{Status}->{State}  // 'Unknown';

        next if $state =~ /^Absent$/i;  # empty socket
        next if $self->check_filter(section => 'cpu', instance => $socket);
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "CPU '%s' (%s) health is '%s' [state: %s].",
                $socket, $model, $health, $state
            )
        );

        my $threshold = $self->get_severity(
            section   => 'cpu',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("CPU '%s' health is '%s'.", $socket, $health)
            );
        }
    }
}

1;
