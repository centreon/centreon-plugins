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

package network::ruckus::scg::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'ap-status'        => 'network::ruckus::scg::snmp::mode::apstatus',
        'ap-usage'         => 'network::ruckus::scg::snmp::mode::apusage',
        'cpu'              => 'snmp_standard::mode::cpu',
        'cpu-detailed'     => 'snmp_standard::mode::cpudetailed',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'list-aps'         => 'network::ruckus::scg::snmp::mode::listaps',
        'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
        'list-ssids'       => 'network::ruckus::scg::snmp::mode::listssids',
        'load'             => 'snmp_standard::mode::loadaverage',
        'memory'           => 'snmp_standard::mode::memory',
        'ssid-usage'       => 'network::ruckus::scg::snmp::mode::ssidusage',
        'system-stats'     => 'network::ruckus::scg::snmp::mode::systemstats',
        'uptime'           => 'snmp_standard::mode::uptime',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Ruckus SmartCell Gateway (SCG) in SNMP.

=cut
