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

package apps::proxmox::ve::restapi::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state : ' . $self->{result_values}->{state};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    return 0;
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $delta_cpu_total = $options{new_datas}->{$self->{instance} . '_cpu_total_usage'} - $options{old_datas}->{$self->{instance} . '_cpu_total_usage'};
    $self->{result_values}->{prct_cpu} = (($delta_cpu_total)  * 100);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub custom_memory_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'memory_used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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
        'Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
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
        label => 'swap_used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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
        'Swap Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
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

sub custom_fs_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'fs_used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_fs_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_fs_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'Root Filesystem Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_fs_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_fs_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_fs_usage'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All nodes are ok', skipped_code => { -10 => 1, -11 => 1 } },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node-status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'cpu', set => {
                key_values => [ { name => 'cpu_total_usage', diff => 1 }, { name => 'cpu_number' }, { name => 'display' } ],
                output_template => 'CPU Usage : %.2f %%',
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_use => 'prct_cpu', threshold_use => 'prct_cpu',
                perfdatas => [
                    { label => 'cpu', value => 'prct_cpu', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'memory_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_output => $self->can('custom_memory_output'),
                closure_custom_perfdata => $self->can('custom_memory_perfdata'),
                closure_custom_threshold_check => $self->can('custom_memory_threshold'),
            }
        },
        { label => 'fs', set => {
                key_values => [ { name => 'fs_usage' }, { name => 'fs_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_fs_calc'),
                closure_custom_output => $self->can('custom_fs_output'),
                closure_custom_perfdata => $self->can('custom_fs_perfdata'),
                closure_custom_threshold_check => $self->can('custom_fs_threshold'),
            }
        },
        { label => 'swap', set => {
                key_values => [ { name => 'swap_usage' }, { name => 'swap_total' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_swap_calc'),
                closure_custom_output => $self->can('custom_swap_output'),
                closure_custom_perfdata => $self->can('custom_swap_perfdata'),
                closure_custom_threshold_check => $self->can('custom_swap_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'node-id:s'                 => { name => 'node_id' },
        'node-name:s'               => { name => 'node_name' },
        'filter-name:s'             => { name => 'filter_name' },
        'use-name'                  => { name => 'use_name' },
        'warning-node-status:s'     => { name => 'warning_node_status', default => '' },
        'critical-node-status:s'    => { name => 'critical_node_status', default => '' },
    });

    $self->{statefile_cache_nodes} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_node_status', 'critical_node_status']);
    $self->{statefile_cache_nodes}->check_options(%options);
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $result = $options{custom}->api_get_nodes(
        node_id => $self->{option_results}->{node_id},
        node_name => $self->{option_results}->{node_name},
        statefile => $self->{statefile_cache_nodes}
    );

    foreach my $node_id (keys %{$result}) {
        next if (!defined($result->{$node_id}->{Stats}));

        my $name = $result->{$node_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{nodes}->{$node_id} = {
            display => defined($self->{option_results}->{use_name}) ? $name : $node_id,
            name => $name,
            state => $result->{$node_id}->{State},
            cpu_total_usage => $result->{$node_id}->{Stats}->{cpu},
            cpu_number => $result->{$node_id}->{Stats}->{cpuinfo}->{cpus},
            memory_usage => $result->{$node_id}->{Stats}->{memory}->{used},
            memory_total => $result->{$node_id}->{Stats}->{memory}->{total},
            swap_usage => $result->{$node_id}->{Stats}->{swap}->{used},
            swap_total => 
                defined($result->{$node_id}->{Stats}->{swap}->{total}) && $result->{$node_id}->{Stats}->{swap}->{total} > 0 ? $result->{$node_id}->{Stats}->{swap}->{total} : undef,
            fs_usage => $result->{$node_id}->{Stats}->{rootfs}->{used},
            fs_total => $result->{$node_id}->{Stats}->{rootfs}->{total},
        };
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No node found.");
        $self->{output}->option_exit();
    }

    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = "proxmox_" . $self->{mode} . '_' .$hostnames . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{node_id}) ? md5_hex($self->{option_results}->{node_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{node_name}) ? md5_hex($self->{option_results}->{node_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check node usage.

=over 8

=item B<--node-id>

Exact node ID.

=item B<--node-name>

Exact node name (if multiple names: names separated by ':').

=item B<--use-name>

Use node name for perfdata and display.

=item B<--filter-name>

Filter by node name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^node-status$'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu' (%), 'memory' (%), 'swap' (%), 'fs' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'cpu' (%), 'memory' (%), 'swap' (%), 'fs' (%).

=item B<--warning-node-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{state}.

=item B<--critical-node-status>

Set critical threshold for status (Default: -).
Can used special variables like: %{name}, %{state}.

=back

=cut
