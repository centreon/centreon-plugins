#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::components::temperature;

use strict;
use warnings;

# Single-node OIDs
my $oid_cpu_temp_single = '.1.3.6.1.4.1.11256.1.10.7.1.2'; # snsCpuTemp

# HA OIDs — structure: oid.<node_id>.<cpu_id>
my $oid_cpu_temp_ha = '.1.3.6.1.4.1.11256.1.11.12.1.2'; # snsNodeCpuTemp

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_cpu_temp_ha } if ($self->{is_ha});
    push @{$self->{request}}, { oid => $oid_cpu_temp_single };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my $use_ha  = $self->use_ha_table(oid => $oid_cpu_temp_ha);
    my $nodes   = $use_ha ? $self->{ha_nodes} : ['0'];
    my $serials = $self->{ha_serials};

    foreach my $node_id (@$nodes) {
        my $label_prefix = $use_ha ? $serials->{$node_id} . '_' : '';

        my %cpu_temps = ();
        if ($use_ha) {
            foreach my $oid (keys %{$self->{results}->{$oid_cpu_temp_ha}}) {
                next if ($oid !~ /^$oid_cpu_temp_ha\.$node_id\.(\d+)$/);
                $cpu_temps{$1} = $self->{results}->{$oid_cpu_temp_ha}->{$oid};
            }
        } else {
            foreach my $oid (keys %{$self->{results}->{$oid_cpu_temp_single}}) {
                next if ($oid !~ /^$oid_cpu_temp_single\.(\d+)$/);
                $cpu_temps{$1} = $self->{results}->{$oid_cpu_temp_single}->{$oid};
            }
        }

        my ($cpu_sum, $cpu_count) = (0, 0);
        foreach my $cpu_id (sort { $a <=> $b } keys %cpu_temps) {
            my $temp     = $cpu_temps{$cpu_id};
            my $instance = $label_prefix . 'cpu' . $cpu_id;

            # absent CPUs are reported with a 0 value
            if ($temp == 0) {
                $self->{output}->output_add(long_msg => sprintf("skipping temperature '%s': value is 0", $instance));
                next;
            }
            next if ($self->check_filter(section => 'temperature', instance => $instance));

            $self->{components}->{temperature}->{total}++;
            $cpu_sum += $temp;
            $cpu_count++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "temperature '%s' is '%s' celsius",
                    $instance, $temp
                )
            );

            my ($exit, $warn, $crit) = $self->get_severity_numeric(
                section  => 'temperature',
                instance => $instance,
                value    => $temp
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf(
                        "Temperature '%s' is '%s' celsius", $instance, $temp
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel    => 'hardware.cpu.temperature.celsius',
                unit      => 'C',
                instances => $instance,
                value     => $temp,
                warning   => $warn,
                critical  => $crit,
                min       => 0
            );
        }

        next if ($cpu_count == 0);

        $self->{output}->perfdata_add(
            nlabel    => 'hardware.cpu.average.temperature.celsius',
            unit      => 'C',
            instances => $label_prefix . 'cpu_average_temp',
            value     => int($cpu_sum / $cpu_count),
            min       => 0
        );
    }
}

1;
