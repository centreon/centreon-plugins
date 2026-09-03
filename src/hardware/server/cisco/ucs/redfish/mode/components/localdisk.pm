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

package hardware::server::cisco::ucs::redfish::mode::components::localdisk;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{localdisk}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking local disks');
    $self->{components}->{localdisk} = { name => 'local disks', total => 0, skip => 0 };
    return if $self->check_filter(section => 'localdisk');

    for my $drive (@{$self->{data}->{localdisk}}) {
        my $id     = $drive->{'Id'}             // 'unknown';
        my $name   = $drive->{'Name'}           // $id;
        my $health = $drive->{Status}->{Health} // 'Unknown';
        my $state  = $drive->{Status}->{State}  // 'Unknown';
        my $cap_gb = $drive->{'CapacityBytes'};
        $cap_gb    = int($cap_gb / 1024 / 1024 / 1024) if defined $cap_gb;

        next if $state =~ /^Absent$/i;  # empty bay
        next if $self->check_filter(section => 'localdisk', instance => $id);
        $self->{components}->{localdisk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Local disk '%s' health is '%s' [state: %s%s].",
                $name, $health, $state,
                defined($cap_gb) ? ", capacity: ${cap_gb} GB" : ''
            )
        );

        my $threshold = $self->get_severity(
            section   => 'localdisk',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("Local disk '%s' health is '%s'.", $name, $health)
            );
        }
    }
}

1;
