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

package apps::vmware::connector::mode::memoryvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return '[connection state ' . $self->{result_values}->{connection_state} . '][power state ' . $self->{result_values}->{power_state} . ']';
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'vm.memory.' . $self->{result_values}->{label_ref} . '.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label_ref} . '_' . $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{instance} : undef,
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
        'Memory %s Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $self->{result_values}->{label_ref},
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    
    if ($self->{result_values}->{total} <= 0) {
        $self->{error_msg} = 'size is 0';
        return -20;
    }

    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref}};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_overhead_output {
    my ($self, %options) = @_;

    my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{overhead});
    return sprintf('Memory overhead: %s %s', $value, $unit);
}

sub custom_ballooning_output {
    my ($self, %options) = @_;

    my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{vmmemctl});
    return sprintf('Memory ballooning: %s %s', $value, $unit);
}

sub custom_shared_output {
    my ($self, %options) = @_;

    my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{shared});
    return sprintf('Memory shared: %s %s', $value, $unit);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 3, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', indent_long_output => '    ', message_multiple => 'All virtual machines are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_consumed', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_active', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_overhead', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_vmmemctl', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_shared', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i',
            set => {
                key_values => [ { name => 'connection_state' }, { name => 'power_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    $self->{maps_counters}->{global_consumed} = [
        { label => 'consumed', nlabel => 'vm.memory.consumed.usage.bytes', set => {
                key_values => [ { name => 'consumed' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'consumed' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];

    $self->{maps_counters}->{global_active} = [
        { label => 'active', nlabel => 'vm.memory.active.usage.bytes', set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'active' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];

    $self->{maps_counters}->{global_overhead} = [
        { label => 'overhead', nlabel => 'vm.memory.overhead.bytes', set => {
                key_values => [ { name => 'overhead' } ],
                closure_custom_output => $self->can('custom_overhead_output'),
                perfdatas => [
                    { label => 'overhead', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_vmmemctl} = [
        { label => 'ballooning', nlabel => 'vm.memory.ballooning.bytes', set => {
                key_values => [ { name => 'vmmemctl' } ],
                closure_custom_output => $self->can('custom_ballooning_output'),
                perfdatas => [
                    { label => 'ballooning', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_shared} = [
        { label => 'shared', nlabel => 'vm.memory.shared.bytes', set => {
                key_values => [ { name => 'shared' } ],
                closure_custom_output => $self->can('custom_shared_output'),
                perfdatas => [
                    { label => 'shared', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    my $msg = "Virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }
    $msg .= ' : ';

    return $msg;
}

sub vm_long_output {
    my ($self, %options) = @_;

    my $msg = "checking virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }

    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'vm-hostname:s'        => { name => 'vm_hostname' },
        'filter'               => { name => 'filter' },
        'scope-datacenter:s'   => { name => 'scope_datacenter' },
        'scope-cluster:s'      => { name => 'scope_cluster' },
        'scope-host:s'         => { name => 'scope_host' },
        'filter-description:s' => { name => 'filter_description' },
        'filter-os:s'          => { name => 'filter_os' },
        'filter-uuid:s'        => { name => 'filter_uuid' },
        'display-description'  => { name => 'display_description' },
        'units:s'              => { name => 'units', default => '%' },
        'free'                 => { name => 'free' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vm} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'memvm'
    );

    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};

        $self->{vm}->{$vm_name} = { display => $vm_name, 
            global => {
                connection_state => $response->{data}->{$vm_id}->{connection_state},
                power_state => $response->{data}->{$vm_id}->{power_state}
            }
        };

        foreach (('consumed', 'active', 'overhead', 'vmmemctl', 'shared')) {
            next if (!defined($response->{data}->{$vm_id}->{'mem.' . $_ . '.average'}));
            $self->{vm}->{$vm_name}->{'global_' . $_} = {
                $_ => $response->{data}->{$vm_id}->{'mem.' . $_ . '.average'},
                total => $response->{data}->{$vm_id}->{memory_size}
            };
        }

        if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }
    }
}

1;

__END__

=head1 MODE

Check virtual machine memory.

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--display-description>

Display virtual machine description.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i or %{power_state}  !~ /^poweredOn$/i').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{connection_state}, %{power_state}

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-*>

Threshold warning.
Can be: 'consumed', 'active', 'overhead', 'ballooning', 'shared'.

=item B<--critical-*>

Threshold critical.
Can be: 'consumed', 'active', 'overhead', 'ballooning', 'shared'.

=back

=cut
