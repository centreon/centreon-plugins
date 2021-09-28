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

package network::cisco::standard::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'aaa-servers'         => 'centreon::common::cisco::standard::snmp::mode::aaaservers',
        'arp'                 => 'snmp_standard::mode::arp',
        'configuration'       => 'centreon::common::cisco::standard::snmp::mode::configuration',
        'cpu'                 => 'centreon::common::cisco::standard::snmp::mode::cpu',
        'environment'         => 'centreon::common::cisco::standard::snmp::mode::environment',
        'hsrp'                => 'centreon::common::cisco::standard::snmp::mode::hsrp',
        'interfaces'          => 'centreon::common::cisco::standard::snmp::mode::interfaces', 
        'ipsla'               => 'centreon::common::cisco::standard::snmp::mode::ipsla',
        'list-aaa-servers'    => 'centreon::common::cisco::standard::snmp::mode::listaaaservers',
        'list-interfaces'     => 'snmp_standard::mode::listinterfaces',
        'list-spanning-trees' => 'snmp_standard::mode::listspanningtrees',
        'load'                => 'centreon::common::cisco::standard::snmp::mode::load',
        'memory'              => 'centreon::common::cisco::standard::snmp::mode::memory',
        'memory-flash'        => 'centreon::common::cisco::standard::snmp::mode::memoryflash',
        'qos-usage'           => 'centreon::common::cisco::standard::snmp::mode::qosusage',
        'spanning-tree'       => 'snmp_standard::mode::spanningtree',
        'stack'               => 'centreon::common::cisco::standard::snmp::mode::stack',
        'uptime'              => 'snmp_standard::mode::uptime',
        'voice-call'          => 'centreon::common::cisco::standard::snmp::mode::voicecall',
        'vpc'                 => 'centreon::common::cisco::standard::snmp::mode::vpc',
        'vss'                 => 'centreon::common::cisco::standard::snmp::mode::vss',
        'wan3g'               => 'centreon::common::cisco::standard::snmp::mode::wan3g'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco equipments (2800, 2900, 3750, Nexus,...) in SNMP.

=cut
