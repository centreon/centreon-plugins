#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcenter::mode;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {}
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'VMWARE 8 VCENTER OPTIONS', once => 1);

    return $self;
}

sub get_datastore {
    my ($self, %options) = @_;
    # if a datastore_id option is given, prepare to append it to the endpoint path
    my $datastore_param = defined($options{datastore_id}) ? '/' . $options{datastore_id} : '';

    # Retrieve the data
    return $options{custom}->request_api('endpoint' => '/vcenter/datastore' . $datastore_param, 'method' => 'GET');
}

sub get_cluster {
    my ($self, %options) = @_;
    # if a cluster_id option is given, prepare to append it to the endpoint path
    my $cluster_param = defined($options{cluster_id}) ? '/' . $options{cluster_id} : '';

    # Retrieve the data
    return $options{custom}->request_api('endpoint' => '/vcenter/cluster' . $cluster_param, 'method' => 'GET');
}

sub request_api {
    my ($self, %options) = @_;

    return $options{custom}->request_api(%options);
}

sub get_vms_by_host {
    my ($self, %options) = @_;

    return $options{custom}->get_vms_by_host(%options);
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
        my $vms_by_host    = $self->get_vms_by_host(%options);
        my $datastore_data = $self->get_datastore(%options);
    }

=head1 DESCRIPTION

This module provides convenience methods for modes that monitor a VMware vCenter through the
vSphere 8 REST API. It delegates all HTTP communication to C<api.pm> and exposes higher-level
helpers for retrieving VMs, datastores, clusters, and raw API responses.

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

=head2 get_cluster

    my $all_clusters  = $self->get_cluster(%options);
    my $one_cluster   = $self->get_cluster(%options, cluster_id => 'cluster-12');

Retrieves the vCenter's clusters, or a single cluster when C<cluster_id> is provided.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<custom> - The custom_mode object, defined in C<api.pm> and declared in C<plugin.pm> (mandatory).

=item * C<cluster_id> - The ID of a specific cluster (optional).

=back

=back

=head2 request_api

    my $response = $self->request_api(endpoint => '/vcenter/vm', method => 'GET');

Thin wrapper that forwards any C<%options> to C<< $options{custom}->request_api >>. Use this
when no higher-level helper covers the endpoint you need.

=over 4

=item * C<%options> - Passed through to C<api.pm>'s C<request_api>. Useful keys:

=over 8

=item * C<custom> - The custom_mode object (mandatory).

=item * C<endpoint> - The API endpoint path, e.g. C</vcenter/vm> (mandatory).

=item * C<method> - The HTTP method: C<GET>, C<POST>, C<PATCH> (default: C<GET>).

=item * C<get_param> - Array reference of query parameters.

=back

=back

=head2 get_vms_by_host

    my $vms = $self->get_vms_by_host(%options);
    my $vms = $self->get_vms_by_host(%options, get_param => ['power_states=POWERED_ON']);

Retrieves all virtual machines grouped by ESX host. Delegates to C<api.pm>'s C<get_vms_by_host>,
which works around the 4000-element API limit by issuing one request per ESX host.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<custom> - The custom_mode object, defined in C<api.pm> and declared in C<plugin.pm> (mandatory).

=item * C<get_param> - An array reference of extra query parameters forwarded to each per-host
VM request (e.g. C<['power_states=POWERED_ON']>).

=back

=back

Returns a hash reference keyed by VM ID. Each value contains: C<vm>, C<name>, C<power_state>,
C<cpu_count>, C<memory_size_MiB>, and C<host> (the ESX host ID the VM runs on).

=cut

