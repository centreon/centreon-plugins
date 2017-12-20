#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

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
                key_values => [ { name => 'status' }, { name => 'detailed_status' }, { name => 'role' }, { name => 'loading' }, { name => 'sync' }, { name => 'backup' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'ops-per-sec', set => {
                key_values => [ { name => 'instantaneous_ops_per_sec' }, { name => 'display' } ],
                output_template => 'Operations: %s ops/s',
                perfdatas => [
                    { label => 'ops_per_sec', value => 'instantaneous_ops_per_sec_absolute', template => '%s',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'memory-used', set => {
                key_values => [ { name => 'used_memory' }, { name => 'display' } ],
                output_template => 'Memory used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'memory-used', value => 'used_memory_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'total-keys', set => {
                key_values => [ { name => 'no_of_keys' }, { name => 'display' } ],
                output_template => 'Total keys: %s',
                perfdatas => [
                    { label => 'total-keys', value => 'no_of_keys_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'connected-clients', set => {
                key_values => [ { name => 'connected_clients' }, { name => 'display' } ],
                output_template => 'Connected clients: %s',
                perfdatas => [
                    { label => 'connected_clients', value => 'connected_clients_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'blocked-clients', set => {
                key_values => [ { name => 'blocked_clients' }, { name => 'display' } ],
                output_template => 'Blocked clients: %s',
                perfdatas => [
                    { label => 'blocked_clients', value => 'blocked_clients_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'read-hits', set => {
                key_values => [ { name => 'read_hits' }, { name => 'display' } ],
                output_template => 'Read hits: %s /s',
                perfdatas => [
                    { label => 'read_hits', value => 'read_hits_absolute', template => '%s',
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'read-misses', set => {
                key_values => [ { name => 'read_misses' }, { name => 'display' } ],
                output_template => 'Read misses: %s /s',
                perfdatas => [
                    { label => 'read_misses', value => 'read_misses_absolute', template => '%s',
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'write-hits', set => {
                key_values => [ { name => 'write_hits' }, { name => 'display' } ],
                output_template => 'Write hits: %s /s',
                perfdatas => [
                    { label => 'write_hits', value => 'write_hits_absolute', template => '%s',
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'write-misses', set => {
                key_values => [ { name => 'write_misses' }, { name => 'display' } ],
                output_template => 'Write misses: %s /s',
                perfdatas => [
                    { label => 'write_misses', value => 'write_misses_absolute', template => '%s',
                      min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'evicted-objects', set => {
                key_values => [ { name => 'evicted_objects' }, { name => 'display' } ],
                output_template => 'Evicted objects: %s',
                perfdatas => [
                    { label => 'evicted_objects', value => 'evicted_objects_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'expired-objects', set => {
                key_values => [ { name => 'expired_objects' }, { name => 'display' } ],
                output_template => 'Evicted objects: %s',
                perfdatas => [
                    { label => 'expired_objects', value => 'expired_objects_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'rdb-changes-since-last-save', set => {
                key_values => [ { name => 'rdb_changes_since_last_save' }, { name => 'display' } ],
                output_template => 'Rdb changes since last save: %s',
                perfdatas => [
                    { label => 'rdb_changes_since_last_save', value => 'rdb_changes_since_last_save_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'last-save-time', set => {
                key_values => [ { name => 'last_save_time' }, { name => 'last_save_time_sec' }, { name => 'display' } ],
                output_template => 'Last same time: %s',
                perfdatas => [
                    { label => 'last_save_time', value => 'last_save_time_sec_absolute', template => '%s',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'mem-frag-ratio', set => {
                key_values => [ { name => 'mem_frag_ratio' }, { name => 'display' } ],
                output_template => 'Memory fragmentation ratio: %s',
                perfdatas => [
                    { label => 'mem_frag_ratio', value => 'mem_frag_ratio_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-shard:s"     => { name => 'filter_shard' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "redis_restapi_" . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->get(path => '/v1/shards/stats/last');
    my $result2 = $options{custom}->get(path => '/v1/shards');

    foreach my $shard (keys $result) {
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
            instantaneous_ops_per_sec   => $result->{$shard}->{instantaneous_ops_per_sec},
            no_of_keys                  => $result->{$shard}->{no_of_keys},
            connected_clients           => $result->{$shard}->{connected_clients},
            blocked_clients             => $result->{$shard}->{blocked_clients},
            evicted_objects             => $result->{$shard}->{evicted_objects},
            expired_objects             => $result->{$shard}->{expired_objects},
            read_hits                   => $result->{$shard}->{read_hits},
            read_misses                 => $result->{$shard}->{read_misses},
            write_hits                  => $result->{$shard}->{write_hits},
            write_misses                => $result->{$shard}->{write_misses},
            mem_frag_ratio              => $result->{$shard}->{mem_frag_ratio},
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

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /active/i').
Can used special variables like: %{status}, %{detailed_status}, 
%{role}, %{loading}, %{sync}, %{backup}.

=item B<--warning-*>

Threshold warning.
Can be: 'ops-per-sec', 'memory-used', 'total-keys', 
'connected-clients', 'blocked-clients', 
'read-hits', 'read-misses', 'write-hits', 
'write-misses', 'evicted-objects', 'expired-objects', 
'rdb-changes-since-last-save', 'last-save-time', 
'mem-frag-ratio'.

=item B<--critical-*>

Threshold critical.
Can be: 'ops-per-sec', 'memory-used', 'total-keys', 
'connected-clients', 'blocked-clients', 
'read-hits', 'read-misses', 'write-hits', 
'write-misses', 'evicted-objects', 'expired-objects', 
'rdb-changes-since-last-save', 'last-save-time', 
'mem-frag-ratio'.

=back

=cut
