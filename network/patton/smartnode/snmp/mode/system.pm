#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package network::patton::smartnode::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;
    return "CPU '".$options{instance_value}->{display}."' ";
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    return "Memory pool '".$options{instance_value}->{display}."' ";
}

sub prefix_temperature_output {
    my ($self, %options) = @_;
    return "Temperature probe '".$options{instance_value}->{display}."' ";
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_total_bytes});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_allocated_bytes});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_free_bytes});
    return sprintf(
        'memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{memory_allocated_percent},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{memory_free_percent}
    );
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' },
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' },
        { name => 'temperature', type => 1, cb_prefix_output => 'prefix_temperature_output', message_multiple => 'All temperatures are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-workload-current', nlabel => 'cpu.workload.current', set => {
                key_values => [ { name => 'cpu_workload_current' }, { name => 'display' } ],
                output_template => 'cpu workload: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cpu-workload-1m', nlabel => 'cpu.workload.1m', set => {
                key_values => [ { name => 'cpu_workload_1m' }, { name => 'display' } ],
                output_template => 'cpu workload 1 minute average: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cpu-workload-5m', nlabel => 'cpu.workload.5m', set => {
                key_values => [ { name => 'cpu_workload_5m' }, { name => 'display' } ],
                output_template => 'cpu workload 5 minutes average: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-allocated-bytes', nlabel => 'memory.allocated.bytes', set => {
                key_values => [ { name => 'memory_allocated_bytes' }, { name => 'memory_free_bytes' }, { name => 'memory_allocated_percent' }, { name => 'memory_free_percent' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'memory_total_bytes', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-free-bytes', nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'memory_free_bytes' }, { name => 'memory_allocated_bytes' }, { name => 'memory_allocated_percent' }, { name => 'memory_free_percent' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'memory_total_bytes', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-allocated-percentage', nlabel => 'memory.allocated.percentage', display_ok => 0, set => {
                key_values => [ { name => 'memory_allocated_percent' }, { name => 'memory_allocated_bytes' }, { name => 'memory_free_bytes' }, { name => 'memory_free_percent' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'temperature-current-celsius', nlabel => 'temperature.current.celsius', set => {
                key_values => [ { name => 'temperature_current_celsius' }, { name => 'display' } ],
                output_template => 'temperature probe: %.2f C',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => 'C', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $cpuEntry_oid = '.1.3.6.1.4.1.1768.100.70.10.2.1';
my $cpuDescr_oid = '.1.3.6.1.4.1.1768.100.70.10.2.1.1';
my $cpuWorkloadCurrent_oid = '.1.3.6.1.4.1.1768.100.70.10.2.1.2';
my $cpuWorkload1MinuteAverage_oid = '.1.3.6.1.4.1.1768.100.70.10.2.1.3';
my $cpuWorkload5MinuteAverage_oid = '.1.3.6.1.4.1.1768.100.70.10.2.1.4';

my $memoryPoolEntry_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1';
my $memDescr_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.1';
my $memTotalBytes_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.2';
my $memAllocatedBytes_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.3';
my $memFreeBytes_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.4';
my $memLargestFreeBlock_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.5';
my $memAllocatedBlocks_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.6';
my $memFreeBlocks_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1.7';

my $tempProbeEntry_oid = '.1.3.6.1.4.1.1768.100.70.30.2.1';
my $tempProbeDescr_oid = '.1.3.6.1.4.1.1768.100.70.30.2.1.1';
my $currentDegreesCelsius_oid = '.1.3.6.1.4.1.1768.100.70.30.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_results = $options{snmp}->get_multiple_table(oids => [
        { oid => $cpuEntry_oid },
        { oid => $memoryPoolEntry_oid },
        { oid => $tempProbeEntry_oid }
    ], nothing_quit => 1);

    my $cpuEntry = $snmp_results->{$cpuEntry_oid};
    my $numCpu = 1;
    $self->{cpu} = {};
    while ($cpuEntry->{$cpuDescr_oid.".".$numCpu}) {
        my $cpuObj = $self->{cpu}->{ $cpuEntry->{$cpuDescr_oid.".".$numCpu} } = {};
        $cpuObj->{display} = $cpuEntry->{$cpuDescr_oid.".".$numCpu};
        $cpuObj->{cpu_workload_current} = $cpuEntry->{$cpuWorkloadCurrent_oid.".".$numCpu};
        $cpuObj->{cpu_workload_1m} = $cpuEntry->{$cpuWorkload1MinuteAverage_oid.".".$numCpu};
        $cpuObj->{cpu_workload_5m} = $cpuEntry->{$cpuWorkload5MinuteAverage_oid.".".$numCpu};
        $numCpu++;
    }

    my $memoryPoolEntry = $snmp_results->{$memoryPoolEntry_oid};
    my $numMem = 1;
    $self->{memory} = {};
    while ($memoryPoolEntry->{$memDescr_oid.".".$numMem}) {
        my $memoryObj = $self->{memory}->{ $memoryPoolEntry->{$memDescr_oid.".".$numMem} } = {};
        $memoryObj->{display} = $memoryPoolEntry->{$memDescr_oid.".".$numMem};
        $memoryObj->{memory_total_bytes} = $memoryPoolEntry->{$memTotalBytes_oid.".".$numMem};
        $memoryObj->{memory_allocated_bytes} = $memoryPoolEntry->{$memAllocatedBytes_oid.".".$numMem};
        $memoryObj->{memory_free_bytes} = $memoryPoolEntry->{$memFreeBytes_oid.".".$numMem};
        if ($memoryObj->{memory_total_bytes} > 0) {
            $memoryObj->{memory_allocated_percent} = $memoryObj->{memory_allocated_bytes} * 100 / $memoryObj->{memory_total_bytes};
            $memoryObj->{memory_free_percent} = $memoryObj->{memory_free_bytes} * 100 / $memoryObj->{memory_total_bytes};
        } else {
            $memoryObj->{memory_allocated_percent} = 0;
            $memoryObj->{memory_free_percent} = 0;
        }
        $numMem++;
    }

    my $tempProbeEntry = $snmp_results->{$tempProbeEntry_oid};
    my $numTemp = 1;
    $self->{temperature} = {};
    while ($tempProbeEntry->{$tempProbeDescr_oid.".".$numTemp}) {
        my $temperatureObj = $self->{temperature}->{ $tempProbeEntry->{$tempProbeDescr_oid.".".$numTemp} } = {};
        $temperatureObj->{display} = $tempProbeEntry->{$tempProbeDescr_oid.".".$numTemp};
        $temperatureObj->{temperature_current_celsius} = $tempProbeEntry->{$currentDegreesCelsius_oid.".".$numTemp};
        $numTemp++;
    }
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu-workload-current$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-workload-current' (%), 'cpu-workload-1m' (%), 'cpu-workload-5m' (%), 'memory-allocated-bytes',
'memory-free-bytes', 'memory-allocated-percentage', 'temperature-current-celsius'.

=back

=cut
