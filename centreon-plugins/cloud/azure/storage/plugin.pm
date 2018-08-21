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

package cloud::azure::storage::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    %{ $self->{modes} } = (
        'account-used-capacity'     => 'cloud::azure::storage::mode::accountusedcapacity',
        'blob-capacity'             => 'cloud::azure::storage::mode::blobcapacity',
        'blob-container-count'      => 'cloud::azure::storage::mode::blobcontainercount',
        'blob-count'                => 'cloud::azure::storage::mode::blobcount',
        'file-capacity'             => 'cloud::azure::storage::mode::filecapacity',
        'file-count'                => 'cloud::azure::storage::mode::filecount',
        'file-share-count'          => 'cloud::azure::storage::mode::filesharecount',
        'list-resources'            => 'cloud::azure::storage::mode::listresources',
        'queue-capacity'            => 'cloud::azure::storage::mode::queuecapacity',
        'queue-count'               => 'cloud::azure::storage::mode::queuecount',
        'queue-message-count'       => 'cloud::azure::storage::mode::queuemessagecount',
        'table-capacity'            => 'cloud::azure::storage::mode::tablecapacity',
        'table-count'               => 'cloud::azure::storage::mode::tablecount',
        'table-entity-count'        => 'cloud::azure::storage::mode::tableentitycount',
        'transactions-availability' => 'cloud::azure::storage::mode::transactionsavailability',
        'transactions-count'        => 'cloud::azure::storage::mode::transactionscount',
        'transactions-latency'      => 'cloud::azure::storage::mode::transactionslatency',
        'transactions-throughput'   => 'cloud::azure::storage::mode::transactionsthroughput',
    );

    $self->{custom_modes}{azcli} = 'cloud::azure::custom::azcli';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Microsoft Azure storage provider.

=cut
