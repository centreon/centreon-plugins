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

package storage::netapp::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'aggregatestate'   => 'storage::netapp::snmp::mode::aggregatestate',
                         'cp-statistics'    => 'storage::netapp::snmp::mode::cpstatistics',
                         'cpuload'          => 'storage::netapp::snmp::mode::cpuload',
                         'diskfailed'       => 'storage::netapp::snmp::mode::diskfailed',
                         'fan'              => 'storage::netapp::snmp::mode::fan',
                         'filesys'          => 'storage::netapp::snmp::mode::filesys',
                         'list-filesys'     => 'storage::netapp::snmp::mode::listfilesys',
                         'global-status'    => 'storage::netapp::snmp::mode::globalstatus',
                         'ndmpsessions'     => 'storage::netapp::snmp::mode::ndmpsessions',
                         'nvram'            => 'storage::netapp::snmp::mode::nvram',
                         'partnerstatus'    => 'storage::netapp::snmp::mode::partnerstatus',
                         'psu'              => 'storage::netapp::snmp::mode::psu',
                         'qtree-usage'      => 'storage::netapp::snmp::mode::qtreeusage',
                         'share-calls'      => 'storage::netapp::snmp::mode::sharecalls',
                         'shelf'            => 'storage::netapp::snmp::mode::shelf',
                         'snapmirrorlag'    => 'storage::netapp::snmp::mode::snapmirrorlag',
                         'snapshotage'      => 'storage::netapp::snmp::mode::snapshotage',
                         'temperature'      => 'storage::netapp::snmp::mode::temperature',
                         'volumeoptions'    => 'storage::netapp::snmp::mode::volumeoptions',
                         'cache-age'        => 'storage::netapp::snmp::mode::cacheage',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Netapp in SNMP (Some Check needs ONTAP 8.x).

=cut
