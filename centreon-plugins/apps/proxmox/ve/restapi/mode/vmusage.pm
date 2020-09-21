#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used},
                                                  threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => 1, cb_prefix_output => 'prefix_vms_output', message_multiple => 'All vms are ok', skipped_code => { -11 => 1 } },
        { name => 'vms_traffic', type => 1, cb_prefix_output => 'prefix_vms_traffic_output', message_multiple => 'All vm traffics are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{vms} = [
         { label => 'vm-status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu', set => {
                key_values => [ { name => 'cpu_total_usage', diff => 1 }, { name => 'cpu_number' }, { name => 'display' } ],
                output_template => 'CPU Usage : %.2f %%',
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_use => 'prct_cpu', threshold_use => 'prct_cpu',
                perfdatas => [
                    { label => 'cpu', value => 'prct_cpu', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
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
        { label => 'read-iops', set => {
                key_values => [ { name => 'read_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Read IOPs : %.2f', output_error_template => "Read IOPs : %s",
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'write_io', per_second => 1 }, { name => 'display' } ],
                output_template => 'Write IOPs : %.2f', output_error_template => "Write IOPs : %s",
                perfdatas => [
                    { label => 'write_iops', template => '%.2f',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        }
    ];

    $self->{maps_counters}->{vms_traffic} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', set => {
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
        'vm-id:s'       => { name => 'vm_id' },
        'vm-name:s'     => { name => 'vm_name' },
        'filter-name:s' => { name => 'filter_name' },
        'use-name'      => { name => 'use_name' }
    });

    $self->{statefile_cache_vms} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_vms}->check_options(%options);
}

sub prefix_vms_traffic_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub prefix_vms_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vms} = {};
    $self->{vms_traffic} = {};

    my $result = $options{custom}->api_get_vms(
        vm_id => $self->{option_results}->{vm_id},
        vm_name => $self->{option_results}->{vm_name},
        statefile => $self->{statefile_cache_vms}
    );

    foreach my $vm_id (keys %{$result}) {
        next if (!defined($result->{$vm_id}->{Stats}));

        my $name = $result->{$vm_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vms}->{$vm_id} = {
            display => defined($self->{option_results}->{use_name}) ? $name : $vm_id,
            name => $name,
            state => $result->{$vm_id}->{State},
            read_io => $result->{$vm_id}->{Stats}->{diskread},
            write_io => $result->{$vm_id}->{Stats}->{diskwrite},
            cpu_total_usage => $result->{$vm_id}->{Stats}->{cpu},
            cpu_number => $result->{$vm_id}->{Stats}->{cpus},
            memory_usage => $result->{$vm_id}->{Stats}->{mem},
            memory_total => $result->{$vm_id}->{Stats}->{maxmem},
            swap_usage => $result->{$vm_id}->{Stats}->{swap},
            swap_total => defined($result->{$vm_id}->{Stats}->{maxswap}) && $result->{$vm_id}->{Stats}->{maxswap} > 0 ? $result->{$vm_id}->{Stats}->{maxswap} : undef
        };
        $self->{vms_traffic}->{$name} = {
            display => $name,
            traffic_in => $result->{$vm_id}->{Stats}->{netin} * 8,
            traffic_out => $result->{$vm_id}->{Stats}->{netout} * 8
        };
    }

    if (scalar(keys %{$self->{vms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vm found.");
        $self->{output}->option_exit();
    }

    my $hostnames = $options{custom}->get_hostnames();
    $self->{cache_name} = "proxmox_" . $self->{mode} . '_' .$hostnames . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{vm_id}) ? md5_hex($self->{option_results}->{vm_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{vm_name}) ? md5_hex($self->{option_results}->{vm_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check VM usage on Proxmox VE Cluster.

=over 8

=item B<--vm-id>

Exact VM ID.

=item B<--vm-name>

Exact VM name (if multiple names: names separated by ':').

=item B<--use-name>

Use VM name for perfdata and display.

=item B<--filter-name>

Filter by vm name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^vm-status$'

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out',
'cpu' (%), 'memory' (%), 'swap' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'write-iops', 'traffic-in', 'traffic-out',
'cpu' (%), 'memory' (%), 'swap' (%).

=item B<--warning-vm-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{state}.

=item B<--critical-vm-status>

Set critical threshold for status (Default: -).
Can used special variables like: %{name}, %{state}.

=back

=cut
