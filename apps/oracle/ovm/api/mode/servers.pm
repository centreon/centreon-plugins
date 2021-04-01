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

package apps::oracle::ovm::api::mode::servers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'running state: %s [up2date: %s][maintenance: %s]',
         $self->{result_values}->{running_state},
         $self->{result_values}->{up2date},
         $self->{result_values}->{is_maintenance}
    );
}

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

sub prefix_server_output {
    my ($self, %options) = @_;
    
    return "Server '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Servers ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'servers', type => 1, cb_prefix_output => 'prefix_server_output', message_multiple => 'All servers are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'servers-running', nlabel => 'servers.running.count', display_ok => 0, set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'servers-stopped', nlabel => 'servers.stopped.count', display_ok => 0, set => {
                key_values => [ { name => 'stopped' }, { name => 'total' } ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{servers} = [
        { label => 'status', threshold => 2, set => {
                key_values => [
                    { name => 'running_state' }, { name => 'up2date' },
                    { name => 'is_maintenance' },{ name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'memory-usage', nlabel => 'server.memory.usage.bytes', set => {
                key_values => [ { name => 'used_memory' }, { name => 'free_memory' }, { name => 'prct_used_memory' }, { name => 'prct_free_memory' }, { name => 'total_memory' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_memory', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', nlabel => 'server.memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_memory' }, { name => 'used_memory' }, { name => 'prct_used_memory' }, { name => 'prct_free_memory' }, { name => 'total_memory' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_memory', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'server.memory.usage.percentage', display_ok => 0, set => {
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
        'filter-name:s' => { name => 'filter_name' }
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

    my $servers = $options{custom}->request_api(endpoint => '/Server');

    $self->{global} = { running => 0, stopped => 0, total => 0 };
    $self->{servers} = {};
    foreach (@$servers) {
        my $name = $_->{id}->{value};
        $name = $_->{name}
            if (defined($_->{name}) && $_->{name} ne '');

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping server '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        my $total_memory = $_->{memory} * 1024 * 1024;
        my $usable_memory = $_->{usableMemory} * 1024 * 1024;
        $self->{servers}->{$name} = {
            name => $name,
            running_state => lc($_->{serverRunState}),
            is_maintenance => $_->{maintenanceMode} =~ /True|1/i ? 'yes' : 'no',
            up2date => $_->{serverUpToDate} =~ /True|1/i ? 'yes' : 'no',

            total_memory => $total_memory,
            used_memory => $total_memory - $usable_memory,
            free_memory => $usable_memory,
            prct_used_memory => ($total_memory - $usable_memory) * 100 / $total_memory,
            prct_free_memory => $usable_memory * 100 / $total_memory
        };
        $self->{global}->{ lc($_->{serverRunState}) }++
            if (defined($self->{global}->{ lc($_->{serverRunState}) }));
        $self->{global}->{total}++;
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

=item B<--filter-name>

Filter servers by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{running_status}, %{is_maintenance}, %{up2date}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{running_status}, %{is_maintenance}, %{up2date}, %{name}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{running_status}, %{is_maintenance}, %{up2date}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'servers-running', 'servers-stopped',
'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct' (%).

=back

=cut
