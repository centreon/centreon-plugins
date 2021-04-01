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

package network::nokia::timos::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'bgp-usage'        => 'network::nokia::timos::snmp::mode::bgpusage',
        'cpu'              => 'network::nokia::timos::snmp::mode::cpu',
        'hardware'         => 'network::nokia::timos::snmp::mode::hardware',
        'l2tp-usage'       => 'network::nokia::timos::snmp::mode::l2tpusage',
        'ldp-usage'        => 'network::nokia::timos::snmp::mode::ldpusage',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'isis-usage'       => 'network::nokia::timos::snmp::mode::isisusage',
        'list-bgp'         => 'network::nokia::timos::snmp::mode::listbgp',
        'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
        'list-isis'        => 'network::nokia::timos::snmp::mode::listisis',
        'list-ldp'         => 'network::nokia::timos::snmp::mode::listldp',
        'list-sap'         => 'network::nokia::timos::snmp::mode::listsap',
        'list-vrtr'        => 'network::nokia::timos::snmp::mode::listvrtr',
        'memory'           => 'network::nokia::timos::snmp::mode::memory',
        'sap-usage'        => 'network::nokia::timos::snmp::mode::sapusage',
        'uptime'           => 'snmp_standard::mode::uptime',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Nokia TiMOS (SR OS) equipments (7750SR, 7210SAS) in SNMP.

=cut
