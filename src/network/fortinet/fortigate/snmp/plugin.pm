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

package network::fortinet::fortigate::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'ap-usage'            => 'centreon::common::fortinet::fortigate::snmp::mode::apusage',
        'cluster-status'      => 'centreon::common::fortinet::fortigate::snmp::mode::clusterstatus',
        'cpu'                 => 'centreon::common::fortinet::fortigate::snmp::mode::cpu',
        'disk'                => 'centreon::common::fortinet::fortigate::snmp::mode::disk',
        'hardware'            => 'centreon::common::fortinet::fortigate::snmp::mode::hardware',
        'interfaces'          => 'centreon::common::fortinet::fortigate::snmp::mode::interfaces',
        'ips-stats'           => 'centreon::common::fortinet::fortigate::snmp::mode::ipsstats',
        'link-monitor'        => 'centreon::common::fortinet::fortigate::snmp::mode::linkmonitor',
        'list-interfaces'     => 'snmp_standard::mode::listinterfaces',
        'list-link-monitors'  => 'centreon::common::fortinet::fortigate::snmp::mode::listlinkmonitors',
        'list-virtualdomains' => 'centreon::common::fortinet::fortigate::snmp::mode::listvirtualdomains',
        'list-switches'       => 'centreon::common::fortinet::fortigate::snmp::mode::listswitches',
        'memory'              => 'centreon::common::fortinet::fortigate::snmp::mode::memory',
        'sessions'            => 'centreon::common::fortinet::fortigate::snmp::mode::sessions',
        'signatures'          => 'centreon::common::fortinet::fortigate::snmp::mode::signatures',
        'uptime'              => 'snmp_standard::mode::uptime',
        'sdwan'               => 'centreon::common::fortinet::fortigate::snmp::mode::sdwan',
        'switch-usage'        => 'centreon::common::fortinet::fortigate::snmp::mode::switchusage',
        'vdom-usage'          => 'centreon::common::fortinet::fortigate::snmp::mode::vdomusage',
        'virus'               => 'centreon::common::fortinet::fortigate::snmp::mode::virus',
        'vpn'                 => 'centreon::common::fortinet::fortigate::snmp::mode::vpn'
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Fortinet Fortigate in SNMP.

=cut
