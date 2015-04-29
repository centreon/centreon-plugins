################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::vmware::connector::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'alarm-datacenter'     => 'apps::vmware::connector::mode::alarmdatacenter',
                         'alarm-host'           => 'apps::vmware::connector::mode::alarmhost',
                         'countvm-host'         => 'apps::vmware::connector::mode::countvmhost', 
                         'cpu-host'             => 'apps::vmware::connector::mode::cpuhost', 
                         'cpu-vm'               => 'apps::vmware::connector::mode::cpuvm',
                         'datastore-host'       => 'apps::vmware::connector::mode::datastorehost',
                         'datastore-io'         => 'apps::vmware::connector::mode::datastoreio',
                         'datastore-iops'       => 'apps::vmware::connector::mode::datastoreiops',
                         'datastore-snapshot'   => 'apps::vmware::connector::mode::datastoresnapshot',
                         'datastore-usage'      => 'apps::vmware::connector::mode::datastoreusage',
                         'datastore-vm'         => 'apps::vmware::connector::mode::datastorevm', 
                         'getmap'               => 'apps::vmware::connector::mode::getmap',
                         'health-host'          => 'apps::vmware::connector::mode::healthhost',
                         'limit-vm'             => 'apps::vmware::connector::mode::limitvm',
                         'list-datacenters'     => 'apps::vmware::connector::mode::listdatacenters',
                         'list-datastores'      => 'apps::vmware::connector::mode::listdatastores',
                         'list-nichost'         => 'apps::vmware::connector::mode::listnichost',
                         'maintenance-host'     => 'apps::vmware::connector::mode::maintenancehost',
                         'memory-host'          => 'apps::vmware::connector::mode::memoryhost',
                         'memory-vm'            => 'apps::vmware::connector::mode::memoryvm',
                         'net-host'             => 'apps::vmware::connector::mode::nethost',
                         'snapshot-vm'          => 'apps::vmware::connector::mode::snapshotvm',
                         'stat-connectors'      => 'apps::vmware::connector::mode::statconnectors',
                         'status-host'          => 'apps::vmware::connector::mode::statushost',
                         'status-vm'            => 'apps::vmware::connector::mode::statusvm',
                         'swap-host'            => 'apps::vmware::connector::mode::swaphost',
                         'swap-vm'              => 'apps::vmware::connector::mode::swapvm',
                         'thinprovisioning-vm'  => 'apps::vmware::connector::mode::thinprovisioningvm',
                         'tools-vm'             => 'apps::vmware::connector::mode::toolsvm',
                         'uptime-host'          => 'apps::vmware::connector::mode::uptimehost',
                         'vmoperation-cluster'  => 'apps::vmware::connector::mode::vmoperationcluster',
                         );

    $self->{custom_modes}{connector} = 'apps::vmware::connector::custom::connector';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check VMWare with centreon-esxd connector.

=cut
