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

package cloud::azure::network::vpngateway::mode::discovery;

use base qw(cloud::azure::management::monitor::mode::discovery);

use strict;
use warnings;

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{namespace} = 'Microsoft.Network';
    $self->{type} = 'virtualNetworkGateways';
}

1;

__END__

=head1 MODE

VPN Gateway discovery.

=over 8

=item B<--resource-group>

Specify resource group.

=item B<--location>

Specify location.

=item B<--prettify>

Prettify JSON output.

=back

=cut
