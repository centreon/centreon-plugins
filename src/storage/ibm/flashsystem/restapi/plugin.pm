#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::ibm::flashsystem::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';

    $self->{modes} = {
        'capacity'      => 'storage::ibm::flashsystem::restapi::mode::capacity',
        'drives'        => 'storage::ibm::flashsystem::restapi::mode::drives',
        'eth-ports'     => 'storage::ibm::flashsystem::restapi::mode::ethports',
        'eventlog'      => 'storage::ibm::flashsystem::restapi::mode::eventlog',
        'fc-ports'      => 'storage::ibm::flashsystem::restapi::mode::fcports',
        'hardware'      => 'storage::ibm::flashsystem::restapi::mode::hardware',
        'hosts'         => 'storage::ibm::flashsystem::restapi::mode::hosts',
        'performance'   => 'storage::ibm::flashsystem::restapi::mode::performance',
        'replication'   => 'storage::ibm::flashsystem::restapi::mode::replication',
        'system-status' => 'storage::ibm::flashsystem::restapi::mode::systemstatus',
        'volume-groups' => 'storage::ibm::flashsystem::restapi::mode::volumegroups',
        'volumes'       => 'storage::ibm::flashsystem::restapi::mode::volumes'
    };

    $self->{custom_modes}->{api} = 'storage::ibm::flashsystem::restapi::custom::api';

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check IBM Storage Virtualize systems (FlashSystem, Storwize, SAN Volume Controller) using the REST API.

=cut
