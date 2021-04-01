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

package cloud::docker::restapi::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'state : ' . $self->{result_values}->{state};
    return $msg;
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_total = $options{new_datas}->{$self->{instance} . '_cpu_total_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_total_usage'};
    my $delta_cpu_system = $options{new_datas}->{$self->{instance} . '_cpu_system_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_system_usage'};
    $self->{result_values}->{prct_cpu} = (($delta_cpu_total / $delta_cpu_system) * $options{new_datas}->{$self->{instance} . '_cpu_number'}) * 100;
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'memory_used',
        nlabel => 'container.memory.usage.bytes',
        unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        "Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_memory_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_memory_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_memory_usage'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output', message_multiple => 'All containers are ok', skipped_code => { -11 => 1 } },
        { name => 'containers_traffic', type => 1, cb_prefix_output => 'prefix_containers_traffic_output', message_multiple => 'All container traffics are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{containers} = [
         { label => 'container-status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu', nlabel => 'container.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_total_usage', diff => 1 }, { name => 'cpu_system_usage', diff => 1 }, { name => 'cpu_number' }, { name => 'display' } ],
                output_template => 'CPU Usage : %.2f %%',
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_use => 'prct_cpu', threshold_use => 'prct_cpu',
                perfdatas => [
                    { label => 'cpu', value => 'prct_cpu', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory', nlabel => 'container.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'memory_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_output => $self->can('custom_memory_output'),
                closure_custom_perfdata => $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check => $self->can('custom_memory_threshold')
            }
        },
        { label => 'read-iops', nlabel => 'container.disk.io.read.usage.iops', set => {
                key_values => [ { name => 'read_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'container.disk.io.write.usage.iops', set => {
                key_values => [ { name => 'write_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{containers_traffic} = [
        { label => 'traffic-in', nlabel => 'container.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out',  nlabel => 'container.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'container-id:s'   => { name => 'container_id' },
        'container-name:s' => { name => 'container_name' },
        'filter-name:s'    => { name => 'filter_name' },
        'use-name'         => { name => 'use_name' }
    });
   
    $self->{statefile_cache_containers} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_containers}->check_options(%options);
}

sub prefix_containers_traffic_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub prefix_containers_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{containers} = {};
    $self->{containers_traffic} = {};
    my $result = $options{custom}->api_get_containers(container_id => $self->{option_results}->{container_id}, 
        container_name => $self->{option_results}->{container_name}, statefile => $self->{statefile_cache_containers});

    foreach my $container_id (keys %{$result}) {
        next if (!defined($result->{$container_id}->{Stats})); 
        my $name = $result->{$container_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        my $read_io = $result->{$container_id}->{Stats}->{blkio_stats}->{io_service_bytes_recursive}->[0]->{value};
        my $write_io = $result->{$container_id}->{Stats}->{blkio_stats}->{io_service_bytes_recursive}->[1]->{value};
        $self->{containers}->{$container_id} = {
            display => defined($self->{option_results}->{use_name}) ? $name : $container_id,
            name => $name,
            state => $result->{$container_id}->{State},
            read_io => $read_io,
            write_io => $write_io,
            cpu_total_usage => $result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{total_usage},
            cpu_system_usage => $result->{$container_id}->{Stats}->{cpu_stats}->{system_cpu_usage},
            cpu_number => defined($result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{percpu_usage}) ?
                scalar(@{$result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{percpu_usage}}) : 1,
            memory_usage => $result->{$container_id}->{Stats}->{memory_stats}->{usage},
            memory_total => $result->{$container_id}->{Stats}->{memory_stats}->{limit},
        };
        
        foreach my $interface (keys %{$result->{$container_id}->{Stats}->{networks}}) {
            my $name = defined($self->{option_results}->{use_name}) ? $name : $container_id;
            $name .= '.' . $interface;
            $self->{containers_traffic}->{$name} = {
                display => $name,
                traffic_in => $result->{$container_id}->{Stats}->{networks}->{$interface}->{rx_bytes} * 8,
                traffic_out => $result->{$container_id}->{Stats}->{networks}->{$interface}->{tx_bytes} * 8,
            };
        }
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No container found.");
        $self->{output}->option_exit();
    }
    
    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = "docker_" . $self->{mode} . '_' . join('_', @$hostnames) . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{container_id}) ? md5_hex($self->{option_results}->{container_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{container_name}) ? md5_hex($self->{option_results}->{container_name}) : md5_hex('all'));
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

Use docker name for perfdata and display.

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
