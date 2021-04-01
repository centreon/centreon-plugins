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

package apps::oracle::ovm::api::mode::serverpools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_memory});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_memory});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_memory});
    return sprintf(
        'memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_memory},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_memory}
    );
}

sub pool_long_output {
    my ($self, %options) = @_;

    return "checking server pool '" . $options{instance_value}->{name} . "'";
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return "Server pool '" . $options{instance_value}->{name} . "' ";
}

sub prefix_servers_output {
    my ($self, %options) = @_;

    return 'servers ';
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return 'virtual machines ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pools', type => 3, cb_prefix_output => 'prefix_pool_output', cb_long_output => 'pool_long_output', indent_long_output => '    ', message_multiple => 'All server pools are ok',
            group => [
                { name => 'servers', type => 0, cb_prefix_output => 'prefix_servers_output' },
                { name => 'vm', type => 0, cb_prefix_output => 'prefix_vm_output' },
                { name => 'memory', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{servers} = [
        { label => 'servers-running', nlabel => 'serverpool.servers.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'servers-stopped', nlabel => 'serverpool.servers.stopped.count', set => {
                key_values => [ { name => 'stopped' }, { name => 'total' } ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'vm-running', nlabel => 'serverpool.vm.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'vm-stopped', nlabel => 'serverpool.vm.stopped.count', set => {
                key_values => [ { name => 'stopped' }, { name => 'total' } ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'serverpool.memory.usage.bytes', set => {
                key_values => [ { name => 'used_memory' }, { name => 'free_memory' }, { name => 'prct_used_memory' }, { name => 'prct_free_memory' }, { name => 'total_memory' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_memory', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', nlabel => 'serverpool.memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_memory' }, { name => 'used_memory' }, { name => 'prct_used_memory' }, { name => 'prct_free_memory' }, { name => 'total_memory' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_memory', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'serverpool.memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_memory' }, { name => 'used_memory' }, { name => 'free_memory' }, { name => 'prct_free_memory' }, { name => 'total_memory' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-server-pool-name:s' => { name => 'filter_server_pool_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $manager = $options{custom}->request_api(endpoint => '/Manager');
    if ($manager->[0]->{managerRunState} ne 'RUNNING') {
        $self->{output}->add_option_msg(short_msg => 'manager is not running.');
        $self->{output}->option_exit();
    }

    my $pools = $options{custom}->request_api(endpoint => '/ServerPool');
    my $vms = $options{custom}->request_api(endpoint => '/Vm');
    my $servers = $options{custom}->request_api(endpoint => '/Server');

    $self->{pools} = {};
    foreach (@$pools) {
        my $name = $_->{id}->{value};
        $name = $_->{name}
            if (defined($_->{name}) && $_->{name} ne '');

        if (defined($self->{option_results}->{filter_server_pool_name}) && $self->{option_results}->{filter_server_pool_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_server_pool_name}/) {
            $self->{output}->output_add(long_msg => "skipping server pool '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pools}->{$name} = {
            name => $name,
            memory => {
                total_memory => 0,
                free_memory => 0
            },
            servers => {
                total => 0, running => 0, stopped => 0
            },
            vm => {
                total => 0, running => 0, stopped => 0
            }
        };

        foreach my $server (@{$_->{serverIds}}) {
            foreach my $target (@$servers) {
                if ($server->{value} eq $target->{id}->{value}) {
                    $self->{pools}->{$name}->{memory}->{total_memory} += ($target->{memory} * 1024 * 1024);
                    $self->{pools}->{$name}->{memory}->{free_memory} += ($target->{usableMemory} * 1024 * 1024);
                    $self->{pools}->{$name}->{servers}->{ lc($target->{serverRunState}) }++
                        if (defined($self->{pools}->{$name}->{servers}->{ lc($target->{serverRunState}) }));
                    $self->{pools}->{$name}->{servers}->{total}++;
                    last;
                }
            }
        }

        foreach my $vm (@{$_->{vmIds}}) {
            foreach my $target (@$vms) {
                if ($vm->{value} eq $target->{id}->{value}) {
                    $self->{pools}->{$name}->{vm}->{ lc($target->{vmRunState}) }++
                        if (defined($self->{pools}->{$name}->{vm}->{ lc($target->{vmRunState}) }));
                    $self->{pools}->{$name}->{vm}->{total}++;
                    last;
                }
            }
        }

        $self->{pools}->{$name}->{memory}->{used_memory} = $self->{pools}->{$name}->{memory}->{total_memory} - $self->{pools}->{$name}->{memory}->{free_memory};
        $self->{pools}->{$name}->{memory}->{prct_used_memory} = $self->{pools}->{$name}->{memory}->{used_memory} * 100 / $self->{pools}->{$name}->{memory}->{total_memory};
        $self->{pools}->{$name}->{memory}->{prct_free_memory} = 100 - $self->{pools}->{$name}->{memory}->{prct_used_memory};
    }
}

1;

__END__

=head1 MODE

Check servers.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-usage$'

=item B<--filter-server-pool-name>

Filter server pools by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'servers-running', 'servers-stopped', 'vm-running', 'vm-stopped',
'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct' (%).

=back

=cut
