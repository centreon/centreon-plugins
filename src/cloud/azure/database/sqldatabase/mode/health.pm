#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package cloud::azure::database::sqldatabase::mode::health;

use base qw(cloud::azure::management::monitor::mode::health);

use strict;
use warnings;

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{az_resource_namespace} = 'Microsoft.Sql' if (!defined($self->{az_resource_namespace}) || $self->{az_resource_namespace} eq '');
    $self->{az_resource_type} = 'servers/databases' if (!defined($self->{az_resource_type}) || $self->{az_resource_type} eq '');
}

1;

__END__

=head1 MODE

Check SQL Database health status.
(Useful to determine host status)

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-status>

Set warning threshold for status (Default: '').

You can use the following variables: %{status}, %{summary}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /^Unavailable$/').

You can use the following variables: %{status}, %{summary}

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /^Unknown$/').

You can use the following variables: %{status}, %{summary}

=item B<--ok-status>

Set ok threshold for status (Default: '%{status} =~ /^Available$/').

You can use the following variables: %{status}, %{summary}

=back

=cut
