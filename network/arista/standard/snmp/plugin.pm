#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::arista::standard::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'cpu' => 'snmp_standard::mode::cpu',
                         'entity' => 'snmp_standard::mode::entity',
                         'hardwaredevice' => 'snmp_standard::mode::hardwaredevice',
                         'interfaces' => 'snmp_standard::mode::interfaces',
                         'list-interfaces' => 'snmp_standard::mode::listinterfaces',
                         'ntp' => 'snmp_standard::mode::ntp',
                         'tcpcon' => 'snmp_standard::mode::tcpcon',
                         'uptime' => 'snmp_standard::mode::uptime',
                         'vrrp' => 'snmp_standard::mode::vrrp',
                         );

    return $self;
}

1;

