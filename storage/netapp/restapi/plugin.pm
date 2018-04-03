#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package storage::netapp::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                            'aggregate-raid-status' => 'storage::netapp::restapi::mode::aggregateraidstatus',
                            'aggregate-status'      => 'storage::netapp::restapi::mode::aggregatestatus',
                            'aggregate-usage'       => 'storage::netapp::restapi::mode::aggregateusage',
                            'cluster-io'            => 'storage::netapp::restapi::mode::clusterio',
                            'cluster-status'        => 'storage::netapp::restapi::mode::clusterstatus',
                            'cluster-usage'         => 'storage::netapp::restapi::mode::clusterusage',
                            'disk-failed'           => 'storage::netapp::restapi::mode::diskfailed',
                            'disk-spare'            => 'storage::netapp::restapi::mode::diskspare',
                            'fc-port-status'        => 'storage::netapp::restapi::mode::fcportstatus',
                            'list-aggregates'       => 'storage::netapp::restapi::mode::listaggregates',
                            'list-clusters'         => 'storage::netapp::restapi::mode::listclusters',
                            'list-fc-ports'         => 'storage::netapp::restapi::mode::listfcports',
                            'list-luns'             => 'storage::netapp::restapi::mode::listluns',
                            'list-nodes'            => 'storage::netapp::restapi::mode::listnodes',
                            'list-snapmirrors'      => 'storage::netapp::restapi::mode::listsnapmirrors',
                            'list-volumes'          => 'storage::netapp::restapi::mode::listvolumes',
                            'lun-alignment'         => 'storage::netapp::restapi::mode::lunalignment',
                            'lun-online'            => 'storage::netapp::restapi::mode::lunonline',
                            'lun-usage'             => 'storage::netapp::restapi::mode::lunusage',
                            'node-failover-status'  => 'storage::netapp::restapi::mode::nodefailoverstatus',
                            'node-hardware-status'  => 'storage::netapp::restapi::mode::nodehardwarestatus',
                            'qtree-status'          => 'storage::netapp::restapi::mode::qtreestatus',
                            'snapmirror-status'     => 'storage::netapp::restapi::mode::snapmirrorstatus',
                            'snapmirror-usage'      => 'storage::netapp::restapi::mode::snapmirrorusage',
                            'volume-io'             => 'storage::netapp::restapi::mode::volumeio',
                            'volume-status'         => 'storage::netapp::restapi::mode::volumestatus',
                            'volume-usage'          => 'storage::netapp::restapi::mode::volumeusage',
                        );
    $self->{custom_modes}{api} = 'storage::netapp::restapi::custom::restapi';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check NetApp with OnCommand API.

=cut
