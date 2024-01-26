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

package cloud::azure::compute::aks::mode::health;

use base qw(cloud::azure::management::monitor::mode::health);

use strict;
use warnings;

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{az_resource_namespace} = 'Microsoft.ContainerService';
    $self->{az_resource_type} = 'managedClusters';
}

1;

__END__

=head1 MODE

Check Azure Kubernetes Cluster health status.
(useful to determine host status)

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').

You can use the following variables: %{status}, %{summary}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /^Unavailable$/').

You can use the following variables: %{status}, %{summary}

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /^Unknown$/').

You can use the following variables: %{status}, %{summary}

=item B<--ok-status>

Define the conditions to match for the status to be OK (default: '%{status} =~ /^Available$/').

You can use the following variables: %{status}, %{summary}

=back

=cut
