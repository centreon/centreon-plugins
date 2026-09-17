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

package hardware::server::cisco::ucs::redfish::mode::components::fan;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{fan}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if $self->check_filter(section => 'fan');

    for my $fan (@{$self->{data}->{fan}}) {
        my $name    = $fan->{'FanName'} // $fan->{'Name'} // $fan->{'MemberId'} // 'unknown';
        my $health  = $fan->{Status}->{Health} // 'Unknown';
        my $state   = $fan->{Status}->{State}  // 'Unknown';
        my $reading = $fan->{'Reading'};
        my $units   = $fan->{'ReadingUnits'} // 'RPM';

        next if $state =~ /^Absent$/i;
        next if $self->check_filter(section => 'fan', instance => $name);
        $self->{components}->{fan}->{total}++;

        my $long_msg = sprintf("Fan '%s' health is '%s' [state: %s]", $name, $health, $state);
        $long_msg .= sprintf(" [reading: %s %s]", $reading, $units) if defined $reading;
        $self->{output}->output_add(long_msg => $long_msg . '.');

        if (defined $reading) {
            $self->{output}->perfdata_add(
                nlabel    => 'hardware.fan.speed.' . lc($units),
                unit      => lc($units),
                instances => $name,
                value     => $reading,
                min       => 0,
            );
        }

        my $threshold = $self->get_severity(
            section   => 'fan',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("Fan '%s' health is '%s'.", $name, $health)
            );
        }
    }
}

1;
