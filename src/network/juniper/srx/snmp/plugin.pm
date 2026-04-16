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

package network::juniper::srx::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'hardware'          => 'network::juniper::common::junos::snmp::mode::hardware',
        'cpu'               => 'network::juniper::common::junos::snmp::mode::cpu',
        'cpu-forwarding'    => 'network::juniper::common::junos::snmp::mode::cpuforwarding', # packet forwarding engine
        'memory'            => 'network::juniper::common::junos::snmp::mode::memory',
        'memory-forwarding' => 'network::juniper::common::junos::snmp::mode::memoryforwarding', # packet forwarding engine
        'cp-sessions'       => 'network::juniper::common::junos::snmp::mode::cpsessions', # CP = 'central point'
        'flow-sessions'     => 'network::juniper::common::junos::snmp::mode::flowsessions',
        'interfaces'        => 'network::juniper::common::junos::snmp::mode::interfaces',
        'ipsec-tunnel'      => 'network::juniper::common::junos::snmp::mode::ipsectunnel',
        'list-interfaces'   => 'snmp_standard::mode::listinterfaces',
        'list-storages'     => 'snmp_standard::mode::liststorages',
        'storage'           => 'snmp_standard::mode::storage'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Juniper SRX in SNMP.

=cut
