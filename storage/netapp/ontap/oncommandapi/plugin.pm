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

package storage::netapp::ontap::oncommandapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'aggregate-raid-status' => 'storage::netapp::ontap::oncommandapi::mode::aggregateraidstatus',
        'aggregate-status'      => 'storage::netapp::ontap::oncommandapi::mode::aggregatestatus',
        'aggregate-usage'       => 'storage::netapp::ontap::oncommandapi::mode::aggregateusage',
        'cluster-io'            => 'storage::netapp::ontap::oncommandapi::mode::clusterio',
        'cluster-status'        => 'storage::netapp::ontap::oncommandapi::mode::clusterstatus',
        'cluster-usage'         => 'storage::netapp::ontap::oncommandapi::mode::clusterusage',
        'disk-failed'           => 'storage::netapp::ontap::oncommandapi::mode::diskfailed',
        'disk-spare'            => 'storage::netapp::ontap::oncommandapi::mode::diskspare',
        'fc-port-status'        => 'storage::netapp::ontap::oncommandapi::mode::fcportstatus',
        'list-aggregates'       => 'storage::netapp::ontap::oncommandapi::mode::listaggregates',
        'list-clusters'         => 'storage::netapp::ontap::oncommandapi::mode::listclusters',
        'list-fc-ports'         => 'storage::netapp::ontap::oncommandapi::mode::listfcports',
        'list-luns'             => 'storage::netapp::ontap::oncommandapi::mode::listluns',
        'list-nodes'            => 'storage::netapp::ontap::oncommandapi::mode::listnodes',
        'list-snapmirrors'      => 'storage::netapp::ontap::oncommandapi::mode::listsnapmirrors',
        'list-volumes'          => 'storage::netapp::ontap::oncommandapi::mode::listvolumes',
        'lun-alignment'         => 'storage::netapp::ontap::oncommandapi::mode::lunalignment',
        'lun-online'            => 'storage::netapp::ontap::oncommandapi::mode::lunonline',
        'lun-usage'             => 'storage::netapp::ontap::oncommandapi::mode::lunusage',
        'node-failover-status'  => 'storage::netapp::ontap::oncommandapi::mode::nodefailoverstatus',
        'node-hardware-status'  => 'storage::netapp::ontap::oncommandapi::mode::nodehardwarestatus',
        'qtree-status'          => 'storage::netapp::ontap::oncommandapi::mode::qtreestatus',
        'snapmirror-status'     => 'storage::netapp::ontap::oncommandapi::mode::snapmirrorstatus',
        'snapmirror-usage'      => 'storage::netapp::ontap::oncommandapi::mode::snapmirrorusage',
        'volume-io'             => 'storage::netapp::ontap::oncommandapi::mode::volumeio',
        'volume-status'         => 'storage::netapp::ontap::oncommandapi::mode::volumestatus',
        'volume-usage'          => 'storage::netapp::ontap::oncommandapi::mode::volumeusage'
    );

    $self->{custom_modes}{api} = 'storage::netapp::ontap::oncommandapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check NetApp ONTAP with OnCommand API.

=cut
