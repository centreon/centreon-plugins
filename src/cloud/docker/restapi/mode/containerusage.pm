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

package cloud::docker::restapi::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'state: ' . $self->{result_values}->{state};
    if (defined($self->{instance_mode}->{option_results}->{add_health})) {
        $msg .= ' [health: ' . $self->{result_values}->{health} . ']';
    }
    return $msg;
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_total = $options{new_datas}->{$self->{instance} . '_cpu_total_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_total_usage'};
    my $delta_cpu_system = $options{new_datas}->{$self->{instance} . '_cpu_system_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_system_usage'};
    # container is not running
    return -10 if ($options{new_datas}->{$self->{instance} . '_cpu_system_usage'} == 0);

    if ($delta_cpu_system == 0) {
        $self->{result_values}->{prct_cpu} = 0;
    } else {
        $self->{result_values}->{prct_cpu} = (($delta_cpu_total / $delta_cpu_system) * $options{new_datas}->{$self->{instance} . '_cpu_number'}) * 100;
    }
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
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used}, threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        "memory total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
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
    # container is not running
    return -10 if ($self->{result_values}->{used} == 0);

    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub prefix_containers_traffic_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub prefix_containers_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output', message_multiple => 'All containers are ok', skipped_code => { -10 => 1, -11 => 1 } },
        { name => 'containers_traffic', type => 1, cb_prefix_output => 'prefix_containers_traffic_output', message_multiple => 'All container traffics are ok', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{containers} = [
         { label => 'container-status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'health' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu', nlabel => 'container.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_total_usage', diff => 1 }, { name => 'cpu_system_usage', diff => 1 }, { name => 'cpu_number' }, { name => 'display' } ],
                output_template => 'cpu usage: %.2f %%',
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
                output_template => 'read IOPs: %.2f',
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'container.disk.io.write.usage.iops', set => {
                key_values => [ { name => 'write_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'write IOPs: %.2f',
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
                output_template => 'traffic in: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out',  nlabel => 'container.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'traffic out: %s %s/s',
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
        'use-name'         => { name => 'use_name' },
        'add-health'       => { name => 'add_health' },
        'no-stats'         => { name => 'no_stats' }
    });

    $self->{statefile_cache_containers} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_containers}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->api_get_containers(
        container_id => $self->{option_results}->{container_id}, 
        container_name => $self->{option_results}->{container_name},
        statefile => $self->{statefile_cache_containers},
        add_health => $self->{option_results}->{add_health},
        no_stats => $self->{option_results}->{no_stats}
    );

    $self->{containers} = {};
    $self->{containers_traffic} = {};
    foreach my $container_id (keys %$result) {

        my $name = $result->{$container_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{containers}->{$container_id} = {
            display => defined($self->{option_results}->{use_name}) ? $name : $container_id,
            health => defined($result->{$container_id}->{Inspector}) ? $result->{$container_id}->{Inspector}->{State}->{Health}->{Status} : '-',
            name => $name,
            state => $result->{$container_id}->{State}
        };

        next if (!defined($result->{$container_id}->{Stats}));

        my $read_io = $result->{$container_id}->{Stats}->{blkio_stats}->{io_service_bytes_recursive}->[0]->{value};
        my $write_io = $result->{$container_id}->{Stats}->{blkio_stats}->{io_service_bytes_recursive}->[1]->{value};

        $self->{containers}->{$container_id}->{read_io} = $read_io;
        $self->{containers}->{$container_id}->{write_io} = $write_io;
        $self->{containers}->{$container_id}->{cpu_total_usage} = $result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{total_usage};
        $self->{containers}->{$container_id}->{cpu_system_usage} = $result->{$container_id}->{Stats}->{cpu_stats}->{system_cpu_usage};
        
        $self->{containers}->{$container_id}->{cpu_number} = 1;
        if (defined($result->{$container_id}->{Stats}->{cpu_stats}->{online_cpus})) {
            $self->{containers}->{$container_id}->{cpu_number} = $result->{$container_id}->{Stats}->{cpu_stats}->{online_cpus};
        } elsif (defined($result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{percpu_usage})) {
            $self->{containers}->{$container_id}->{cpu_number} = scalar(@{$result->{$container_id}->{Stats}->{cpu_stats}->{cpu_usage}->{percpu_usage}});
        }

        $self->{containers}->{$container_id}->{memory_usage} = $result->{$container_id}->{Stats}->{memory_stats}->{usage} - $result->{$container_id}->{Stats}->{memory_stats}->{stats}->{inactive_file} // 0;
        $self->{containers}->{$container_id}->{memory_total} = $result->{$container_id}->{Stats}->{memory_stats}->{limit};

        foreach my $interface (keys %{$result->{$container_id}->{Stats}->{networks}}) {
            my $name = defined($self->{option_results}->{use_name}) ? $name : $container_id;
            $name .= '.' . $interface;
            $self->{containers_traffic}->{$name} = {
                display => $name,
                traffic_in => $result->{$container_id}->{Stats}->{networks}->{$interface}->{rx_bytes} * 8,
                traffic_out => $result->{$container_id}->{Stats}->{networks}->{$interface}->{tx_bytes} * 8
            };
        }
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No container found.');
        $self->{output}->option_exit();
    }

    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = 'docker_' . $self->{mode} . '_' . join('_', @$hostnames) . '_' . $options{custom}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{container_id}) ? $self->{option_results}->{container_id} : '') . '_' .
            (defined($self->{option_results}->{container_name}) ? $self->{option_results}->{container_name} : '')
        );
}

1;

__END__

=head1 MODE

Check container usage.

=over 8

=item B<--container-id>

Set the container ID.

=item B<--container-name>

Set the container name(s). Multiple container names should be separated by ':'.
Example: C<--container-name='container1:container2'>.

=item B<--use-name>

Use the docker name for perfdata and display.

=item B<--add-health>

Get the container health status by calling the  /inspector endpoint.

=item B<--no-stats>

Don't get container statistics.

=item B<--filter-name>

Filter by container name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='^container-status$'>

=item B<--warning-container-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{state}>, C<%{health}>.

=item B<--critical-container-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{name}>, C<%{state}>, C<%{health}>.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out', 
'cpu' (%), 'memory' (%).

=back

=cut
