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

    if ($self->{is_ha}) {
        push @{$self->{request}}, { oid => $oid_cpu_temp_ha };
    } else {
        push @{$self->{request}}, { oid => $oid_cpu_temp_single };
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my $nodes   = $self->{is_ha} ? $self->{ha_nodes} : ['0'];
    my $serials = $self->{ha_serials};

    foreach my $node_id (@$nodes) {
        my $label_prefix = $self->{is_ha} ? $serials->{$node_id} . '_' : '';

        my @cpu_ids   = ();
        my %cpu_temps = ();

        if ($self->{is_ha}) {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpu_temp_ha}})) {
                next if ($oid !~ /^$oid_cpu_temp_ha\.$node_id\.(\d+)$/);
                my $cpu_id = $1;
                push @cpu_ids, $cpu_id;
                $cpu_temps{$cpu_id} = $self->{results}->{$oid_cpu_temp_ha}->{$oid};
                $self->{components}->{temperature}->{total}++;
            }
        } else {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpu_temp_single}})) {
                next if ($oid !~ /^$oid_cpu_temp_single\.(\d+)$/);
                my $cpu_id = $1;
                push @cpu_ids, $cpu_id;
                $cpu_temps{$cpu_id} = $self->{results}->{$oid_cpu_temp_single}->{$oid};
                $self->{components}->{temperature}->{total}++;
            }
        }

        next if (scalar @cpu_ids == 0);
        @cpu_ids = sort { $a <=> $b } @cpu_ids;

        my $cpu_sum = 0;
        foreach my $cpu_id (@cpu_ids) {
            my $temp     = $cpu_temps{$cpu_id};
            my $instance = $label_prefix . 'cpu' . $cpu_id;

            next if ($self->check_filter(section => 'temperature', instance => $instance));

            $cpu_sum += $temp;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "temperature '%s' is '%s' celsius",
                    $instance, $temp
                )
            );

            $self->{output}->perfdata_add(
                nlabel    => 'hardware.cpu.temperature.celsius',
                unit      => 'C',
                instances => $instance,
                value     => $temp,
                min       => 0
            );

            my ($exit) = $self->get_severity_numeric(
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
        }

        my $cpu_avg      = int($cpu_sum / scalar(@cpu_ids));
        my $avg_instance = $label_prefix . 'cpu_average_temp';

        $self->{output}->perfdata_add(
            nlabel    => 'hardware.cpu.average.temperature.celsius',
            unit      => 'C',
            instances => $avg_instance,
            value     => $cpu_avg,
            min       => 0
        );
    }
}

1;
