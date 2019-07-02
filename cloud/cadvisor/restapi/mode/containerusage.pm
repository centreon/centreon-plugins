#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::cadvisor::restapi::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use DateTime;

sub custom_memory_output {
    my ($self, %options) = @_;
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_total_absolute});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_used_absolute});
    my $msg = sprintf("Memory Used: %s (%.2f%%) Total: %s" ,
                      $total_used_value . " " . $total_used_unit, 100 * $self->{result_values}->{memory_used_absolute} / $self->{result_values}->{memory_total_absolute},
                      $total_size_value . " " . $total_size_unit);
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output', message_multiple => 'All containers are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{containers} = [
        { label => 'cpu-number', set => {
                key_values => [ { name => 'cpu_number'}, { name => 'display' } ],
                output_template => 'CPU: %d core(s)',
                output_use => 'cpu_number_absolute',
                perfdatas => [
                    { label => 'cpu_number', value => 'cpu_number_absolute', template => '%d',
                       min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'cpu-total', set => {
                key_values => [ { name => 'cpu_total'}, { name => 'display' } ],
                output_template => 'CPU Usage: %.2f %%',
                output_use => 'cpu_total_absolute',
                perfdatas => [
                    { label => 'cpu_total', value => 'cpu_total_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'cpu-user', set => {
                key_values => [ { name => 'cpu_user'}, { name => 'display' } ],
                output_template => 'CPU User: %.2f %%',
                output_use => 'cpu_user_absolute',
                perfdatas => [
                    { label => 'cpu_user', value => 'cpu_user_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'cpu-system', set => {
                key_values => [ { name => 'cpu_system' }, { name => 'display' } ],
                output_template => 'CPU System: %.2f %%',
                output_use => 'cpu_system_absolute',
                perfdatas => [
                    { label => 'cpu_system', value => 'cpu_system_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'memory_used' }, { name => 'memory_total' }, { name => 'display' } ],
                output_change_bytes => 1,
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { label => 'memory_used', value => 'memory_used_absolute', template => '%s',
                    min => 0, max => 'memory_total_absolute',unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'memory-cache', set => {
                key_values => [ { name => 'memory_cache' }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'Memory Cache: %s %s',
                perfdatas => [
                    { label => 'memory_cache', value => 'memory_cache_absolute', template => '%s',
                    min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'memory-rss', set => {
                key_values => [ { name => 'memory_rss' }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'Memory RSS: %s %s',
                perfdatas => [
                    { label => 'memory_rss', value => 'memory_rss_absolute', template => '%s',
                    min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'swap', set => {
                key_values => [ { name => 'swap' }, { name => 'display' } ],
                output_change_bytes => 1,
                output_template => 'Swap: %s %s',
                perfdatas => [
                    { label => 'swap', value => 'swap_absolute', template => '%s',
                    min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "container-id:s"              => { name => 'container_id' },
        "container-name:s"            => { name => 'container_name' },
        "filter-name:s"               => { name => 'filter_name' },
        "use-name"                    => { name => 'use_name' },
        "warning-container-status:s"  => { name => 'warning_container_status', default => '' },
        "critical-container-status:s" => { name => 'critical_container_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_container_status', 'critical_container_status']);
}

sub prefix_containers_output {
    my ($self, %options) = @_;
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{containers} = {};
    my $result = $options{custom}->api_get_containers(
        container_id => $self->{option_results}->{container_id}, 
        container_name => $self->{option_results}->{container_name}
    );
    my $machine_stats = $options{custom}->api_get_machine_stats();

    foreach my $container_id (keys %{$result}) {
        next if (!defined($result->{$container_id}->{Stats})); 
        my $name = $result->{$container_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        my $first_index = 0;
        my $first_stat = $result->{$container_id}->{Stats}[$first_index];
        my $first_ts = $first_stat->{timestamp};
        my $first_dt = $self->parse_date(date => $first_ts);
        my $first_cpu_total = $first_stat->{cpu}{usage}{total};
        my $first_cpu_user = $first_stat->{cpu}{usage}{user};
        my $first_cpu_system = $first_stat->{cpu}{usage}{system};

        my $last_index = scalar @{$result->{$container_id}->{Stats}} - 1;
        my $last_stat = $result->{$container_id}->{Stats}[$last_index];
        my $last_ts = $last_stat->{timestamp};
        my $last_dt = $self->parse_date(date => $last_ts);
        my $last_cpu_total = $last_stat->{cpu}{usage}{total};
        my $last_cpu_user = $last_stat->{cpu}{usage}{user};
        my $last_cpu_system = $last_stat->{cpu}{usage}{system};

        my $diff_ts = $last_dt - $first_dt;
        my $cpu_number = $machine_stats->{$result->{$container_id}->{NodeName}}->{num_cores};


        $self->{containers}->{$container_id} = {
            node_name           => $result->{$container_id}->{NodeName},
            display             => defined($self->{option_results}->{use_name}) ? $name : $container_id,
            name                => $name,
            cpu_total           => ($last_cpu_total - $first_cpu_total) / ($diff_ts * 1_000_000_000) * 100 / $cpu_number,
            cpu_user            => ($last_cpu_user - $first_cpu_user) / ($diff_ts * 1_000_000_000) * 100 / $cpu_number,
            cpu_system          => ($last_cpu_system - $first_cpu_system) / ($diff_ts * 1_000_000_000) * 100 / $cpu_number,
            cpu_number          => $cpu_number,
            memory_used         => $last_stat->{memory}{usage},
            memory_cache        => $last_stat->{memory}{cache},
            memory_rss          => $last_stat->{memory}{rss},
            swap                => $last_stat->{memory}{swap},
            memory_total        => $machine_stats->{$result->{$container_id}->{NodeName}}->{memory_capacity},
        };
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
    
    my $hostnames = $options{custom}->get_hostnames();
}

sub parse_date {
    my ($self, %options) = @_;

    if ($options{date} !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d*)([^\d]+)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong time found '" . $options{date} . "'.");
        $self->{output}->option_exit();
    }
    my $dt = DateTime->new(
        year => $1, month => $2, day => $3, 
        hour => $4, minute => $5, second => $6, 
        time_zone => $8
    );
    # return epoch time with nanoseconds
    return $dt->epoch.".".$7;
}


1;

__END__

=head1 MODE

Check container usage.

=over 8

=item B<--container-id>

Exact container ID.

=item B<--container-name>

Exact container name (if multiple names: names separated by ':').

=item B<--use-name>

Use name for perfdata and display.

=item B<--filter-name>

Filter by container name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^container-status$'

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out', 
'cpu' (%), 'memory' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out',
'cpu' (%), 'memory' (%).

=item B<--warning-container-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{state}.

=item B<--critical-container-status>

Set critical threshold for status (Default: -).
Can used special variables like: %{name}, %{state}.

=back

=cut
