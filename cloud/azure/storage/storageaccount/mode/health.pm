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

package cloud::azure::storage::storageaccount::mode::health;

use base qw(cloud::azure::management::monitor::mode::health);

use strict;
use warnings;

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{az_resource_namespace} = 'Microsoft.Storage';
    $self->{az_resource_type} = 'storageAccounts';
}

1;

__END__

=head1 MODE

Check Storage Account health status.

(Usefull to determine host status)

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{summary}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /^Unavailable$/').
Can used special variables like: %{status}, %{summary}

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /^Unknown$/').
Can used special variables like: %{status}, %{summary}

=item B<--ok-status>

Set ok threshold for status (Default: '%{status} =~ /^Available$/').
Can used special variables like: %{status}, %{summary}

=back

=cut
