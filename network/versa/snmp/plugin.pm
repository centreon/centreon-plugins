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

package network::versa::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'bgp-peers'       => 'network::versa::snmp::mode::bgppeers',
        'devices'         => 'network::versa::snmp::mode::devices',
        'list-interfaces' => 'snmp_standard::mode::listinterfaces',
        'list-ipsec'      => 'network::versa::snmp::mode::listipsec',
        'list-sdwan'      => 'network::versa::snmp::mode::listsdwan',
        'interfaces'      => 'snmp_standard::mode::interfaces',
        'ipsec'           => 'network::versa::snmp::mode::ipsec',
        'qos-policy'      => 'network::versa::snmp::mode::qospolicy',
        'sdwan'           => 'network::versa::snmp::mode::sdwan'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Versa equipments in SNMP.

=cut

