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

package apps::vmware::connector::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'alarm-datacenter'     => 'apps::vmware::connector::mode::alarmdatacenter',
        'alarm-host'           => 'apps::vmware::connector::mode::alarmhost',
        'countvm-host'         => 'apps::vmware::connector::mode::countvmhost', 
        'cpu-host'             => 'apps::vmware::connector::mode::cpuhost', 
        'cpu-vm'               => 'apps::vmware::connector::mode::cpuvm',
        'datastore-countvm'    => 'apps::vmware::connector::mode::datastorecountvm',
        'datastore-host'       => 'apps::vmware::connector::mode::datastorehost',
        'datastore-io'         => 'apps::vmware::connector::mode::datastoreio',
        'datastore-iops'       => 'apps::vmware::connector::mode::datastoreiops',
        'datastore-snapshot'   => 'apps::vmware::connector::mode::datastoresnapshot',
        'datastore-usage'      => 'apps::vmware::connector::mode::datastoreusage',
        'datastore-vm'         => 'apps::vmware::connector::mode::datastorevm',
        'device-vm'            => 'apps::vmware::connector::mode::devicevm', 
        'discovery'            => 'apps::vmware::connector::mode::discovery', 
        'getmap'               => 'apps::vmware::connector::mode::getmap',
        'health-host'          => 'apps::vmware::connector::mode::healthhost',
        'limit-vm'             => 'apps::vmware::connector::mode::limitvm',
        'list-clusters'        => 'apps::vmware::connector::mode::listclusters',
        'list-datacenters'     => 'apps::vmware::connector::mode::listdatacenters',
        'list-datastores'      => 'apps::vmware::connector::mode::listdatastores',
        'list-nichost'         => 'apps::vmware::connector::mode::listnichost',
        'maintenance-host'     => 'apps::vmware::connector::mode::maintenancehost',
        'memory-host'          => 'apps::vmware::connector::mode::memoryhost',
        'memory-vm'            => 'apps::vmware::connector::mode::memoryvm',
        'net-host'             => 'apps::vmware::connector::mode::nethost',
        'net-vm'               => 'apps::vmware::connector::mode::netvm',
        'service-host'         => 'apps::vmware::connector::mode::servicehost',
        'snapshot-vm'          => 'apps::vmware::connector::mode::snapshotvm',
        'stat-connectors'      => 'apps::vmware::connector::mode::statconnectors',
        'status-cluster'       => 'apps::vmware::connector::mode::statuscluster',
        'status-host'          => 'apps::vmware::connector::mode::statushost',
        'status-vm'            => 'apps::vmware::connector::mode::statusvm',
        'swap-host'            => 'apps::vmware::connector::mode::swaphost',
        'swap-vm'              => 'apps::vmware::connector::mode::swapvm',
        'thinprovisioning-vm'  => 'apps::vmware::connector::mode::thinprovisioningvm',
        'time-host'            => 'apps::vmware::connector::mode::timehost',
        'tools-vm'             => 'apps::vmware::connector::mode::toolsvm',
        'uptime-host'          => 'apps::vmware::connector::mode::uptimehost',
        'vmoperation-cluster'  => 'apps::vmware::connector::mode::vmoperationcluster',
        'vsan-cluster-usage'   => 'apps::vmware::connector::mode::vsanclusterusage',
    };

    $self->{custom_modes}->{connector} = 'apps::vmware::connector::custom::connector';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check VMWare with centreon-vmware connector.

=cut
