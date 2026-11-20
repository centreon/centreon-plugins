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

package hardware::server::cisco::ucs::xmlapi::mode::components::localdisk;

use strict;
use warnings;
use hardware::server::cisco::ucs::xmlapi::mode::components::resources qw(%mapping_presence %mapping_drive_status $thresholds);

sub load {
    my ($self) = @_;
    push @{$self->{request_classes}}, 'storageLocalDisk';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking local disks');
    $self->{components}->{localdisk} = { name => 'local disks', total => 0, skip => 0 };
    return if $self->check_filter(section => 'localdisk');

    foreach my $object (@{$self->{data}->{storageLocalDisk}}) {
        my $dn       = $object->{dn}          // 'unknown';
        my $presence = $object->{presence}    // 'unknown';
        my $status   = $object->{diskState}   // 'unknown';

        next if $self->check_filter(section => 'localdisk', instance => $dn);
        $self->{components}->{localdisk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Local disk '%s' presence is '%s' [disk state: %s].", $dn, $presence, $status)
        );

        my $presence_threshold = $self->get_severity(
            section   => 'localdisk.presence',
            threshold => $thresholds->{presence},
            value     => $presence
        );
        if (!$self->{output}->is_status(value => $presence_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $presence_threshold,
                short_msg => sprintf("Local disk '%s' presence is '%s'.", $dn, $presence)
            );
            next;
        }

        my $status_threshold = $self->get_severity(
            section   => 'localdisk',
            threshold => $thresholds->{drive_status},
            value     => $status
        );
        if (!$self->{output}->is_status(value => $status_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $status_threshold,
                short_msg => sprintf("Local disk '%s' disk state is '%s'.", $dn, $status)
            );
        }
    }
}

1;
