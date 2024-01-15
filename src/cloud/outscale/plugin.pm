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

package cloud::outscale::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'account-consumptions'   => 'cloud::outscale::mode::accountconsumptions',
        'client-gateways'        => 'cloud::outscale::mode::clientgateways',
        'internet-services'      => 'cloud::outscale::mode::internetservices',
        'list-client-gateways'   => 'cloud::outscale::mode::listclientgateways',
        'list-internet-services' => 'cloud::outscale::mode::listinternetservices',
        'list-load-balancers'    => 'cloud::outscale::mode::listloadbalancers',
        'list-nat-services'      => 'cloud::outscale::mode::listnatservices',
        'list-nets'              => 'cloud::outscale::mode::listnets',
        'list-quotas'            => 'cloud::outscale::mode::listquotas',
        'list-route-tables'      => 'cloud::outscale::mode::listroutetables',
        'list-subnets'           => 'cloud::outscale::mode::listsubnets',
        'list-virtual-gateways'  => 'cloud::outscale::mode::listvirtualgateways',
        'list-volumes'           => 'cloud::outscale::mode::listvolumes',
        'list-vms'               => 'cloud::outscale::mode::listvms',
        'list-vpn-connections'   => 'cloud::outscale::mode::listvpnconnections',
        'load-balancers'         => 'cloud::outscale::mode::loadbalancers',
        'nat-services'           => 'cloud::outscale::mode::natservices',
        'nets'                   => 'cloud::outscale::mode::nets',
        'quotas'                 => 'cloud::outscale::mode::quotas',
        'route-tables'           => 'cloud::outscale::mode::routetables',
        'subnets'                => 'cloud::outscale::mode::subnets',
        'virtual-gateways'       => 'cloud::outscale::mode::virtualgateways',
        'volumes'                => 'cloud::outscale::mode::volumes',
        'vms'                    => 'cloud::outscale::mode::vms',
        'vpn-connections'        => 'cloud::outscale::mode::vpnconnections'
    };

    $self->{custom_modes}->{http} = 'cloud::outscale::custom::http';
    $self->{custom_modes}->{osccli} = 'cloud::outscale::custom::osccli';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Outscale.

=cut
