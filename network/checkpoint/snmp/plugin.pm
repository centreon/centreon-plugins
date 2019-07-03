#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::checkpoint::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.5';
    %{$self->{modes}} = (
                        'connections'       => 'network::checkpoint::snmp::mode::connections',
                        'cpu'               => 'snmp_standard::mode::cpu',
                        'hardware'          => 'network::checkpoint::snmp::mode::hardware',
                        'hastate'           => 'network::checkpoint::snmp::mode::hastate',
                        'interfaces'        => 'snmp_standard::mode::interfaces',
                        'list-interfaces'   => 'snmp_standard::mode::listinterfaces',
                        'list-storages'     => 'snmp_standard::mode::liststorages',
                        'memory'            => 'snmp_standard::mode::memory',
                        'storage'           => 'snmp_standard::mode::storage',
                        'swap'              => 'snmp_standard::mode::swap',
                        'time'              => 'snmp_standard::mode::ntp',
                        'uptime'            => 'snmp_standard::mode::uptime',
                        'vpn-status'        => 'network::checkpoint::snmp::mode::vpnstatus',
                        'vrrp-status'       => 'snmp_standard::mode::vrrp',
                        );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check CheckPoint FW in SNMP.

=cut
