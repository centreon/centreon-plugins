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

package apps::redis::restapi::mode::databasesstats;

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
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{used}};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total}};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
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

    my $msg = sprintf("Status is '%s' [type: %s] [shard list: %s] [backup status: %s] [export status: %s] [import status: %s]", 
        $self->{result_values}->{status}, 
        $self->{result_values}->{type},
        $self->{result_values}->{shard_list}, 
        $self->{result_values}->{backup_status}, 
        $self->{result_values}->{export_status},
        $self->{result_values}->{import_status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{backup_status} = $options{new_datas}->{$self->{instance} . '_backup_status'};
    $self->{result_values}->{export_status} = $options{new_datas}->{$self->{instance} . '_export_status'};
    $self->{result_values}->{import_status} = $options{new_datas}->{$self->{instance} . '_import_status'};
    $self->{result_values}->{shard_list} = $options{new_datas}->{$self->{instance} . '_shard_list'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_cpu_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s CPU usage (user/system): %s/%s %%", 
        $self->{result_values}->{cpu}, 
        $self->{result_values}->{user}, 
        $self->{result_values}->{system});
    return $msg;
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{display}};
    $self->{result_values}->{cpu} = $options{extra_options}->{cpu};
    $self->{result_values}->{user} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{user}};
    $self->{result_values}->{system} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{system}};
    return 0;
}

sub custom_operations_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s operations rates (hits/misses/requests/responses): %s/%s/%s/%s ops/s", 
        $self->{result_values}->{operation}, 
        $self->{result_values}->{hits}, 
        $self->{result_values}->{misses}, 
        $self->{result_values}->{req}, 
        $self->{result_values}->{res});
    return $msg;
}

sub custom_operations_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{display}};
    $self->{result_values}->{operation} = $options{extra_options}->{operation};
    $self->{result_values}->{hits} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{hits}};
    $self->{result_values}->{misses} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{misses}};
    $self->{result_values}->{req} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{req}};
    $self->{result_values}->{res} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{res}};
    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All databases counters are ok' },
    ];
    
    $self->{maps_counters}->{databases} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'type' }, { name => 'backup_status' }, 
                                { name => 'export_status' }, { name => 'import_status' }, { name => 'shard_list' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'total-cpu', set => {
                key_values => [ { name => 'shard_cpu_user' }, { name => 'shard_cpu_system' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => { cpu => 'Total', user => 'shard_cpu_user', 
                                system => 'shard_cpu_system', display => 'display' },
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas => [
                    { label => 'total_cpu_user', value => 'user', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'total_cpu_system', value => 'system', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'fork-cpu', set => {
                key_values => [ { name => 'fork_cpu_user' }, { name => 'fork_cpu_system' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => { cpu => 'Fork', user => 'fork_cpu_user', 
                                system => 'fork_cpu_system', display => 'display' },
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas => [
                    { label => 'fork_cpu_user', value => 'user', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'fork_cpu_system', value => 'system', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'main-thread-cpu', set => {
                key_values => [ { name => 'main_thread_cpu_user' }, { name => 'main_thread_cpu_system' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => { cpu => 'Main thread', user => 'main_thread_cpu_user', 
                                system => 'main_thread_cpu_system', display => 'display' },
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas => [
                    { label => 'main_thread_cpu_user', value => 'user', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'main_thread_cpu_system', value => 'system', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'used_memory' }, { name => 'memory_size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_calc_extra_options => { display => 'Memory', label => 'memory', perf => 'memory', 
                                                        used => 'used_memory', total => 'memory_size' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'mem-frag-ratio', set => {
                key_values => [ { name => 'mem_frag_ratio' }, { name => 'display' } ],
                output_template => 'Memory fragmentation ratio: %s',
                perfdatas => [
                    { label => 'mem_frag_ratio', value => 'mem_frag_ratio', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
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
        { label => 'total-rates', set => {
                key_values => [ { name => 'total_hits' }, { name => 'total_misses' }, 
                                { name => 'total_req' }, { name => 'total_res' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Total', hits => 'total_hits', misses => 'total_misses',
                                req => 'total_req', res => 'total_res', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'total_hits', value => 'hits', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'total_misses', value => 'misses', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'total_req', value => 'req', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'total_res', value => 'res', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'latency', set => {
                key_values => [ { name => 'avg_latency' }, { name => 'display' } ],
                output_template => 'Average latency: %.2f ms',
                perfdatas => [
                    { label => 'latency', value => 'avg_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'other-rates', set => {
                key_values => [ { name => 'other_hits' }, { name => 'other_misses' }, 
                                { name => 'other_req' }, { name => 'other_res' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Other', hits => 'other_hits', misses => 'other_misses',
                                req => 'other_req', res => 'other_res', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'other_req', value => 'req', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'other_res', value => 'res', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'other-latency', set => {
                key_values => [ { name => 'avg_other_latency' }, { name => 'display' } ],
                output_template => 'Other latency: %.2f ms',
                perfdatas => [
                    { label => 'other_latency', value => 'avg_other_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'keys', set => {
                key_values => [ { name => 'no_of_keys' }, { name => 'display' } ],
                output_template => 'Total keys: %s',
                perfdatas => [
                    { label => 'keys', value => 'no_of_keys', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'evicted-objects', set => {
                key_values => [ { name => 'evicted_objects' }, { name => 'display' } ],
                output_template => 'Evicted objects rate: %s evictions/sec',
                perfdatas => [
                    { label => 'evicted_objects', value => 'evicted_objects', template => '%s',
                      min => 0, unit => 'evictions/sec', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'expired-objects', set => {
                key_values => [ { name => 'expired_objects' }, { name => 'display' } ],
                output_template => 'Expired objects rate: %s expirations/sec',
                perfdatas => [
                    { label => 'expired_objects', value => 'expired_objects', template => '%s',
                      min => 0, unit => 'expirations/sec', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-rates', set => {
                key_values => [ { name => 'read_hits' }, { name => 'read_misses' }, 
                                { name => 'read_req' }, { name => 'read_res' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Read', hits => 'read_hits', misses => 'read_misses',
                                req => 'read_req', res => 'read_res', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'read_hits', value => 'hits', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'read_misses', value => 'misses', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'read_req', value => 'req', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'read_res', value => 'res', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-latency', set => {
                key_values => [ { name => 'avg_read_latency' }, { name => 'display' } ],
                output_template => 'Read latency: %.2f ms',
                perfdatas => [
                    { label => 'read_latency', value => 'avg_read_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-rates', set => {
                key_values => [ { name => 'write_hits' }, { name => 'write_misses' }, 
                                { name => 'write_req' }, { name => 'write_res' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Write', hits => 'write_hits', misses => 'write_misses',
                                req => 'write_req', res => 'write_res', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'write_hits', value => 'hits', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'write_misses', value => 'misses', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'write_req', value => 'req', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'write_res', value => 'res', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-latency', set => {
                key_values => [ { name => 'avg_write_latency' }, { name => 'display' } ],
                output_template => 'Write latency: %.2f ms',
                perfdatas => [
                    { label => 'write_latency', value => 'avg_write_latency', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
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
                                    "filter-database:s"     => { name => 'filter_database' },
                                    "units:s"               => { name => 'units', default => '%' },
                                    "free"                  => { name => 'free' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} =~ /creation-failed/i | %{backup_status} =~ /failed/i | 
                                                                                                        %{export_status} =~ /failed/i | %{import_status} =~ /failed/i' },
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

    my $result = $options{custom}->get(path => '/v1/bdbs/stats/last?interval='.$options{custom}->get_interval());
    my $result2 = $options{custom}->get(path => '/v1/bdbs');

    foreach my $database (keys %{$result}) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $database !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping database '" . $database . "': no matching filter.", debug => 1);
            next;
        }

        my $shard_list = '-';
        if (@{$result2->{$database}->{shard_list}}) {
            $shard_list = join(", ", @{$result2->{$database}->{shard_list}});
        }

        $self->{databases}->{$database} = {
            display                     => $result2->{$database}->{name},
            status                      => defined($result2->{$database}->{status}) ? $result2->{$database}->{status} : '-',
            type                        => defined($result2->{$database}->{type}) ? $result2->{$database}->{type} : '-',
            backup_status               => defined($result2->{$database}->{backup_status}) ? $result2->{$database}->{backup_status} : '-',
            export_status               => defined($result2->{$database}->{export_status}) ? $result2->{$database}->{export_status} : '-',
            import_status               => defined($result2->{$database}->{import_status}) ? $result2->{$database}->{import_status} : '-',
            shard_list                  => $shard_list,
            shard_cpu_user              => $result->{$database}->{shard_cpu_user} * 100,
            shard_cpu_system            => $result->{$database}->{shard_cpu_system} * 100,
            main_thread_cpu_user        => $result->{$database}->{main_thread_cpu_user} * 100,
            main_thread_cpu_system      => $result->{$database}->{main_thread_cpu_system} * 100,
            fork_cpu_user               => $result->{$database}->{fork_cpu_user} * 100,
            fork_cpu_system             => $result->{$database}->{fork_cpu_system} * 100,
            used_memory                 => $result->{$database}->{used_memory},
            memory_size                 => $result2->{$database}->{memory_size},
            mem_frag_ratio              => $result->{$database}->{mem_frag_ratio},
            conns                       => $result->{$database}->{conns},
            total_req                   => defined($result->{$database}->{total_req}) ? $result->{$database}->{total_req} : $result->{$database}->{instantaneous_ops_per_sec},
            total_res                   => $result->{$database}->{total_res},
            total_hits                  => $result->{$database}->{read_hits} + $result->{$database}->{write_hits},
            total_misses                => $result->{$database}->{read_misses} + $result->{$database}->{write_misses},
            avg_latency                 => defined($result2->{$database}->{avg_latency}) ? $result->{$database}->{avg_latency} * 1000 : '0',
            other_req                   => $result->{$database}->{other_req},
            other_res                   => $result->{$database}->{other_res},
            other_hits                  => '-',
            other_misses                => '-',
            avg_other_latency           => defined($result2->{$database}->{avg_other_latency}) ? $result->{$database}->{avg_other_latency} * 1000 : '0',
            no_of_keys                  => $result->{$database}->{no_of_keys},
            evicted_objects             => $result->{$database}->{evicted_objects},
            expired_objects             => $result->{$database}->{expired_objects},
            read_hits                   => $result->{$database}->{read_hits},
            read_misses                 => $result->{$database}->{read_misses},
            read_req                    => $result->{$database}->{read_req},
            read_res                    => $result->{$database}->{read_res},
            write_hits                  => $result->{$database}->{write_hits},
            write_misses                => $result->{$database}->{write_misses},
            write_req                   => $result->{$database}->{write_req},
            write_res                   => $result->{$database}->{write_res},
            avg_read_latency            => defined($result2->{$database}->{avg_read_latency}) ? $result->{$database}->{avg_read_latency} * 1000 : '0',
            avg_write_latency           => defined($result2->{$database}->{avg_write_latency}) ? $result->{$database}->{avg_write_latency} * 1000 : '0',
            ingress                     => $result->{$database}->{ingress_bytes} * 8,
            egress                      => $result->{$database}->{egress_bytes} * 8,
        };

        if (scalar(keys %{$self->{databases}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => 'No databases detected, check your filter ? ');
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check RedisLabs Enterprise Cluster databases statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='rate|latency'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{type},  
%{backup_status}, %{export_status}, %{shard_list}.
'status' can be: 'pending', 'active', 'active-change-pending', 
'delete-pending', 'import-pending', 'creation-failed', 'recovery'.
'type' can be: 'redis', 'memcached'.
'backup_status' can be: 'exporting', 'succeeded', 'failed'.
'export_status' can be: 'exporting', 'succeeded', 'failed'.
'import_status' can be: 'idle', 'initializing', 'importing', 
'succeeded', 'failed'.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /creation-failed/i | 
%{backup_status} =~ /failed/i | %{export_status} =~ /failed/i | 
%{import_status} =~ /failed/i').
Can used special variables like: %{status}, %{type},  
%{backup_status}, %{export_status}, %{shard_list}.
'status' can be: 'pending', 'active', 'active-change-pending', 
'delete-pending', 'import-pending', 'creation-failed', 'recovery'.
'type' can be: 'redis', 'memcached'.
'backup_status' can be: 'exporting', 'succeeded', 'failed'.
'' can be: 'exporting', 'succeeded', 'failed'.
'import_status' can be: 'idle', 'initializing', 'importing', 
'succeeded', 'failed'.

=item B<--warning-*>

Threshold warning.
Can be: 'total-cpu', 'fork-cpu', 'main-thread-cpu', 
'memory', 'mem-frag-ratio', 'connections',
'total-rates', 'latency', 'other-rates', 'other-latency', 
'keys', 'evicted-objects', 'expired-objects', 
'read-rates', 'read-latency', 
'write-rates', 'write-latency', 
'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-cpu', 'fork-cpu', 'main-thread-cpu', 
'memory', 'mem-frag-ratio', 'connections',
'total-rates', 'latency', 'other-rates', 'other-latency', 
'keys', 'evicted-objects', 'expired-objects', 
'read-rates', 'read-latency', 
'write-rates', 'write-latency', 
'traffic-in', 'traffic-out'.

=back

=cut
