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

# Copyright 2024 Centreon (http://www.centreon.com/)
# Licensed under the Apache License, Version 2.0

package hardware::server::cisco::ucs::xmlapi::mode::components::fan;

use strict;
use warnings;
use hardware::server::cisco::ucs::xmlapi::mode::components::resources qw(%mapping_presence %mapping_operability $thresholds);

sub load {
    my ($self) = @_;
    push @{$self->{request_classes}}, 'equipmentFan';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if $self->check_filter(section => 'fan');

    foreach my $object (@{$self->{data}->{equipmentFan}}) {
        my $dn       = $object->{dn}        // 'unknown';
        my $presence = $object->{presence}  // 'unknown';
        my $state    = $object->{operState} // 'unknown';

        next if $self->check_filter(section => 'fan', instance => $dn);
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Fan '%s' presence is '%s' [operability: %s].", $dn, $presence, $state)
        );

        my $presence_threshold = $self->get_severity(
            section   => 'fan.presence',
            threshold => $thresholds->{presence},
            value     => $presence
        );
        if (!$self->{output}->is_status(value => $presence_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $presence_threshold,
                short_msg => sprintf("Fan '%s' presence is '%s'.", $dn, $presence)
            );
            next;
        }

        my $state_threshold = $self->get_severity(
            section   => 'fan',
            threshold => $thresholds->{operability},
            value     => $state
        );
        if (!$self->{output}->is_status(value => $state_threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $state_threshold,
                short_msg => sprintf("Fan '%s' operability is '%s'.", $dn, $state)
            );
        }
    }
}

1;
