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

package hardware::server::cisco::ucs::redfish::mode::components::memory;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{memory}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking memory');
    $self->{components}->{memory} = { name => 'memory modules', total => 0, skip => 0 };
    return if $self->check_filter(section => 'memory');

    for my $dimm (@{$self->{data}->{memory}}) {
        my $id       = $dimm->{'Id'}             // 'unknown';
        my $name     = $dimm->{'Name'}           // $id;
        my $health   = $dimm->{Status}->{Health} // 'Unknown';
        my $state    = $dimm->{Status}->{State}  // 'Unknown';
        my $capacity = $dimm->{'CapacityMiB'};
        my $speed    = $dimm->{'OperatingSpeedMhz'};

        next if $state =~ /^Absent$/i;  # empty DIMM slot
        next if $self->check_filter(section => 'memory', instance => $id);
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Memory '%s' health is '%s' [state: %s, capacity: %s MiB, speed: %s MHz].",
                $name, $health, $state,
                defined($capacity) ? $capacity : 'N/A',
                defined($speed)    ? $speed    : 'N/A'
            )
        );

        my $threshold = $self->get_severity(
            section   => 'memory',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("Memory '%s' health is '%s'.", $name, $health)
            );
        }
    }
}

1;
