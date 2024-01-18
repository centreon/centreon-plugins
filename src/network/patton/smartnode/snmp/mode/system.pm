#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    if ($self->{cpu_average}->{count} > 0) {
        return $self->{cpu_average}->{count} . ' CPU(s) average usage is ';
    }
    return 'CPU(s) average usage is ';
}

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
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_usage_bytes});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_free_bytes});

    return sprintf(
        'memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{memory_usage_percentage},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{memory_free_percentage}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_average', type => 0, cb_prefix_output => 'prefix_cpu_avg_output' },
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPU usages are ok' },
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' },
        { name => 'temperature', type => 1, cb_prefix_output => 'prefix_temperature_output', message_multiple => 'All temperatures are ok' }
    ];

    $self->{maps_counters}->{cpu_average} = [
        { label => 'cpu-average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'average' }, { name => 'count' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'core-cpu-utilization', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_utilization_current_percentage' }, { name => 'display' } ],
                output_template => 'cpu workload: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'core-cpu-utilization-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_utilization_1m_percentage' }, { name => 'display' } ],
                output_template => 'cpu workload 1 minute average: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'core-cpu-utilization-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_utilization_5m_percentage' }, { name => 'display' } ],
                output_template => 'cpu workload 5 minutes average: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'memory_usage_bytes' }, { name => 'memory_free_bytes' }, { name => 'memory_usage_percentage' }, { name => 'memory_free_percentage' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'memory_total_bytes', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'memory_free_bytes' }, { name => 'memory_usage_bytes' }, { name => 'memory_usage_percentage' }, { name => 'memory_free_percentage' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'memory_total_bytes', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'memory_usage_percentage' }, { name => 'memory_usage_bytes' }, { name => 'memory_free_bytes' }, { name => 'memory_free_percentage' }, { name => 'memory_total_bytes' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'probe-temperature', nlabel => 'probe.temperature.celsius', set => {
                key_values => [ { name => 'probe_temperature_celsius' }, { name => 'display' } ],
                output_template => 'probe temperature: %.2f C',
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
my $mappingCpu = {
    display => { oid => '.1.3.6.1.4.1.1768.100.70.10.2.1.1' }, # cpuDescr
    cpu_utilization_current_percentage => { oid => '.1.3.6.1.4.1.1768.100.70.10.2.1.2' }, # cpuWorkloadCurrent
    cpu_utilization_1m_percentage => { oid => '.1.3.6.1.4.1.1768.100.70.10.2.1.3' }, # cpuWorkload1MinuteAverage
    cpu_utilization_5m_percentage => { oid => '.1.3.6.1.4.1.1768.100.70.10.2.1.4' } # cpuWorkload5MinuteAverage
};

my $memoryPoolEntry_oid = '.1.3.6.1.4.1.1768.100.70.20.2.1';
my $mappingMemory = {
    display => { oid => '.1.3.6.1.4.1.1768.100.70.20.2.1.1' }, # memDescr
    memory_total_bytes => { oid => '.1.3.6.1.4.1.1768.100.70.20.2.1.2' }, # memTotalBytes
    memory_usage_bytes => { oid => '.1.3.6.1.4.1.1768.100.70.20.2.1.3' }, # memAllocatedBytes
    memory_free_bytes => { oid => '.1.3.6.1.4.1.1768.100.70.20.2.1.4' } # memFreeBytes
};

my $tempProbeEntry_oid = '.1.3.6.1.4.1.1768.100.70.30.2.1';
my $mappingTemperature = {
    display => { oid => '.1.3.6.1.4.1.1768.100.70.30.2.1.1' }, # tempProbeDescr
    probe_temperature_celsius => { oid => '.1.3.6.1.4.1.1768.100.70.30.2.1.2' } # currentDegreesCelsius
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_results = $options{snmp}->get_multiple_table(oids => [
        { oid => $cpuEntry_oid },
        { oid => $memoryPoolEntry_oid },
        { oid => $tempProbeEntry_oid }
    ], nothing_quit => 1);

    $self->{cpu} = {};
    my $cpuTotal = 0;
    foreach my $oid (keys %{$snmp_results->{$cpuEntry_oid}}) {
        next if ($oid !~ /^$mappingCpu->{display}->{oid}\.(.*)$/);
        my $instance = $1;
        my $cpuEntry = $options{snmp}->map_instance(mapping => $mappingCpu, results => $snmp_results->{$cpuEntry_oid}, instance => $instance);
        $self->{cpu}->{$instance} = { display => $instance,
            %$cpuEntry
        };
        $cpuTotal += $cpuEntry->{cpu_utilization_current_percentage};
    }

    my $numCpu = keys %{$self->{cpu}};
    $self->{cpu_average} = {};
    if ($numCpu > 1) {
        $self->{cpu_average} = {
            average => $cpuTotal / ($numCpu - 1),
            count => ($numCpu - 1)
        };
    }

    $self->{memory} = {};
    foreach my $oid (keys %{$snmp_results->{$memoryPoolEntry_oid}}) {
        next if ($oid !~ /^$mappingMemory->{display}->{oid}\.(.*)$/);
        my $instance = $1;
        my $memoryPoolEntry = $options{snmp}->map_instance(mapping => $mappingMemory, results => $snmp_results->{$memoryPoolEntry_oid}, instance => $instance);
        if ($memoryPoolEntry->{memory_total_bytes} > 0) {
            $memoryPoolEntry->{memory_usage_percentage} = $memoryPoolEntry->{memory_usage_bytes} * 100 / $memoryPoolEntry->{memory_total_bytes};
            $memoryPoolEntry->{memory_free_percentage} = $memoryPoolEntry->{memory_free_bytes} * 100 / $memoryPoolEntry->{memory_total_bytes};
        } else {
            $memoryPoolEntry->{memory_usage_percentage} = 0;
            $memoryPoolEntry->{memory_free_percentage} = 0;
        }
        $self->{memory}->{$instance} = { display => $instance,
            %$memoryPoolEntry
        };
    }

    $self->{temperature} = {};
    foreach my $oid (keys %{$snmp_results->{$tempProbeEntry_oid}}) {
        next if ($oid !~ /^$mappingTemperature->{display}->{oid}\.(.*)$/);
        my $instance = $1;
        my $tempProbeEntry = $options{snmp}->map_instance(mapping => $mappingTemperature, results => $snmp_results->{$tempProbeEntry_oid}, instance => $instance);
        $self->{temperature}->{$instance} = { display => $instance,
            %$tempProbeEntry
        };
    }
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^core-cpu-utilization$'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-average' (%), 'core-cpu-utilization' (%), 'core-cpu-utilization-1m' (%), 'core-cpu-utilization-5m' (%),
'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct', 'probe-temperature' (C).

=back

=cut
