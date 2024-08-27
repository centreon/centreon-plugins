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

package apps::virtualization::hpe::simplivity::restapi::mode::virtualmachines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub vm_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking virtual machine '%s'",
        $options{instance}
    );
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return sprintf(
        "virtual machine '%s' ",
        $options{instance}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 3, cb_prefix_output => 'prefix_vm_output', cb_long_output => 'vm_long_output', indent_long_output => '    ', message_multiple => 'All virtual machines are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'ha-status',
            type => 2,
            unknown_default => '%{ha_status} =~ /unknown/',
            warning_default => '%{ha_status} =~ /degraded/',
            set => {
                key_values => [ { name => 'ha_status' }, { name => 'vm_name' } ],
                output_template => 'high-availability status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'virtual_machine.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'virtual_machine.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'virtual_machine.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
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
        'filter-vm-name:s' => { name => 'filter_vm_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vms = $options{custom}->get_virtual_machines();

    $self->{vm} = {};
    foreach my $vm (@{$vms->{virtual_machines}}) {
        if (defined($self->{option_results}->{filter_vm_name}) && $self->{option_results}->{filter_vm_name} ne '' &&
            $vm->{name} !~ /$self->{option_results}->{filter_vm_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vm->{name}  . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vm}->{ $vm->{id} . ':' . $vm->{name} } = {
            status => {
                vm_name => $vm->{id} . ':' . $vm->{name},
                ha_status => lc($vm->{ha_status})
            },
            space => {
                total_space => $vm->{hypervisor_allocated_capacity},
                used_space => $vm->{hypervisor_allocated_capacity} - $vm->{hypervisor_free_space},
                free_space => $vm->{hypervisor_free_space},
                prct_used_space => ($vm->{hypervisor_allocated_capacity} - $vm->{hypervisor_free_space}) * 100 / $vm->{hypervisor_allocated_capacity},
                prct_free_space => $vm->{hypervisor_free_space} * 100 / $vm->{hypervisor_allocated_capacity}
            }
        };
    }
}


1;

__END__

=head1 MODE

Check virtual machines.

=over 8

=item B<--filter-vm-name>

Filter virtual machines by virtual machine name.

=item B<--unknown-ha-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown/').
You can use the following variables: %{ha_status}, %{vm_name}

=item B<--warning-ha-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /degraded/').
You can use the following variables: %{ha_status}, %{vm_name}

=item B<--critical-ha-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{ha_status}, %{vm_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct'.

=back

=cut
