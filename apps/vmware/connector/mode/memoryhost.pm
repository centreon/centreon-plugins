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

package apps::vmware::connector::mode::memoryhost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'host.memory.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf(
        "Memory 'consumed' Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    
    if ($self->{result_values}->{total} <= 0) {
        $self->{error_msg} = 'size is 0';
        return -20;
    }
    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_consumed'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_overhead_output {
    my ($self, %options) = @_;

    my ($overhead_value, $overhead_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{overhead});
    return sprintf(
        "Memory Overhead: %s",
        $overhead_value . " " . $overhead_unit
    );
}

sub custom_memstate_output {
    my ($self, %options) = @_;

    return 'Memory state is ' . $self->{result_values}->{mem_state_str};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 1, cb_prefix_output => 'prefix_host_output', message_multiple => 'All hosts are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{host} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'consumed-memory', nlabel => 'host.memory.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'consumed' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'overhead-memory', nlabel => 'host.memory.overhead.bytes', set => {
                key_values => [ { name => 'overhead' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_overhead_output'),
                perfdatas => [
                    { label => 'overhead', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'state-memory', nlabel => 'host.memory.state.count', set => {
                key_values => [ { name => 'mem_state' }, { name => 'mem_state_str' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memstate_output'),
                perfdatas => [
                    { label => 'state', template => '%s', 
                      min => 0, max => 3, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'esx-hostname:s'     => { name => 'esx_hostname' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'scope-cluster:s'    => { name => 'scope_cluster' },
        'units:s'            => { name => 'units', default => '%' },
        'free'               => { name => 'free' },
        'no-memory-state'    => { name => 'no_memory_state' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'memhost'
    );

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { 
            display => $host_name, 
            state => $response->{data}->{$host_id}->{state},
            consumed => $response->{data}->{$host_id}->{'mem.consumed.average'},
            overhead => $response->{data}->{$host_id}->{'mem.overhead.average'},
            mem_state => $response->{data}->{$host_id}->{mem_state},
            mem_state_str => $response->{data}->{$host_id}->{mem_state_str},
            total => $response->{data}->{$host_id}->{mem_size}
        };        
    }    
}

1;

__END__

=head1 MODE

Check ESX memory usage.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} !~ /^connected$/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-consumed-memory>

Threshold warning (can use unit option).

=item B<--critical-consumed-memory>

Threshold critical (can use unit option).

=item B<--warning-overhead-memory>

Threshold overhead.

=item B<--critical-overhead-memory>

Threshold critical.

=item B<--warning-state-memory>

Threshold warning. For state != 'high': --warning-state=0

=item B<--critical-state-memory>

Threshold critical. For state != 'high': --warning-state=0

=item B<--no-memory-state>

Don't check memory state.

=back

=cut
