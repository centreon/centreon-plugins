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

package apps::redis::restapi::mode::shardsstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s' (%s) [role: %s] [loading status: %s] [backup status: %s]", 
        $self->{result_values}->{status}, 
        $self->{result_values}->{detailed_status}, 
        $self->{result_values}->{role}, 
        $self->{result_values}->{loading}, 
        $self->{result_values}->{backup});
    if ($self->{result_values}->{role} eq 'slave') {
        $msg .= sprintf(" [sync status: %s]", 
            $self->{result_values}->{sync});
    }
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{detailed_status} = $options{new_datas}->{$self->{instance} . '_detailed_status'};
    $self->{result_values}->{loading} = $options{new_datas}->{$self->{instance} . '_loading'};
    $self->{result_values}->{sync} = $options{new_datas}->{$self->{instance} . '_sync'};
    $self->{result_values}->{backup} = $options{new_datas}->{$self->{instance} . '_backup'};
    return 0;
}

sub custom_operations_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s operations rates (hits/misses): %s/%s ops/s", 
        $self->{result_values}->{operation}, 
        $self->{result_values}->{hits}, 
        $self->{result_values}->{misses});
    return $msg;
}

sub custom_operations_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{display}};
    $self->{result_values}->{operation} = $options{extra_options}->{operation};
    $self->{result_values}->{hits} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{hits}};
    $self->{result_values}->{misses} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{misses}};
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

sub prefix_output {
    my ($self, %options) = @_;

    return "Shard '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'shards', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All shards counters are ok' },
    ];
    
    $self->{maps_counters}->{shards} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'detailed_status' }, { name => 'role' }, 
                                { name => 'loading' }, { name => 'sync' }, { name => 'backup' } ],
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
                key_values => [ { name => 'used_memory' }, { name => 'display' } ],
                output_template => 'Memory used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'memory', value => 'used_memory', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
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
        { label => 'connected-clients', set => {
                key_values => [ { name => 'connected_clients' }, { name => 'display' } ],
                output_template => 'Connected clients: %s',
                perfdatas => [
                    { label => 'connected_clients', value => 'connected_clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'blocked-clients', set => {
                key_values => [ { name => 'blocked_clients' }, { name => 'display' } ],
                output_template => 'Blocked clients: %s',
                perfdatas => [
                    { label => 'blocked_clients', value => 'blocked_clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'requests', set => {
                key_values => [ { name => 'total_req'}, { name => 'display' }],
                output_template => 'Requests rate: %s ops/s',
                perfdatas => [
                    { label => 'requests', value => 'total_req', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
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
        { label => 'volatile-keys', set => {
                key_values => [ { name => 'no_of_expires' }, { name => 'display' } ],
                output_template => 'Volatile keys: %s',
                perfdatas => [
                    { label => 'volatile_keys', value => 'no_of_expires', template => '%s',
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
                key_values => [ { name => 'read_hits' }, { name => 'read_misses' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Read', hits => 'read_hits', 
                                                        misses => 'read_misses', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'read_hits', value => 'hits', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'read_misses', value => 'misses', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-rates', set => {
                key_values => [ { name => 'write_hits' }, { name => 'write_misses' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_operations_calc'),
                closure_custom_calc_extra_options => { operation => 'Write', hits => 'write_hits', 
                                                        misses => 'write_misses', display => 'display' },
                closure_custom_output => $self->can('custom_operations_output'),
                perfdatas => [
                    { label => 'write_hits', value => 'hits', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                    { label => 'write_misses', value => 'misses', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'rdb-changes-since-last-save', set => {
                key_values => [ { name => 'rdb_changes_since_last_save' }, { name => 'display' } ],
                output_template => 'Rdb changes since last save: %s',
                perfdatas => [
                    { label => 'rdb_changes_since_last_save', value => 'rdb_changes_since_last_save', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'last-save-time', set => {
                key_values => [ { name => 'last_save_time' }, { name => 'last_save_time_sec' }, { name => 'display' } ],
                output_template => 'Last same time: %s',
                perfdatas => [
                    { label => 'last_save_time', value => 'last_save_time_sec', template => '%s',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "filter-shard:s"     => { name => 'filter_shard' },
                                    "warning-status:s"   => { name => 'warning_status', default => '' },
                                    "critical-status:s"  => { name => 'critical_status', default => '%{status} =~ /inactive/i | %{backup} =~ /failed/i | 
                                                                                                    %{sync} =~ /link_down/i' },
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

    my $result = $options{custom}->get(path => '/v1/shards/stats/last?interval='.$options{custom}->get_interval());
    my $result2 = $options{custom}->get(path => '/v1/shards');

    foreach my $shard (keys %{$result}) {
        if (defined($self->{option_results}->{filter_shard}) && $self->{option_results}->{filter_shard} ne '' &&
            $shard !~ /$self->{option_results}->{filter_shard}/) {
            $self->{output}->output_add(long_msg => "skipping shard '" . $shard . "': no matching filter.", debug => 1);
            next;
        }

        $self->{shards}->{$shard} = {
            display                     => $shard,
            status                      => defined($result2->{$shard}->{status}) ? $result2->{$shard}->{status} : '-',
            detailed_status             => defined($result2->{$shard}->{detailed_status}) ? $result2->{$shard}->{detailed_status} : '-',
            role                        => defined($result2->{$shard}->{role}) ? $result2->{$shard}->{role} : '-',
            loading                     => defined($result2->{$shard}->{loading}->{status}) ? $result2->{$shard}->{loading}->{status} : '-',
            sync                        => defined($result2->{$shard}->{sync}->{status}) ? $result2->{$shard}->{sync}->{status} : '-',
            backup                      => defined($result2->{$shard}->{backup}->{status}) ? $result2->{$shard}->{backup}->{status} : '-',
            used_memory                 => $result->{$shard}->{used_memory},
            mem_frag_ratio              => $result->{$shard}->{mem_frag_ratio},
            shard_cpu_user              => $result->{$shard}->{shard_cpu_user} * 100,
            shard_cpu_system            => $result->{$shard}->{shard_cpu_system} * 100,
            main_thread_cpu_user        => $result->{$shard}->{main_thread_cpu_user} * 100,
            main_thread_cpu_system      => $result->{$shard}->{main_thread_cpu_system} * 100,
            fork_cpu_user               => $result->{$shard}->{fork_cpu_user} * 100,
            fork_cpu_system             => $result->{$shard}->{fork_cpu_system} * 100,
            connected_clients           => $result->{$shard}->{connected_clients},
            blocked_clients             => $result->{$shard}->{blocked_clients},
            total_req                   => defined($result->{$shard}->{total_req}) ? $result->{$shard}->{total_req} : $result->{$shard}->{instantaneous_ops_per_sec},
            no_of_keys                  => $result->{$shard}->{no_of_keys},
            no_of_expires               => $result->{$shard}->{no_of_expires},
            evicted_objects             => $result->{$shard}->{evicted_objects},
            expired_objects             => $result->{$shard}->{expired_objects},
            read_hits                   => $result->{$shard}->{read_hits},
            read_misses                 => $result->{$shard}->{read_misses},
            write_hits                  => $result->{$shard}->{write_hits},
            write_misses                => $result->{$shard}->{write_misses},
            rdb_changes_since_last_save => $result->{$shard}->{rdb_changes_since_last_save},
            last_save_time              => centreon::plugins::misc::change_seconds(value => time() - $result->{$shard}->{last_save_time}),
            last_save_time_sec          => time() - $result->{$shard}->{last_save_time},
        };

        if (scalar(keys %{$self->{shards}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => 'No shards detected, check your filter ? ');
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

Check RedisLabs Enterprise Cluster shards statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='clients'

=item B<--warning-status>
    
Set warning threshold for status.
Can used special variables like: %{status}, %{detailed_status}, 
%{role}, %{loading}, %{sync}, %{backup}.
'status' can be: 'active', 'inactive', 'trimming'.
'detailed_status' can be: 'ok', 'importing', 'timeout', 
'loading', 'busy', 'down', 'trimming', 'unknown'.
'role' can be: 'slave', 'master'.
'loading' can be: 'in_progress', 'idle'.
'sync' can be: 'in_progress', 'idle', 'link_down'.
'backup' can be: 'exporting', 'succeeded', 'failed'.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /inactive/i | 
%{backup} =~ /failed/i | %{sync} =~ /link_down/i').
Can used special variables like: %{status}, %{detailed_status}, 
%{role}, %{loading}, %{sync}, %{backup}.
'status' can be: 'active', 'inactive', 'trimming'.
'detailed_status' can be: 'ok', 'importing', 'timeout', 
'loading', 'busy', 'down', 'trimming', 'unknown'.
'role' can be: 'slave', 'master'.
'loading' can be: 'in_progress', 'idle'.
'sync' can be: 'in_progress', 'idle', 'link_down'.
'backup' can be: 'exporting', 'succeeded', 'failed'.

=item B<--warning-*>

Threshold warning.
Can be: 'total-cpu', 'fork-cpu', 'main-thread-cpu', 
'memory', 'mem-frag-ratio', 
'connected-clients', 'blocked-clients', 
'request', 'keys', 
'evicted-objects', 'expired-objects', 
'read-rates', 'write-rates', 
'rdb-changes-since-last-save', 'last-save-time', 

=item B<--critical-*>

Threshold critical.
Can be: 'total-cpu', 'fork-cpu', 'main-thread-cpu', 
'memory', 'mem-frag-ratio', 
'connected-clients', 'blocked-clients', 
'request', 'keys', 
'evicted-objects', 'expired-objects', 
'read-rates', 'write-rates', 
'rdb-changes-since-last-save', 'last-save-time', 

=back

=cut
