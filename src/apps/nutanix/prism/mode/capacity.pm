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

package apps::nutanix::prism::mode::capacity;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

# Aggregates cluster-wide CPU, RAM, and storage capacity
# by consolidating data from all hosts and storage pools.

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu',     type => 0, message_separator => ' - ' },
        { name => 'memory',  type => 0, message_separator => ' - ' },
        { name => 'storage', type => 0, message_separator => ' - ' },
    ];

    # CPU (allocated vCPUs vs physical core capacity)
    $self->{maps_counters}->{cpu} = [
        {
            label  => 'cpu-capacity',
            nlabel => 'cluster.cpu.capacity.count',
            set    => {
                key_values      => [ { name => 'total_cores' } ],
                output_template => 'CPU capacity: %d physical cores',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'cpu-allocated',
            nlabel => 'cluster.cpu.allocated.count',
            set    => {
                key_values      => [ { name => 'allocated_vcpus' } ],
                output_template => 'vCPUs allocated: %d',
                perfdatas       => [ { template => '%d', min => 0 } ],
            }
        },
        {
            label  => 'cpu-usage-prct',
            nlabel => 'cluster.cpu.usage.percentage',
            set    => {
                key_values      => [ { name => 'cpu_usage_pct' } ],
                output_template => 'CPU usage: %.2f%%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ],
            }
        },
    ];

    # Memory (bytes)
    $self->{maps_counters}->{memory} = [
        {
            label  => 'memory-capacity',
            nlabel => 'cluster.memory.capacity.bytes',
            set    => {
                key_values          => [ { name => 'memory_total_bytes' } ],
                output_template     => 'memory capacity: %s',
                output_change_bytes => 1,
                perfdatas           => [ { template => '%d', unit => 'B', min => 0 } ],
            }
        },
        {
            label  => 'memory-used',
            nlabel => 'cluster.memory.used.bytes',
            set    => {
                key_values          => [ { name => 'memory_used_bytes' } ],
                output_template     => 'memory used: %s',
                output_change_bytes => 1,
                perfdatas           => [ { template => '%d', unit => 'B', min => 0 } ],
            }
        },
        {
            label  => 'memory-usage-prct',
            nlabel => 'cluster.memory.usage.percentage',
            set    => {
                key_values      => [ { name => 'memory_usage_pct' } ],
                output_template => 'memory usage: %.2f%%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ],
            }
        },
    ];

    # Storage (bytes)
    $self->{maps_counters}->{storage} = [
        {
            label  => 'storage-capacity',
            nlabel => 'cluster.storage.capacity.bytes',
            set    => {
                key_values          => [ { name => 'storage_total_bytes' } ],
                output_template     => 'storage capacity: %s',
                output_change_bytes => 1,
                perfdatas           => [ { template => '%d', unit => 'B', min => 0 } ],
            }
        },
        {
            label  => 'storage-used',
            nlabel => 'cluster.storage.used.bytes',
            set    => {
                key_values          => [ { name => 'storage_used_bytes' } ],
                output_template     => 'storage used: %s',
                output_change_bytes => 1,
                perfdatas           => [ { template => '%d', unit => 'B', min => 0 } ],
            }
        },
        {
            label  => 'storage-usage-prct',
            nlabel => 'cluster.storage.usage.percentage',
            set    => {
                key_values      => [ { name => 'storage_usage_pct' } ],
                output_template => 'storage usage: %.2f%%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ],
            }
        },
        {
            label  => 'storage-free',
            nlabel => 'cluster.storage.free.bytes',
            set    => {
                key_values          => [ { name => 'storage_free_bytes' } ],
                output_template     => 'storage free: %s',
                output_change_bytes => 1,
                perfdatas           => [ { template => '%d', unit => 'B', min => 0 } ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Aggregate CPU and RAM data from all hosts
    my $hosts_result = $options{custom}->get_hosts();
    my $hosts        = $hosts_result->{entities} // [];

    my ($total_cores, $allocated_vcpus) = (0, 0);
    my ($mem_total, $mem_used_sum, $cpu_usage_sum) = (0, 0, 0);
    my $host_count = scalar(@{$hosts});

    for my $host (@{$hosts}) {
        $total_cores     += $host->{num_cpu_cores}           // 0;
        # num_cpu_threads is the best available proxy for allocated vCPU count in v2.0
        $allocated_vcpus += $host->{num_cpu_threads}          // 0;
        $mem_total       += $host->{memory_capacity_in_bytes} // 0;

        my $stats   = $host->{stats} // {};
        # CPU: PPM (parts per million) → percentage
        my $cpu_ppm = $stats->{hypervisor_cpu_usage_ppm}    // 0;
        $cpu_usage_sum += $cpu_ppm / 10000;

        # Memory used = capacity × (usage_ppm / 1_000_000)
        my $mem_ppm = $stats->{hypervisor_memory_usage_ppm} // 0;
        $mem_used_sum += ($host->{memory_capacity_in_bytes} // 0) * ($mem_ppm / 1_000_000);
    }

    my $cpu_usage_avg = ($host_count > 0) ? ($cpu_usage_sum / $host_count) : 0;
    my $mem_usage_pct = ($mem_total > 0)  ? ($mem_used_sum / $mem_total * 100) : 0;

    $self->{cpu} = {
        total_cores     => $total_cores,
        allocated_vcpus => $allocated_vcpus,
        cpu_usage_pct   => $cpu_usage_avg,
    };
    $self->{memory} = {
        memory_total_bytes => $mem_total,
        memory_used_bytes  => $mem_used_sum,
        memory_usage_pct   => $mem_usage_pct,
    };

    # Aggregate storage data from all storage pools
    my $pools_result    = $options{custom}->get_storage_pools();
    my $pools           = $pools_result->{entities} // [];

    my ($storage_total, $storage_used) = (0, 0);
    for my $pool (@{$pools}) {
        $storage_total += $pool->{capacity_bytes} // 0;
        $storage_used  += $pool->{usage_bytes}    // 0;
    }
    my $storage_free    = $storage_total - $storage_used;
    $storage_free       = 0 if $storage_free < 0;
    my $storage_pct     = ($storage_total > 0) ? ($storage_used / $storage_total * 100) : 0;

    $self->{storage} = {
        storage_total_bytes => $storage_total,
        storage_used_bytes  => $storage_used,
        storage_free_bytes  => $storage_free,
        storage_usage_pct   => $storage_pct,
    };
}

1;

__END__

=head1 MODE

Monitor Nutanix cluster capacity (CPU, memory, storage) through Prism REST API.

Data is aggregated from all AHV hosts (CPU/RAM) and all storage pools (storage).
Two API calls are made: C</api/nutanix/v2.0/hosts> and C</api/nutanix/v2.0/storage_pools>.

=over 8

=item B<--warning-cpu-usage-prct>

Warning threshold for cluster-wide CPU usage (%).

=item B<--critical-cpu-usage-prct>

Critical threshold for cluster-wide CPU usage (%). Example: C<--critical-cpu-usage-prct=85>

=item B<--warning-memory-usage-prct>

Warning threshold for memory usage (%).

=item B<--critical-memory-usage-prct>

Critical threshold for memory usage (%). Example: C<--critical-memory-usage-prct=90>

=item B<--warning-storage-usage-prct>

Warning threshold for storage usage (%).

=item B<--critical-storage-usage-prct>

Critical threshold for storage usage (%). Example: C<--critical-storage-usage-prct=85>

=item B<--warning-storage-free>

Warning threshold for free storage space (bytes).

=item B<--critical-storage-free>

Critical threshold for free storage space (bytes).

=item B<--warning-cpu-capacity>

Warning threshold for total physical core count.

=item B<--critical-cpu-capacity>

Critical threshold for total physical core count.

=back

=cut
