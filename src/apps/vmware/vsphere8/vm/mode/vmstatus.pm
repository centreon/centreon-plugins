#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vm::mode::vmstatus;

use base qw(apps::vmware::vsphere8::vm::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_power_status_output {
    my ($self, %options) = @_;

    return 'power state is ' . $self->{result_values}->{power_state};
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "', id: '" . $options{instance_value}->{id} . "': ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'vm',
            type             => 1,
            cb_prefix_output => 'prefix_vm_output',
            message_multiple => 'All VMs are ok'
        }
    ];

    $self->{maps_counters}->{vm} = [
        {
            label => 'power-status',
            type => 2,
            critical_default => '%{power_state} !~ /^powered_on$/i',
            set => {
                key_values => [ { name => 'display' }, { name => 'power_state' }, { name => 'id' } ],
                closure_custom_output          => $self->can('custom_power_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vm = $self->get_vm(%options);

    $self->{vm}->{$vm->{vm}} = {
        display          => $vm->{name},
        power_state      => $vm->{power_state},
        id               => $vm->{vm}
    };

    return 1;
}

1;

__END__

=head1 MODE

Monitor the status of VMware VMs through vSphere 8 REST API.

=over 8

=item B<--warning-power-status>

Define the warning threshold for the power status of the VM.
The value should be a Perl expression using the %{power_state} macro.

=item B<--critical-power-status>

Define the critical threshold for the power status of the VM.
The value should be a Perl expression using the %{power_state} macro.
Default: '%{power_state} !~ /^powered_on$/i'

=back

=cut
