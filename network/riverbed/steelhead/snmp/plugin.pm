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

package network::riverbed::steelhead::snmp::plugin;

use strict;
use warnings;

use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'bandwidth-optimization'    => 'centreon::common::riverbed::steelhead::snmp::mode::bwoptimization',
        'bandwidth-passthrough'     => 'centreon::common::riverbed::steelhead::snmp::mode::bwpassthrough',
        'connections'               => 'centreon::common::riverbed::steelhead::snmp::mode::connections',
        'cpu'                       => 'snmp_standard::mode::cpu',
        'cpu-detailed'              => 'snmp_standard::mode::cpudetailed',
        'disk-utilization'          => 'centreon::common::riverbed::steelhead::snmp::mode::diskutilization',
        'interfaces'                => 'snmp_standard::mode::interfaces',
        'list-interfaces'           => 'snmp_standard::mode::listinterfaces',
        'list-storages'             => 'snmp_standard::mode::liststorages',
        'load-average'              => 'centreon::common::riverbed::steelhead::snmp::mode::loadaverage',
        'memory'                    => 'snmp_standard::mode::memory',
        'status'                    => 'centreon::common::riverbed::steelhead::snmp::mode::status',
        'storage'                   => 'snmp_standard::mode::storage',
        'temperature'               => 'centreon::common::riverbed::steelhead::snmp::mode::temperature',
        'uptime'                    => 'snmp_standard::mode::uptime'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Riverbed SteelHead WAN optimizer using SNMP.

=cut
