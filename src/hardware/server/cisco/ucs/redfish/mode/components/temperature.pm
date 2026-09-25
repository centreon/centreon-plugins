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

package hardware::server::cisco::ucs::redfish::mode::components::temperature;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    # Temperatures come from Chassis/Thermal.Temperatures[] — already fetched
    # by equipment.pm load_data() alongside fans. No extra request needed.
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if $self->check_filter(section => 'temperature');

    for my $sensor (@{$self->{data}->{temperature}}) {
        my $name    = $sensor->{'Name'}           // $sensor->{'MemberId'} // 'unknown';
        my $reading = $sensor->{'ReadingCelsius'};
        my $state   = $sensor->{Status}->{State} // 'Enabled';

        next unless defined $reading;
        next if $state =~ /^Absent$/i;
        next if $self->check_filter(section => 'temperature', instance => $name);
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Temperature '%s': %.1f C.", $name, $reading + 0)
        );

        # Use get_severity_numeric for user-supplied --threshold-overload,
        # but fall back to the thresholds embedded in the Redfish response.
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'temperature',
            instance => $name,
            value    => $reading + 0
        );

        if (!$checked) {
            # No user threshold defined — use Redfish embedded thresholds
            my $warn_rf = $sensor->{'UpperThresholdNonCritical'};
            my $crit_rf = $sensor->{'UpperThresholdCritical'};
            if (defined($crit_rf) && $reading >= $crit_rf) {
                $exit = 'CRITICAL';
                $crit = $crit_rf;
            } elsif (defined($warn_rf) && $reading >= $warn_rf) {
                $exit = 'WARNING';
                $warn = $warn_rf;
            } else {
                $exit = 'OK';
            }
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Temperature '%s' is %.1f C.", $name, $reading + 0)
            );
        }

        $self->{output}->perfdata_add(
            nlabel    => 'hardware.temperature.celsius',
            unit      => 'C',
            instances => $name,
            value     => sprintf('%.1f', $reading + 0),
            warning   => $warn,
            critical  => $crit,
            min       => 0,
        );
    }
}

1;
