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

package hardware::server::cisco::ucs::xmlapi::mode::components::temperature;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    push @{$self->{request_classes}}, 'processorEnvStats', 'computeMbTempStats';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if $self->check_filter(section => 'temperature');

    # --- CPU temperatures ---
    for my $stat (@{$self->{data}->{processorEnvStats}}) {
        my $dn   = $stat->{dn}          // '';
        my $temp = $stat->{temperature} // '';

        next if $temp eq '' || $temp =~ /^not-applicable$/i || $temp !~ /^[\d.]+$/;

        (my $display = $dn) =~ s{/env-stats$}{};
        $display =~ s{sys/}{};
        $display =~ s{/board}{};

        next if $self->check_filter(section => 'temperature', instance => $display);
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Temperature '%s' (cpu): %.1f C.", $display, $temp + 0)
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'temperature',
            instance => $display,
            value    => $temp + 0
        );

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Temperature '%s' is %.1f C.", $display, $temp + 0)
            );
        }

        $self->{output}->perfdata_add(
            nlabel    => 'hardware.temperature.celsius',
            unit      => 'C',
            instances => $display,
            value     => sprintf('%.1f', $temp + 0),
            warning   => $warn,
            critical  => $crit,
            min       => 0,
        );
    }

    # --- Motherboard temperatures (ambient / front / rear) ---
    for my $stat (@{$self->{data}->{computeMbTempStats}}) {
        my $dn = $stat->{dn} // '';
        (my $base = $dn) =~ s{/mb/temp-stats$}{};
        $base =~ s{sys/}{};
        $base =~ s{/board}{};

        for my $field (
            [ 'ambientTemp', 'ambient' ],
            [ 'frontTemp',   'front'   ],
            [ 'rearTemp',    'rear'    ],
        ) {
            my ($attr, $label) = @{$field};
            my $temp = $stat->{$attr} // '';
            next if $temp eq '' || $temp =~ /^not-applicable$/i || $temp !~ /^[\d.]+$/;

            my $display = "${base}/mb-${label}";

            next if $self->check_filter(section => 'temperature', instance => $display);
            $self->{components}->{temperature}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf("Temperature '%s' (motherboard): %.1f C.", $display, $temp + 0)
            );

            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section  => 'temperature',
                instance => $display,
                value    => $temp + 0
            );

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf("Temperature '%s' is %.1f C.", $display, $temp + 0)
                );
            }

            $self->{output}->perfdata_add(
                nlabel    => 'hardware.temperature.celsius',
                unit      => 'C',
                instances => $display,
                value     => sprintf('%.1f', $temp + 0),
                warning   => $warn,
                critical  => $crit,
                min       => 0,
            );
        }
    }
}

1;
