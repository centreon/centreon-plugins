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

package hardware::server::cisco::ucs::redfish::mode::components::psu;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{psu}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking PSUs');
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if $self->check_filter(section => 'psu');

    for my $psu (@{$self->{data}->{psu}}) {
        my $name   = $psu->{'Name'} // $psu->{'MemberId'} // 'unknown';
        my $health = $psu->{Status}->{Health} // 'Unknown';
        my $state  = $psu->{Status}->{State}  // 'Unknown';
        my $out_w  = $psu->{'PowerOutputWatts'} // $psu->{'LastPowerOutputWatts'};

        next if $state =~ /^Absent$/i;
        next if $self->check_filter(section => 'psu', instance => $name);
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("PSU '%s' health is '%s' [state: %s].", $name, $health, $state)
        );

        if (defined $out_w) {
            $self->{output}->perfdata_add(
                nlabel    => 'hardware.psu.power.watt',
                unit      => 'W',
                instances => $name,
                value     => $out_w,
                min       => 0,
            );
        }

        my $threshold = $self->get_severity(
            section   => 'psu',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("PSU '%s' health is '%s'.", $name, $health)
            );
        }
    }
}

1;
