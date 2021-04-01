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

package network::citrix::netscaler::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.6';
    $self->{modes} = {
        'certificates-expire' => 'network::citrix::netscaler::snmp::mode::certificatesexpire',
        'connections'         => 'network::citrix::netscaler::snmp::mode::connections',
        'cpu'                 => 'network::citrix::netscaler::snmp::mode::cpu',
        'health'              => 'network::citrix::netscaler::snmp::mode::health',
        'ha-state'            => 'network::citrix::netscaler::snmp::mode::hastate',
        'interfaces'          => 'snmp_standard::mode::interfaces',
        'list-interfaces'     => 'snmp_standard::mode::listinterfaces',
        'list-vservers'       => 'network::citrix::netscaler::snmp::mode::listvservers',
        'memory'              => 'network::citrix::netscaler::snmp::mode::memory',
        'uptime'              => 'snmp_standard::mode::uptime',
        'storage'             => 'network::citrix::netscaler::snmp::mode::storage',
        'vserver-status'      => 'network::citrix::netscaler::snmp::mode::vserverstatus'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Citrix NetScaler Series in SNMP.

=cut
