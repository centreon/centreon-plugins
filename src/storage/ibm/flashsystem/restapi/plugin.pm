#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Supervision des baies IBM Storage Virtualize (FlashSystem, Storwize, SVC)
# via l'API REST exposee sur le port 7443.
#
# Principe de conception : le plugin ne connait aucune specificite d'une baie
# donnee. Tout est decouvert par l'API. Ajouter une baie se limite a creer un
# hote portant le calque et deux macros ; aucune modification de code.
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

    # Seuls les modes reellement implementes sont declares : un mode declare
    # sans son module apparait dans --list-mode puis echoue a l'execution sur
    # "Cannot load module".
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
        # Destine a la commande de verification d'HOTE, pas a un service.
        'system-status' => 'storage::ibm::flashsystem::restapi::mode::systemstatus',
        'volume-groups' => 'storage::ibm::flashsystem::restapi::mode::volumegroups',
        'volumes'       => 'storage::ibm::flashsystem::restapi::mode::volumes'
        # Restent a ecrire, le jour ou la decouverte automatique de services
        # sera mise en place (elle demande aussi des regles cote Centreon, que
        # ni CLAPI ni l'API v2 n'exposent) :
        # 'list-fc-ports'      => '...::mode::listfcports',
        # 'list-volume-groups' => '...::mode::listvolumegroups'
    };

    $self->{custom_modes}->{api} = 'storage::ibm::flashsystem::restapi::custom::api';

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor IBM Storage Virtualize systems (FlashSystem, Storwize, SAN Volume
Controller) through the REST API served on port 7443.

The plugin discovers everything from the API: no array-specific value is
hard-coded, so a newly added system is monitored by the same commands and the
same service templates as the existing ones.

Requires Storage Virtualize 8.1.3 or later, and an array account with the
B<Monitor> role.

=over 8

=item B<Available modes>

capacity, drives, eth-ports, eventlog, fc-ports, hardware, hosts, performance,
replication, system-status, volume-groups, volumes.

Run C<--list-mode> to get the authoritative list: only implemented modes are
declared, so anything listed can actually be run.

C<system-status> is meant to be the B<host check command>, not a service: it
reports DOWN only when the array stopped serving — no canister online, no pool
online, or no answer at all. A dead power supply or a degraded partition must
not take the host down, because that would make every service UNREACHABLE and
silence them.

=item B<Splitting a mode across several services>

A mode that returns several concerns at once is split with
C<--filter-counters>, a regular expression on the counter labels — no plugin
code and no extra command. C<performance> is split that way into three
services: C<--filter-counters=latency>,
C<--filter-counters=iops|bandwidth|cache> and C<--filter-counters=cpu>.

The same idea restricts a scope rather than a counter set:
C<--filter-partition> gives one replication service per storage partition.

=back

=cut
