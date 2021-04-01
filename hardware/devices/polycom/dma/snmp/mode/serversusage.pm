#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::devices::polycom::dma::snmp::mode::serversusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Memory Total: %s %s, Used: %s %s (%.2f%%), Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_used}),
        $self->{result_values}->{memory_prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_free}),
        $self->{result_values}->{memory_prct_free}
    );
}

sub custom_swap_output {
    my ($self, %options) = @_;

    return sprintf(
        'Swap Total: %s %s, Used: %s %s (%.2f%%), Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{swap_total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{swap_used}),
        $self->{result_values}->{swap_prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{swap_free}),
        $self->{result_values}->{swap_prct_free}
    );
}

sub custom_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        'Disk Total: %s %s, Used: %s %s (%.2f%%), Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{disk_total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{disk_used}),
        $self->{result_values}->{disk_prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{disk_free}),
        $self->{result_values}->{disk_prct_free}
    );
}

sub custom_logs_output {
    my ($self, %options) = @_;

    return sprintf(
        'Logs Total: %s %s, Used: %s %s (%.2f%%), Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{logs_total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{logs_used}),
        $self->{result_values}->{logs_prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{logs_free}),
        $self->{result_values}->{logs_prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'server', type => 1, cb_prefix_output => 'prefix_server_output', message_multiple => 'All servers are ok' }
    ];

    $self->{maps_counters}->{server} = [
        { label => 'server-cpu-usage', nlabel => 'dma.server.cpu.utilization.percentage', set => {
                key_values => [ { name => 'stRsrcCPUUsageCPUUtilizationPct' }, { name => 'display'} ],
                output_template => 'CPU Utilization: %.2f %%',
                perfdatas => [
                    { template => '%d', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        # Memory counters
        { label => 'server-memory-usage', nlabel => 'dma.server.memory.usage.bytes', set => {
                key_values => [
                    { name => 'memory_used' }, { name => 'memory_free' }, { name => 'memory_prct_used' },
                    { name => 'memory_prct_free' }, { name => 'memory_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'memory_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-memory-free', display_ok => 0, nlabel => 'dma.server.memory.free.bytes', set => {
                key_values => [
                    { name => 'memory_free' }, { name => 'memory_used' }, { name => 'memory_prct_used' },
                    { name => 'memory_prct_free' }, { name => 'memory_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'memory_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-memory-prct', display_ok => 0, nlabel => 'dma.server.memory.usage.percentage', set => {
                key_values => [ { name => 'memory_prct_used' }, { name => 'display' } ],
                output_template => 'RAM used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        # Swap counters
        { label => 'server-swap-usage', nlabel => 'dma.server.swap.usage.percentage', set => {
                key_values => [
                    { name => 'swap_used' }, { name => 'swap_free' }, { name => 'swap_prct_used' },
                    { name => 'swap_prct_free' }, { name => 'swap_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'swap_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-swap-free', display_ok => 0, nlabel => 'dma.server.swap.free.bytes', set => {
                key_values => [
                    { name => 'swap_free' }, { name => 'swap_used' }, { name => 'swap_prct_used' },
                    { name => 'swap_prct_free' }, { name => 'swap_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'swap_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-swap-prct', display_ok => 0, nlabel => 'dma.server.swap.usage.percentage', set => {
                key_values => [ { name => 'swap_prct_used' }, { name => 'display' } ],
                output_template => 'swap used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        # Disk counters
        { label => 'server-disk-usage', nlabel => 'dma.server.disk.usage.bytes', set => {
                key_values => [
                    { name => 'disk_used' }, { name => 'disk_free' }, { name => 'disk_prct_used' },
                    { name => 'disk_prct_free' }, { name => 'disk_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'disk_total', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-disk-free', display_ok => 0, nlabel => 'dma.server.disk.free.bytes', set => {
                key_values => [
                    { name => 'disk_free' }, { name => 'disk_used' }, { name => 'disk_prct_used' },
                    { name => 'disk_prct_free' }, { name => 'disk_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'disk_total', label_extra_instance => 1, instance_use => 'display', }
                ]
            }
        },
        { label => 'server-disk-prct', display_ok => 0, nlabel => 'dma.server.disk.usage.percentage', set => {
                key_values => [ { name => 'disk_prct_used' }, { name => 'display' } ],
                output_template => 'disk used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        # Log counters
        { label => 'server-logs-usage', nlabel => 'dma.server.logs.usage.bytes', set => {
                key_values => [
                    { name => 'logs_used' }, { name => 'logs_free' }, { name => 'logs_prct_used' },
                    { name => 'logs_prct_free' }, { name => 'logs_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_logs_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'logs_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-logs-free', display_ok => 0, nlabel => 'dma.server.logs.free.bytes', set => {
                key_values => [
                    { name => 'logs_free' }, { name => 'logs_used' }, { name => 'logs_prct_used' },
                    { name => 'logs_prct_free' }, { name => 'logs_total' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_logs_output'),
                perfdatas => [
                    { template => '%d', cast_int => 1, min => 0, max => 'logs_total', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'server-logs-prct', display_ok => 0, nlabel => 'dma.server.logs.usage.percentage', set => {
                key_values => [ { name => 'logs_prct_used' }, { name => 'display' } ],
                output_template => 'logs used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-server:s' => { name => 'filter_server' }
    });

    return $self;
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return "Server '" . $options{instance_value}->{display} . "' ";
}

my $mapping_cpu = {
    stRsrcCPUUsageHostName          => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.1.1.2' },
    stRsrcCPUUsageCPUUtilizationPct => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.1.1.3' }
};

my $mapping_memory = {
    stRsrcMemUsageHostName          => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1.2' },
    stRsrcMemUsageTotalMemory       => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1.3' },
    stRsrcMemUsageBuffersAndCache   => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1.4' },
    stRsrcMemUsageUsed              => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1.5' },
    stRsrcMemUsageFree              => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1.6' }
};

my $mapping_swap = {
    stRsrcSwapHostName  => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.3.1.2' },
    stRsrcSwapTotal     => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.3.1.3' },
    stRsrcSwapUsed      => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.3.1.4' }
};

my $mapping_disk = {
    stRsrcDiskHostName  => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.4.1.2' },
    stRsrcDiskTotal     => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.4.1.3' },
    stRsrcDiskUsed      => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.4.1.4' }
};

my $mapping_logs = {
    stRsrcLogHostName   => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.5.1.2'},
    stRsrcLogTotal      => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.5.1.3'},
    stRsrcLogUsed       => { oid => '.1.3.6.1.4.1.13885.13.2.2.1.4.5.1.4'}
};

my $oid_stRsrcCPUUsageEntry = '.1.3.6.1.4.1.13885.13.2.2.1.4.1.1';
my $oid_stRsrcMemoryUsageEntry = '.1.3.6.1.4.1.13885.13.2.2.1.4.2.1';
my $oid_stRsrcSwapUsageEntry = '.1.3.6.1.4.1.13885.13.2.2.1.4.3.1';
my $oid_stRsrcDiskSpaceEntry = '.1.3.6.1.4.1.13885.13.2.2.1.4.4.1';
my $oid_stRsrcLogSpaceEntry = '.1.3.6.1.4.1.13885.13.2.2.1.4.5.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_stRsrcCPUUsageEntry },
            { oid => $oid_stRsrcMemoryUsageEntry },
            { oid => $oid_stRsrcSwapUsageEntry },
            { oid => $oid_stRsrcDiskSpaceEntry },
            { oid => $oid_stRsrcLogSpaceEntry }
        ],
        nothing_quit => 1
    );

    $self->{server} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_stRsrcCPUUsageEntry}}) {
        next if ($oid !~ /^$mapping_cpu->{stRsrcCPUUsageHostName}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result_cpu = $options{snmp}->map_instance(mapping => $mapping_cpu, results => $snmp_result->{$oid_stRsrcCPUUsageEntry}, instance => $instance);
        my $result_memory = $options{snmp}->map_instance(mapping => $mapping_memory, results => $snmp_result->{$oid_stRsrcMemoryUsageEntry}, instance => $instance);
        my $result_swap = $options{snmp}->map_instance(mapping => $mapping_swap, results => $snmp_result->{$oid_stRsrcSwapUsageEntry}, instance => $instance);
        my $result_disk = $options{snmp}->map_instance(mapping => $mapping_disk, results => $snmp_result->{$oid_stRsrcDiskSpaceEntry}, instance => $instance);
        my $result_logs = $options{snmp}->map_instance(mapping => $mapping_logs, results => $snmp_result->{$oid_stRsrcLogSpaceEntry}, instance => $instance);

        $result_cpu->{stRsrcCPUUsageHostName} = centreon::plugins::misc::trim($result_cpu->{stRsrcCPUUsageHostName});
        if (defined($self->{option_results}->{filter_server}) && $self->{option_results}->{filter_server} ne '' &&
            $result_cpu->{stRsrcCPUUsageHostName} !~ /$self->{option_results}->{filter_server}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $result_cpu->{stRsrcCPUUsageHostName} . "': no matching filter.", debug => 1);
                next;
        }

        my ($memory_used, $memory_total) = (($result_memory->{stRsrcMemUsageUsed} + $result_memory->{stRsrcMemUsageBuffersAndCache} * 1024 * 1024),
                                             $result_memory->{stRsrcMemUsageTotalMemory} * 1024 * 1024);
        my ($swap_used, $swap_total) = (($result_swap->{stRsrcSwapUsed} * 1024 * 1024), ($result_swap->{stRsrcSwapTotal} * 1024 * 1024));
        my ($disk_used, $disk_total) = (($result_disk->{stRsrcDiskUsed} * 1024 * 1024), ($result_disk->{stRsrcDiskTotal} * 1024 * 1024));
        my ($logs_used, $logs_total) = (($result_logs->{stRsrcLogUsed} * 1024 * 1024, $result_logs->{stRsrcLogTotal} * 1024 * 1024));

        $self->{server}->{$instance} = {
            display => $result_cpu->{stRsrcCPUUsageHostName},
            stRsrcCPUUsageCPUUtilizationPct => $result_cpu->{stRsrcCPUUsageCPUUtilizationPct},
            memory_free => $memory_total - $memory_used,
            memory_prct_free => 100 - ($memory_used * 100 / $memory_total),
            memory_prct_used => ($memory_total != 0) ? $memory_used * 100 / $memory_total : '0',
            memory_total => $memory_total,
            memory_used => $memory_used,
            swap_free => $swap_total - $swap_used,
            swap_prct_free => 100 - ($swap_used * 100 / $swap_total),
            swap_prct_used => ($swap_total != 0) ? $swap_used * 100 / $swap_total : '0',
            swap_total => $swap_total,
            swap_used => $swap_used,
            disk_free => $disk_total - $disk_used,
            disk_prct_free => 100 - ($disk_used * 100 / $disk_total),
            disk_prct_used => ($disk_total != 0) ? $disk_used * 100 / $disk_total : '0',
            disk_total => $disk_total,
            disk_used => $disk_used,
            logs_free => $logs_total - $logs_used,
            logs_prct_free => 100 - ($logs_used * 100 / $logs_total),
            logs_prct_used => ($logs_total != 0) ? $logs_used * 100 / $logs_total : '0',
            logs_total => $logs_total,
            logs_used => $logs_used
        };
    }

}

1;

__END__

=head1 MODE

Check managed servers system usage metrics

=over 8

=item B<--filter-server>

Filter on one or several server (POSIX regexp)

=item B<--warning-* --critical-*>

Warning & Critical Thresholds. Possible values:

[CPU]  server-cpu-usage
[RAM]  server-memory-usage server-memory-free server-memory-prct
[SWAP] server-swap-usage server-swap-free server-swap-prct
[DISK] server-disk-usage server-disk-free server-disk-prct
[LOGS] server-logs-usage server-logs-free server-logs-prct

=back

=cut
