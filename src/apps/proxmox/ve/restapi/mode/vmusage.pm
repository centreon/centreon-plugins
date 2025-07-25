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

package apps::proxmox::ve::restapi::mode::vmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state : ' . $self->{result_values}->{state};
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_total = $options{new_datas}->{$self->{instance} . '_cpu_total_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_total_usage'};
    $self->{result_values}->{prct_cpu} = $delta_cpu_total  * 100;
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'vm.memory.usage.bytes',
        unit => 'B',
        instances => $self->{result_values}->{display},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_memory_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'memory total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
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

sub custom_swap_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'vm.swap.usage.bytes',
        unit => 'B',
        instances => $self->{result_values}->{display},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_swap_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_swap_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'swap total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_swap_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_swap_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_swap_usage'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub prefix_vms_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => 1, cb_prefix_output => 'prefix_vms_output', message_multiple => 'All vms are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{vms} = [
         { label => 'vm-status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu', nlabel => 'vm.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_total_usage', diff => 1 }, { name => 'cpu_number' }, { name => 'display' } ],
                output_template => 'cpu usage: %.2f %%',
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_use => 'prct_cpu', threshold_use => 'prct_cpu',
                perfdatas => [
                    { value => 'prct_cpu', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'memory_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_output => $self->can('custom_memory_output'),
                closure_custom_perfdata => $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check => $self->can('custom_memory_threshold')
            }
        },
        { label => 'read-iops', nlabel => 'vm.read.usage.iops', set => {
                key_values => [ { name => 'read_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'read iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'vm.write.usage.iops', set => {
                key_values => [ { name => 'write_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'write iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'swap', set => {
                key_values => [ { name => 'swap_usage' }, { name => 'swap_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_swap_calc'),
                closure_custom_output => $self->can('custom_swap_output'),
                closure_custom_perfdata => $self->can('custom_swap_perfdata'),
                closure_custom_threshold_check => $self->can('custom_swap_threshold')
            }
        },
        { label => 'traffic-in', nlabel => 'vm.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'traffic in: %s %s/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'vm.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'traffic out: %s %s/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'vm-id:s'             => { name => 'vm_id' },
        'vm-name:s'           => { name => 'vm_name' },
        'filter-name:s'       => { name => 'filter_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'include-node-name:s' => { name => 'include_node_name' },
        'use-name'            => { name => 'use_name' }
    });

    $self->{statefile_cache_vms} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_vms}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->api_get_vms(
        vm_id => $self->{option_results}->{vm_id},
        vm_name => $self->{option_results}->{vm_name},
        statefile => $self->{statefile_cache_vms}
    );

    $self->{vms} = {};
    $self->{vms_traffic} = {};
    foreach my $vm_id (keys %{$result}) {
        next if (!defined($result->{$vm_id}->{Stats}));

        my $vm_name = $result->{$vm_id}->{Name};
        my $node_name = $result->{$vm_id}->{Node};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $vm_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vm_name . "': no matching with include filter:" . $self->{option_results}->{filter_name}, debug => 1);
            next;
        }
        if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $vm_name =~ /$self->{option_results}->{exclude_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vm_name . "': no matching with exclude filter: " . $self->{option_results}->{exclude_name}, debug => 1);
            next;
        }
        if (defined($self->{option_results}->{include_node_name}) && $self->{option_results}->{include_node_name} ne '' &&
            $node_name !~ /$self->{option_results}->{include_node_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node_name . "': not running on include node:" . $self->{option_results}->{include_node_name}, debug => 1);
            next;
        }

        $self->{vms}->{$vm_id} = {
            display => defined($self->{option_results}->{use_name}) ? $vm_name : $vm_id,
            name => $vm_name,
            state => $result->{$vm_id}->{State},
            read_io => $result->{$vm_id}->{Stats}->{diskread},
            write_io => $result->{$vm_id}->{Stats}->{diskwrite},
            cpu_total_usage => $result->{$vm_id}->{Stats}->{cpu},
            cpu_number => $result->{$vm_id}->{Stats}->{cpus},
            memory_usage => $result->{$vm_id}->{Stats}->{mem},
            memory_total => $result->{$vm_id}->{Stats}->{maxmem},
            swap_usage => $result->{$vm_id}->{Stats}->{swap},
            swap_total => defined($result->{$vm_id}->{Stats}->{maxswap}) && $result->{$vm_id}->{Stats}->{maxswap} > 0 ? $result->{$vm_id}->{Stats}->{maxswap} : undef,
            traffic_in => $result->{$vm_id}->{Stats}->{netin} * 8,
            traffic_out => $result->{$vm_id}->{Stats}->{netout} * 8
        };
    }

    if (scalar(keys %{$self->{vms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vm found.");
        $self->{output}->option_exit();
    }

    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = 'proxmox_' . $self->{mode} . '_' .$hostnames . '_' . $options{custom}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_name}) ? $self->{option_results}->{exclude_name} : '') . '_' .
            (defined($self->{option_results}->{include_node_name}) ? $self->{option_results}->{include_node_name} : '') . '_' .
            (defined($self->{option_results}->{vm_id}) ? $self->{option_results}->{vm_id} : '') . '_' .
            (defined($self->{option_results}->{vm_name}) ? $self->{option_results}->{vm_name} : '')
        );
}

1;

__END__

=head1 MODE

Check virtual machines usage on Proxmox VE Cluster.

=over 8

=item B<--vm-id>

Exact virtual machine ID.

=item B<--vm-name>

Exact virtual machine name (if multiple names: names separated by ':').

=item B<--use-name>

Use virtual machine name for perfdata and display.

=item B<--include-node-name>

Filter only virtual machine running on specified node name (can be a regexp).

=item B<--filter-name>

Filter by virtual machine name (can be a regexp).

=item B<--exclude-name>

Exclude by virtual machine name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='^vm-status$'>

=item B<--warning-*>

Warning threshold.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out',
'cpu' (%), 'memory' (%), 'swap' (%).

=item B<--critical-*>

Critical threshold.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out',
'cpu' (%), 'memory' (%), 'swap' (%).

=item B<--warning-vm-status>

Define the conditions to match for the status to be WARNING (default: -)
You can use the following variables: %{name}, %{state}.

=item B<--critical-vm-status>

Define the conditions to match for the status to be CRITICAL (default: -).
You can use the following variables: %{name}, %{state}.

=back

=cut
