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

package apps::redis::restapi::mode::databasesstats;

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

    my $msg = sprintf("Status is '%s' [type: %s] [sync: %s] [backup status: %s] [export status: %s] [shard list: %s]", 
        $self->{result_values}->{status}, 
        $self->{result_values}->{type}, 
        $self->{result_values}->{sync}, 
        $self->{result_values}->{backup_status}, 
        $self->{result_values}->{export_status},
        $self->{result_values}->{shard_list});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{sync} = $options{new_datas}->{$self->{instance} . '_sync'};
    $self->{result_values}->{backup_status} = $options{new_datas}->{$self->{instance} . '_backup_status'};
    $self->{result_values}->{export_status} = $options{new_datas}->{$self->{instance} . '_export_status'};
    $self->{result_values}->{shard_list} = $options{new_datas}->{$self->{instance} . '_shard_list'};
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
                key_values => [ { name => 'status' }, { name => 'type' }, { name => 'sync' }, { name => 'backup_status' }, { name => 'export_status' }, { name => 'shard_list' } ],
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
                                    "filter-database:s"     => { name => 'filter_database' },
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

    my $result = $options{custom}->get(path => '/v1/bdbs/stats/last');
    my $result2 = $options{custom}->get(path => '/v1/bdbs');

    foreach my $database (keys $result) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $database !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping database '" . $database . "': no matching filter.", debug => 1);
            next;
        }

        my $shard_list = '-';
        if (@{$result2->{$database}->{shard_list}}) { $shard_list = join(", ", @{$result2->{$database}->{shard_list}}); }

        $self->{databases}->{$database} = {
            display                     => $result2->{$database}->{name},
            status                      => defined($result2->{$database}->{status}) ? $result2->{$database}->{status} : '-',
            type                        => defined($result2->{$database}->{type}) ? $result2->{$database}->{type} : '-',
            sync                        => defined($result2->{$database}->{sync}) ? $result2->{$database}->{sync} : '-',
            backup_status               => defined($result2->{$database}->{backup_status}) ? $result2->{$database}->{backup_status} : '-',
            export_status               => defined($result2->{$database}->{export_status}) ? $result2->{$database}->{export_status} : '-',
            shard_list                  => $shard_list,
            used_memory                 => $result->{$database}->{used_memory},
            instantaneous_ops_per_sec   => $result->{$database}->{instantaneous_ops_per_sec},
            no_of_keys                  => $result->{$database}->{no_of_keys},
            evicted_objects             => $result->{$database}->{evicted_objects},
            expired_objects             => $result->{$database}->{expired_objects},
            read_hits                   => $result->{$database}->{read_hits},
            read_misses                 => $result->{$database}->{read_misses},
            write_hits                  => $result->{$database}->{write_hits},
            write_misses                => $result->{$database}->{write_misses},
            mem_frag_ratio              => $result->{$database}->{mem_frag_ratio},
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
Example: --filter-counters='clients'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{type}, %{sync}, 
%{backup_status}, %{export_status}, %{shard_list}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /active/i').
Can used special variables like: %{status}, %{type}, %{sync}, 
%{backup_status}, %{export_status}, %{shard_list}

=item B<--warning-*>

Threshold warning.
Can be: 'ops-per-sec', 'memory-used', 
'total-keys', 'read-hits', 'read-misses', 
'write-hits', 'write-misses', 'evicted-objects', 
'expired-objects', 'mem-frag-ratio'.

=item B<--critical-*>

Threshold critical.
Can be: 'ops-per-sec', 'memory-used', 
'total-keys', 'read-hits', 'read-misses', 
'write-hits', 'write-misses', 'evicted-objects', 
'expired-objects', 'mem-frag-ratio'.

=back

=cut
