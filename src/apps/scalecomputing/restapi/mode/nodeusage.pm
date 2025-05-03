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

package apps::scalecomputing::restapi::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::PP;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Node %s LAN-IP %s (backplane IP %s) is %s - virtualization is %s",
        $self->{result_values}->{uuid},
        $self->{result_values}->{lan_ip},
        $self->{result_values}->{backplane_ip},
        $self->{result_values}->{network_status},
        $self->{result_values}->{virtualization_online}
    );
}

sub custom_cpu_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s CPU (%s cores/%s threads) usage: %.2f %%',
        $self->{result_values}->{cpu_num},
        $self->{result_values}->{cpu_cores},
        $self->{result_values}->{cpu_threads},
        $self->{result_values}->{cpu_total}
    );
}

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => 'node.memory.usage.bytes',
        unit      => 'B',
        instances => $self->{result_values}->{uuid},
        value     => $self->{result_values}->{memory_used},
        warning   => $self->{perfdata}->get_perfdata_for_output(
            label    => 'warning-' . $self->{thlabel},
            total    => $self->{result_values}->{memory_total},
            cast_int => 1
        ),
        critical  => $self->{perfdata}->get_perfdata_for_output(
            label    => 'critical-' . $self->{thlabel},
            total    => $self->{result_values}->{memory_total},
            cast_int => 1
        ),
        min       => 0,
        max       => $self->{result_values}->{memory_total}
    );
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{memory_prct_used},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_free});
    my ($total_system_used_value, $total_system_used_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_used_system});

    return sprintf(
        'Memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%) system: %s',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{memory_prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{memory_prct_free},
        $total_system_used_value . " " . $total_system_used_unit,
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'nodes',
            type             => 1,
            message_multiple => 'All nodes are ok',
            skipped_code     => { -10 => 1, -11 => 1 }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        {
            label            => 'node-status',
            type             => 2,
            critical_default =>
                '%{network_status} ne "ONLINE" || %{virtualization_online} ne "true" || %{current_disposition} !~ %{desired_disposition}',
            set              => {
                key_values                     => [
                    { name => 'uuid' },
                    { name => 'lan_ip' },
                    { name => 'backplane_ip' },
                    { name => 'network_status' },
                    { name => 'virtualization_online' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label  => 'cpu-total',
            nlabel => 'node.cpu.utilization.percentage',
            set    => {
                key_values            => [
                    { name => 'cpu_total' },
                    { name => 'cpu_num' },
                    { name => 'cpu_cores' },
                    { name => 'cpu_threads' }
                ],
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas             => [
                    {
                        label                => 'cpu_total',
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        max                  => 100,
                        label_extra_instance => 1
                    }
                ]
            }
        },
        {
            label  => 'cpu-mhz',
            nlabel => 'node.cpu.utilization.mhz',
            set    => {
                key_values      => [ { name => 'cpu_total_mhz' } ],
                output_template => '%s MHz',
                perfdatas       => [
                    {
                        label                => 'cpu_total_mhz',
                        template             => '%s',
                        unit                 => 'MHz',
                        min                  => 0,
                        label_extra_instance => 1
                    }
                ]
            }
        },
        {
            label => 'memory',
            set   => {
                key_values                     =>
                    [
                        { name => 'uuid' },
                        { name => 'memory_used' },
                        { name => 'memory_used_system' },
                        { name => 'memory_total' },
                        { name => 'memory_free' },
                        { name => 'memory_prct_used' },
                        { name => 'memory_prct_free' }
                    ],
                closure_custom_output          =>
                    $self->can('custom_memory_output'),
                closure_custom_perfdata        =>
                    $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check =>
                    $self->can('custom_memory_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'uuid:s' => { name => 'uuid' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $nodes = $options{custom}->list_nodes();
    foreach my $node (@{$nodes}) {
        if (defined($self->{option_results}->{uuid}) && $self->{option_results}->{uuid} ne '' &&
            $node->{uuid} !~ /$self->{option_results}->{uuid}/) {
            $self->{output}->output_add(
                long_msg => "skipping  '" . $node->{uuid} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        # add the instance
        $self->{nodes}->{$node->{uuid}} = {
            uuid                  => $node->{uuid},
            lan_ip                => $node->{lanIP},
            backplane_ip          => $node->{backplaneIP},
            network_status        => $node->{networkStatus},
            desired_disposition   => $node->{desiredDisposition},
            current_disposition   => $node->{currentDisposition},
            allow_running_vms     => $node->{allowRunningVMs},
            virtualization_online => ($node->{virtualizationOnline} == JSON::PP::true) ? "true" : "false",
            cpu_total             => $node->{cpuUsage},
            cpu_num               => $node->{numCPUs},
            cpu_cores             => $node->{numCores},
            cpu_threads           => $node->{numThreads},
            cpu_total_mhz         => $node->{CPUhz} * 0.000001
        };

        my $total = $node->{memSize};
        my $used = $node->{totalMemUsageBytes};
        my $free = ($node->{memSize} - $node->{totalMemUsageBytes});

        $self->{nodes}->{$node->{uuid}}->{memory_total} = $total;
        $self->{nodes}->{$node->{uuid}}->{memory_used} = $used;
        $self->{nodes}->{$node->{uuid}}->{memory_free} = $free;
        $self->{nodes}->{$node->{uuid}}->{memory_used_system} = $node->{systemMemUsageBytes};
        $self->{nodes}->{$node->{uuid}}->{memory_prct_used} = $node->{memUsagePercentage};
        $self->{nodes}->{$node->{uuid}}->{memory_prct_free} = 100 - $node->{memUsagePercentage};
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No node found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node usage.

=over 8

=item B<--uuid>

cluster to check. If not set, we check all clusters.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-total' (%), 'cpu-mhz', 'memory' (%)

=item B<--unknown-node-status>

Define the conditions to match for the node status to be UNKNOWN (default: '').
You can use the following variables: %{network_status}, %{current_disposition}, %{desired_disposition}, %{allow_running_vms}, %{virtualization_online}

%{network_status} can be 'ONLINE', 'OFFLINE', 'UNKNOWN'.

=item B<--warning-node-status>

Define the conditions to match for the node status to be WARNING (default: '').
You can use the following variables: %{network_status}, %{current_disposition}, %{desired_disposition}, %{allow_running_vms}, %{virtualization_online}

%{network_status} can be 'ONLINE', 'OFFLINE', 'UNKNOWN'.

=item B<--critical-node-status>

Define the conditions to match for the node status to be CRITICAL (default: '%{network_status} ne "ONLINE" || %{virtualization_online} ne "true" || %{current_disposition} !~ %{desired_disposition}').
You can use the following variables: %{network_status}, %{current_disposition}, %{desired_disposition}, %{allow_running_vms}, %{virtualization_online}

%{network_status} can be 'ONLINE', 'OFFLINE', 'UNKNOWN'.

=back

=cut
