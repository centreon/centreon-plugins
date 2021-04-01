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

package storage::netapp::ontap::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'aggregatestate'   => 'storage::netapp::ontap::snmp::mode::aggregatestate',
        'cache-age'        => 'storage::netapp::ontap::snmp::mode::cacheage',
        'cp-statistics'    => 'storage::netapp::ontap::snmp::mode::cpstatistics',
        'cpuload'          => 'storage::netapp::ontap::snmp::mode::cpuload',
        'diskfailed'       => 'storage::netapp::ontap::snmp::mode::diskfailed',
        'failover'         => 'storage::netapp::ontap::snmp::mode::failover',
        'fan'              => 'storage::netapp::ontap::snmp::mode::fan',
        'filesys'          => 'storage::netapp::ontap::snmp::mode::filesys',
        'list-filesys'     => 'storage::netapp::ontap::snmp::mode::listfilesys',
        'list-snapvault'   => 'storage::netapp::ontap::snmp::mode::listsnapvault',
        'global-status'    => 'storage::netapp::ontap::snmp::mode::globalstatus',
        'ndmpsessions'     => 'storage::netapp::ontap::snmp::mode::ndmpsessions',
        'nvram'            => 'storage::netapp::ontap::snmp::mode::nvram',
        'partnerstatus'    => 'storage::netapp::ontap::snmp::mode::partnerstatus',
        'psu'              => 'storage::netapp::ontap::snmp::mode::psu',
        'qtree-usage'      => 'storage::netapp::ontap::snmp::mode::qtreeusage',
        'share-calls'      => 'storage::netapp::ontap::snmp::mode::sharecalls',
        'shelf'            => 'storage::netapp::ontap::snmp::mode::shelf',
        'sis'              => 'storage::netapp::ontap::snmp::mode::sis',
        'snapmirrorlag'    => 'storage::netapp::ontap::snmp::mode::snapmirrorlag',
        'snapshotage'      => 'storage::netapp::ontap::snmp::mode::snapshotage',
        'snapvault-usage'  => 'storage::netapp::ontap::snmp::mode::snapvaultusage',
        'temperature'      => 'storage::netapp::ontap::snmp::mode::temperature',
        'uptime'           => 'snmp_standard::mode::uptime',
        'volumeoptions'    => 'storage::netapp::ontap::snmp::mode::volumeoptions'
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Netapp ONTAP in SNMP.

=cut
