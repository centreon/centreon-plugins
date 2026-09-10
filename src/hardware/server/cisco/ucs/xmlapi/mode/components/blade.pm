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

package hardware::server::cisco::ucs::xmlapi::mode::components::blade;

use strict;
use warnings;
use hardware::server::cisco::ucs::xmlapi::mode::components::resources qw(%mapping_presence %mapping_overall_status $thresholds);

sub load {
    my ($self) = @_;

    push @{$self->{request_classes}}, 'computeBlade';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking blades');
    $self->{components}->{blade} = { name => 'blades', total => 0, skip => 0 };
    return if $self->check_filter(section => 'blade');

    foreach my $object (@{$self->{data}->{computeBlade}}) {
        my $dn       = $object->{dn}       // 'unknown';
        my $presence = $object->{presence} // 'unknown';
        my $status   = $object->{overallStatus} // 'unknown';

        next if $self->check_filter(section => 'blade', instance => $dn);

        $self->{components}->{blade}->{total}++;

        # Check presence first
        my $presence_threshold = $self->get_severity(
            section   => 'blade.presence',
            threshold => $thresholds->{presence},
            value     => $presence
        );

        $self->{output}->output_add(
            long_msg => sprintf(
                "Blade '%s' presence is '%s' [status: %s].",
                $dn, $presence, $status
            )
        );

        if (!$self->{output}->is_status(value => $presence_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $presence_threshold,
                short_msg => sprintf("Blade '%s' presence is '%s'.", $dn, $presence)
            );
            next;
        }

        # Check overall status
        my $status_threshold = $self->get_severity(
            section   => 'blade.status',
            threshold => $thresholds->{overall_status},
            value     => $status
        );

        if (!$self->{output}->is_status(value => $status_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $status_threshold,
                short_msg => sprintf("Blade '%s' overall status is '%s'.", $dn, $status)
            );
        }
    }
}

1;
