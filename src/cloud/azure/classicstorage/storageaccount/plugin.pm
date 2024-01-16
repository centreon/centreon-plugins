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

package cloud::azure::classicstorage::storageaccount::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    %{ $self->{modes} } = (
        'account-used-capacity'     => 'cloud::azure::common::storageaccount::accountusedcapacity',
        'blob-capacity'             => 'cloud::azure::common::storageaccount::blobcapacity',
        'blob-container-count'      => 'cloud::azure::common::storageaccount::blobcontainercount',
        'blob-count'                => 'cloud::azure::common::storageaccount::blobcount',
        'discovery'                 => 'cloud::azure::classicstorage::storageaccount::mode::discovery',
        'file-capacity'             => 'cloud::azure::common::storageaccount::filecapacity',
        'file-count'                => 'cloud::azure::common::storageaccount::filecount', 
        'file-share-count'          => 'cloud::azure::common::storageaccount::filesharecount',
        'file-share-quota'          => 'cloud::azure::common::storageaccount::filesharecount',
        'health'                    => 'cloud::azure::common::storageaccount::health',
        'list-fileshares'           => 'cloud::azure::common::storageaccount::listfileshares',
        'list-resources'            => 'cloud::azure::classicstorage::storageaccount::mode::listresources',
        'queue-capacity'            => 'cloud::azure::common::storageaccount::queuecapacity',
        'queue-count'               => 'cloud::azure::common::storageaccount::queuecount',
        'queue-message-count'       => 'cloud::azure::common::storageaccount::queuemessagecount',
        'table-capacity'            => 'cloud::azure::common::storageaccount::tablecapacity',
        'table-count'               => 'cloud::azure::common::storageaccount::tablecount',
        'table-entity-count'        => 'cloud::azure::common::storageaccount::tableentitycount',
        'transactions-availability' => 'cloud::azure::common::storageaccount::transactionsavailability',
        'transactions-count'        => 'cloud::azure::common::storageaccount::transactionscount',
        'transactions-latency'      => 'cloud::azure::common::storageaccount::transactionslatency',
        'transactions-throughput'   => 'cloud::azure::common::storageaccount::transactionsthroughput',
    );

    $self->{custom_modes}{azcli} = 'cloud::azure::custom::azcli';
    $self->{custom_modes}{api} = 'cloud::azure::custom::api';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(arguments => {
        'api-version:s'        => { name => 'api_version', default => '2018-01-01' },
    });

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Microsoft Azure classic storage account.

=over 8

=cut
