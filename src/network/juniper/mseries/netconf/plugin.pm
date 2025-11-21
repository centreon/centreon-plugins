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

package network::juniper::mseries::netconf::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'bgp'               => 'network::juniper::common::junos::netconf::mode::bgp',
        'cache'             => 'network::juniper::mseries::netconf::mode::cache',
        'collection'        => 'network::juniper::common::junos::netconf::mode::collection',
        'cpu'               => 'network::juniper::common::junos::netconf::mode::cpu',
        'disks'             => 'network::juniper::common::junos::netconf::mode::disks',
        'hardware'          => 'network::juniper::common::junos::netconf::mode::hardware',
        'interfaces'        => 'network::juniper::common::junos::netconf::mode::interfaces',
        'ldp'               => 'network::juniper::common::junos::netconf::mode::ldp',
        'lsp'               => 'network::juniper::common::junos::netconf::mode::lsp',
        'list-bgp'          => 'network::juniper::common::junos::netconf::mode::listbgp',
        'list-disks'        => 'network::juniper::common::junos::netconf::mode::listdisks',
        'list-interfaces'   => 'network::juniper::common::junos::netconf::mode::listinterfaces',
        'list-ldp'          => 'network::juniper::common::junos::netconf::mode::listldp',
        'list-lsp'          => 'network::juniper::common::junos::netconf::mode::listlsp',
        'list-rsvp'         => 'network::juniper::common::junos::netconf::mode::listrsvp',
        'list-services-rpm' => 'network::juniper::common::junos::netconf::mode::listservicesrpm',
        'memory'            => 'network::juniper::common::junos::netconf::mode::memory',
        'ospf'              => 'network::juniper::common::junos::netconf::mode::ospf',
        'rsvp'              => 'network::juniper::common::junos::netconf::mode::rsvp',
        'services-rpm'      => 'network::juniper::common::junos::netconf::mode::servicesrpm'
    };

    $self->{custom_modes}->{netconf} = 'network::juniper::common::junos::netconf::custom::netconf';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Juniper MX Series with API (Netconf over ssh,...).

=cut
