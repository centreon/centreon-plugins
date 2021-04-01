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

package apps::redis::restapi::mode::nodesstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => $self->{result_values}->{perf}, unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{result_values}->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{result_values}->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    
    my $msg = sprintf("%s usage: Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $self->{result_values}->{display}, 
            $total_value . " " . $total_unit, 
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used}, 
            $free_value . " " . $free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{perf} = $options{extra_options}->{perf};
    $self->{result_values}->{display} = $options{extra_options}->{display};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{free}};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total}};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{used} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s' [shard list: %s] [int addr: %s] [ext addr: %s]", 
        $self->{result_values}->{status}, 
        $self->{result_values}->{shard_list}, 
        $self->{result_values}->{int_addr}, 
        $self->{result_values}->{ext_addr});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{shard_list} = $options{new_datas}->{$self->{instance} . '_shard_list'};
    $self->{result_values}->{int_addr} = $options{new_datas}->{$self->{instance} . '_int_addr'};
    $self->{result_values}->{ext_addr} = $options{new_datas}->{$self->{instance} . '_ext_addr'};
    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_output', message_separator => ', ', message_multiple => 'All nodes counters are ok' },
    ];
    
    $self->{maps_counters}->{nodes} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'shard_list' }, { name => 'int_addr' }, { name => 'ext_addr' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'shard-count', set => {
                key_values => [ { name => 'shard_count' }, { name => 'display' } ],
                output_template => 'Shard count: %d',
                perfdatas => [
                    { label => 'shard_count', value => 'shard_count', template => '%d', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
        { label => 'uptime', set => {
                key_values => [ { name => 'uptime' }, { name => 'uptime_sec' }, { name => 'display' } ],
                output_template => 'Uptime: %s',
                perfdatas => [
                    { label => 'uptime', value => 'uptime_sec', template => '%d', 
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
        { label => 'cpu-system', set => {
                key_values => [ { name => 'cpu_system' }, { name => 'display' } ],
                output_template => 'Cpu system: %.2f %%',
                perfdatas => [
                    { label => 'cpu_system', value => 'cpu_system', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-user', set => {
                key_values => [ { name => 'cpu_user' }, { name => 'display' } ],
                output_template => 'Cpu user: %.2f %%',
                perfdatas => [
                    { label => 'cpu_user', value => 'cpu_user', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'free_memory' }, { name => 'total_memory' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { display => 'Ram', label => 'memory', perf => 'memory', 
                                                        free => 'free_memory', total => 'total_memory' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'persistent-storage', set => {
                key_values => [ { name => 'persistent_storage_free' }, { name => 'persistent_storage_size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { display => 'Persistent storage', label => 'persistent-storage', perf => 'persistent_storage', 
                                                        free => 'persistent_storage_free', total => 'persistent_storage_size' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'ephemeral-storage', set => {
                key_values => [ { name => 'ephemeral_storage_free' }, { name => 'ephemeral_storage_size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { display => 'Ephemeral storage', label => 'ephemeral-storage', perf => 'ephemeral_storage', 
                                                        free => 'ephemeral_storage_free', total => 'ephemeral_storage_size' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'flash-storage', set => {
                key_values => [ { name => 'bigstore_free' }, { name => 'bigstore_size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { display => 'Flash storage', label => 'flash-storage', perf => 'flash_storage', 
                                                        free => 'bigstore_free', total => 'bigstore_size' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'flash-iops', set => {
                key_values => [ { name => 'bigstore_iops' }, { name => 'display' } ],
                output_template => 'Flash IOPS: %s ops/s',
                perfdatas => [
                    { label => 'flash_iops', value => 'bigstore_iops', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'flash-throughput', set => {
                key_values => [ { name => 'bigstore_throughput' }, { name => 'display' } ],
                output_template => 'Flash throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'flash_throughput', value => 'bigstore_throughput', template => '%s',
                      min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'connections', set => {
                key_values => [ { name => 'conns' }, { name => 'display' } ],
                output_template => 'Connections: %s',
                perfdatas => [
                    { label => 'connections', value => 'conns', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'requests', set => {
                key_values => [ { name => 'total_req' } ],
                output_template => 'Requests rate: %s ops/s',
                perfdatas => [
                    { label => 'requests', value => 'total_req', template => '%s',
                      min => 0, unit => 'ops/s' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'ingress' }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', value => 'ingress', template => '%d', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'egress' }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', value => 'egress', template => '%d', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "filter-node:s"     => { name => 'filter_node' },
                                    "units:s"           => { name => 'units', default => '%' },
                                    "free"              => { name => 'free' },
                                    "warning-status:s"  => { name => 'warning_status', default => '' },
                                    "critical-status:s" => { name => 'critical_status', default => '%{status} =~ /down/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/v1/nodes/stats/last?interval='.$options{custom}->get_interval());
    my $result2 = $options{custom}->get(path => '/v1/nodes');

    foreach my $node (keys %{$result}) {
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $node !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $node . "': no matching filter.", debug => 1);
            next;
        }

        my $shard_list = '-';
        if (@{$result2->{$node}->{shard_list}}) {
            $shard_list = join(", ", @{$result2->{$node}->{shard_list}});
        }
        my $ext_addr = '-';
        if (@{$result2->{$node}->{external_addr}}) {
            $ext_addr = join(", ", @{$result2->{$node}->{external_addr}});
        }

        $self->{nodes}->{$node} = {
            display                     => $node,
            status                      => defined($result2->{$node}->{status}) ? $result2->{$node}->{status} : '-',
            shard_list                  => $shard_list,
            shard_count                 => $result2->{$node}->{shard_count},
            int_addr                    => $result2->{$node}->{addr},
            ext_addr                    => $ext_addr,
            uptime                      => centreon::plugins::misc::change_seconds(value => $result2->{$node}->{uptime}),
            uptime_sec                  => $result2->{$node}->{uptime},
            cpu_system                  => $result->{$node}->{cpu_system} * 100,
            cpu_user                    => $result->{$node}->{cpu_user} * 100,
            free_memory                 => $result->{$node}->{free_memory},
            total_memory                => $result2->{$node}->{total_memory},
            persistent_storage_free     => $result->{$node}->{persistent_storage_free},
            persistent_storage_size     => $result2->{$node}->{persistent_storage_size},
            ephemeral_storage_free      => $result->{$node}->{ephemeral_storage_free},
            ephemeral_storage_size      => $result2->{$node}->{ephemeral_storage_size},
            bigstore_free               => $result->{$node}->{bigstore_free},
            bigstore_size               => $result2->{$node}->{bigstore_size},
            bigstore_iops               => $result->{$node}->{bigstore_iops},
            bigstore_throughput         => $result->{$node}->{bigstore_throughput},
            conns                       => $result->{$node}->{conns},
            total_req                   => $result->{$node}->{total_req},
            ingress                     => $result->{$node}->{ingress_bytes} * 8,
            egress                      => $result->{$node}->{egress_bytes} * 8,
        };

        if (scalar(keys %{$self->{nodes}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => 'No nodes detected, check your filter ? ');
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check RedisLabs Enterprise Cluster nodes statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^cpu'

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{shard_list}, 
%{int_addr}, %{ext_addr}.
'status' can be: 'active', 'going_offline', 'offline', 
'provisioning', 'decommissioning', 'down'.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{shard_list}, 
%{int_addr}, %{ext_addr}.
'status' can be: 'active', 'going_offline', 'offline', 
'provisioning', 'decommissioning', 'down'.

=item B<--warning-*>

Threshold warning.
Can be: 'cpu-system', 'cpu-user', 
'requests', 'memory', 'flash-storage', 
'persistent-storage', 'ephemeral-storage', 
'flash-iops', 'flash-throughput', 'connections', 
'traffic-in', 'traffic-out', 'shard-count', 'uptime'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu-system', 'cpu-user', 
'requests', 'memory', 'flash-storage', 
'persistent-storage', 'ephemeral-storage', 
'flash-iops', 'flash-throughput', 'connections', 
'traffic-in', 'traffic-out', 'shard-count', 'uptime'.

=back

=cut
