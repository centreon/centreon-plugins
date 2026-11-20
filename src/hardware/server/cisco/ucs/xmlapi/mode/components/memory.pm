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

package hardware::server::cisco::ucs::xmlapi::mode::components::memory;

use strict;
use warnings;
use hardware::server::cisco::ucs::xmlapi::mode::components::resources qw(%mapping_presence %mapping_operability $thresholds);

sub load {
    my ($self) = @_;
    push @{$self->{request_classes}}, 'memoryUnit';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking memory');
    $self->{components}->{memory} = { name => 'memory modules', total => 0, skip => 0 };
    return if $self->check_filter(section => 'memory');

    foreach my $object (@{$self->{data}->{memoryUnit}}) {
        my $dn       = $object->{dn}        // 'unknown';
        my $presence = $object->{presence}  // 'unknown';
        my $state    = $object->{operState} // 'unknown';
        my $capacity = $object->{capacity}  // 'unspecified';

        # Skip slots that are truly empty (no DIMM installed)
        next if $presence eq 'empty' && $state eq 'unknown';
        next if $self->check_filter(section => 'memory', instance => $dn);
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Memory '%s' presence is '%s' [operability: %s, capacity: %s MB].",
                $dn, $presence, $state, $capacity
            )
        );

        my $presence_threshold = $self->get_severity(
            section   => 'memory.presence',
            threshold => $thresholds->{presence},
            value     => $presence
        );
        if (!$self->{output}->is_status(value => $presence_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $presence_threshold,
                short_msg => sprintf("Memory '%s' presence is '%s'.", $dn, $presence)
            );
            next;
        }

        my $state_threshold = $self->get_severity(
            section   => 'memory',
            threshold => $thresholds->{operability},
            value     => $state
        );
        if (!$self->{output}->is_status(value => $state_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $state_threshold,
                short_msg => sprintf("Memory '%s' operability is '%s'.", $dn, $state)
            );
        }
    }
}

1;
