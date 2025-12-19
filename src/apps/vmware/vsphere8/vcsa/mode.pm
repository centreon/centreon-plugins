#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcsa::mode;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {}
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE 8 VCSA OPTIONS', once => 1);

    return $self;
}

sub get_value {
    my ($self, %options) = @_;

    # Retrieve the data
    return $options{custom}->request_api('endpoint' => '/appliance/' . $options{endpoint}, 'method' => 'GET');
}

sub request_api {
    my ($self, %options) = @_;

    return $options{custom}->request_api(%options);
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

}

1;

__END__

=head1 VMWARE 8 VCENTER OPTIONS

=over 4

No specific options for vCenter modes.

=back

=cut

=head1 NAME

apps::vmware::vsphere8::vcenter::mode - Template for modes monitoring VMware vCenter

=head1 SYNOPSIS

    use base apps::vmware::vsphere8::vcenter::mode;

    sub set_counters {...}
    sub manage_selection {
        my ($self, %options) = @_;

        $self->set_options(option_results => $option_results);
        $self->check_options();
        my $vm_data = $self->get_vms(%options);
        my $datastore_data = $self->get_datastore(%options);
    }

=head1 DESCRIPTION

This module provides methods to interact with the VMware vSphere 8 REST API. It handles generic API requests and VMs GET requests.

=head1 METHODS

=head2 get_datastore

    my $all_datastores = $self->get_datastore(%options);
    my $one_datastore = $self->get_datastore(%options, datastore_id => 'datastore-35');

Retrieves the vCenter's datastores or only one datastore's specifics in case the `datastore_id` option is provided.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<custom> - The custom_mode object, defined in C<api.pm> and declared in C<plugin.pm> (mandatory).

=item * C<datastore_id> - The C<datastore_id> of a datastore (optional).

=back

=back

=head2 get_vms

    my $all_vms = $self->get_vms(%options);

Retrieves the vCenter's virtual machines list.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<custom> - The custom_mode object, defined in C<api.pm> and declared in C<plugin.pm> (mandatory).

=back

=back

Returns the list of all the virtual machines with the following attributes for each VM:

=over 4

=item * C<vm>: ID of the virtual machine.

=item * C<name>: name of the virtual machine.

=item * C<cpu_count>: number of vCPU.

=item * C<power_state>: state of the VM. Can be POWERED_ON, POWERED_OFF, SUSPENDED.

=item * C<memory_size_MiB>: amount of memory allocated to the virtual machine.

=back

=cut

