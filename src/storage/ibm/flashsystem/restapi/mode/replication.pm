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
# Etat de la replication, sous les trois formes que Storage Virtualize connait :
#
#   - partitions de stockage (8.7+) : c'est la partition qui porte l'etat de
#     sante de la haute disponibilite. Un ha_status a 'problem' coexiste sans
#     contradiction avec des groupes de volumes tous 'synchronized' : regarder
#     les seuls groupes ferait conclure a tort que tout va bien.
#   - replication par politique (8.5.2+) : lsvolumegroupreplication.
#   - Metro / Global Mirror (historique) : lsrcrelationship.
#
# Les trois sont interrogees systematiquement. Une baie qui n'en utilise
# aucune rend OK avec la mention explicite qu'aucune replication n'est
# configuree ; une baie qui en utilise deux voit les deux. Aucun mode n'est a
# activer par option.
#

package storage::ibm::flashsystem::restapi::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_partition_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'high availability status: %s, link: %s',
        $self->{result_values}->{ha_status},
        $self->{result_values}->{link_status}
    );

    # Les deux cotes ne sont renseignes que sur une partition repliquee.
    foreach my $side (1, 2) {
        my $system = $self->{result_values}->{'location' . $side . '_system_name'};
        my $status = $self->{result_values}->{'location' . $side . '_status'};
        next if ($system eq '-' && $status eq '-');
        $msg .= sprintf(', %s: %s', $system, $status);
    }

    $msg .= sprintf(', migration: %s', $self->{result_values}->{migration_status})
        if ($self->{result_values}->{migration_status} ne '-');

    return $msg;
}

sub custom_group_output {
    my ($self, %options) = @_;

    my $msg = sprintf('link status: %s', $self->{result_values}->{link1_status});

    $msg .= sprintf(', partition: %s', $self->{result_values}->{partition_name})
        if ($self->{result_values}->{partition_name} ne '-');

    # En 2-site-ha ces champs restent vides : ils ne decrivent que la
    # replication asynchrone. On ne les affiche donc que s'ils portent une
    # valeur, ce qui rend le meme mode lisible dans les deux topologies.
    foreach my $side (1, 2) {
        my $rpo = $self->{result_values}->{'location' . $side . '_within_rpo'};
        next if ($rpo eq '-');
        $msg .= sprintf(', site %s within RPO: %s', $side, $rpo);
    }

    $msg .= ', recovery test in progress'
        if ($self->{result_values}->{recovery_test_active} =~ /^yes$/i);

    return $msg;
}

sub custom_partnership_output {
    my ($self, %options) = @_;

    return sprintf(
        'partnership: %s, type: %s',
        $self->{result_values}->{partnership},
        $self->{result_values}->{type}
    );
}

sub custom_relationship_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s, progress: %s%%',
        $self->{result_values}->{state},
        $self->{result_values}->{progress}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Replication: ';
}

sub prefix_partition_output {
    my ($self, %options) = @_;

    return "Storage partition '" . $options{instance_value}->{name} . "' ";
}

sub prefix_group_output {
    my ($self, %options) = @_;

    return "Volume group replication '" . $options{instance_value}->{name} . "' ";
}

sub prefix_partnership_output {
    my ($self, %options) = @_;

    return "Partnership '" . $options{instance_value}->{name} . "' ";
}

sub prefix_relationship_output {
    my ($self, %options) = @_;

    return "Remote copy relationship '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'partitions', type => 1, cb_prefix_output => 'prefix_partition_output',
          message_multiple => 'All storage partitions are healthy', skipped_code => { -10 => 1 } },
        { name => 'groups', type => 1, cb_prefix_output => 'prefix_group_output',
          message_multiple => 'All replicated volume groups are healthy', skipped_code => { -10 => 1 } },
        { name => 'partnerships', type => 1, cb_prefix_output => 'prefix_partnership_output',
          message_multiple => 'All partnerships are healthy', skipped_code => { -10 => 1 } },
        { name => 'relationships', type => 1, cb_prefix_output => 'prefix_relationship_output',
          message_multiple => 'All remote copy relationships are healthy', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'partitions-detected', nlabel => 'replication.partitions.detected.count', set => {
                key_values => [ { name => 'partitions_detected' } ],
                output_template => '%s partition(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'volume-groups-detected', nlabel => 'replication.volumegroups.detected.count', set => {
                key_values => [ { name => 'groups_detected' } ],
                output_template => '%s replicated volume group(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'relationships-detected', nlabel => 'replication.relationships.detected.count', set => {
                key_values => [ { name => 'relationships_detected' } ],
                output_template => '%s remote copy relationship(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Les seuils par defaut signalent tout ce qui n'est pas explicitement sain.
    # Une valeur inconnue — firmware plus recent, topologie non rencontree —
    # remonte donc plutot que de passer inapercue ; --critical-status permet de
    # l'accepter ensuite, par service, sans toucher au code.
    $self->{maps_counters}->{partitions} = [
        {
            label => 'partition-status',
            type => 2,
            critical_default => '%{ha_status} !~ /^(established|healthy|synchronized)$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'ha_status' }, { name => 'link_status' },
                    { name => 'location1_system_name' }, { name => 'location1_status' },
                    { name => 'location2_system_name' }, { name => 'location2_status' },
                    { name => 'migration_status' }
                ],
                closure_custom_output => $self->can('custom_partition_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{groups} = [
        {
            label => 'volume-group-status',
            type => 2,
            # L'expression sur within_rpo est volontairement inerte quand le
            # champ est vide : elle ne se declenche qu'en replication
            # asynchrone, ou la baie le renseigne.
            critical_default => '%{link1_status} !~ /^(synchronized|running|connected)$/i'
                . ' || %{location1_within_rpo} =~ /^no$/i'
                . ' || %{location2_within_rpo} =~ /^no$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'partition_name' }, { name => 'link1_status' },
                    { name => 'location1_within_rpo' }, { name => 'location2_within_rpo' },
                    { name => 'location1_replication_mode' }, { name => 'location2_replication_mode' },
                    { name => 'recovery_test_active' }
                ],
                closure_custom_output => $self->can('custom_group_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    # Le partenariat local n'a pas d'etat : il se decrit lui-meme. Seuls les
    # partenariats distants sont evalues, d'ou le filtre pose en selection.
    $self->{maps_counters}->{partnerships} = [
        {
            label => 'partnership-status',
            type => 2,
            critical_default => '%{partnership} !~ /^fully_configured$/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'partnership' }, { name => 'type' }, { name => 'location' } ],
                closure_custom_output => $self->can('custom_partnership_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{relationships} = [
        {
            label => 'relationship-status',
            type => 2,
            critical_default => '%{state} !~ /^(consistent_synchronized|consistent_copying)$/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'state' }, { name => 'progress' }, { name => 'freeze_time' } ],
                closure_custom_output => $self->can('custom_relationship_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-partition:s'    => { name => 'filter_partition' },
        'filter-volume-group:s' => { name => 'filter_volume_group' },
        'filter-partnership:s'  => { name => 'filter_partnership' },
        'filter-relationship:s' => { name => 'filter_relationship' }
    });

    return $self;
}

# Renvoie la valeur du champ, ou '-' : les seuils et les sorties travaillent
# alors sur une chaine toujours definie, quelle que soit la version de l'API.
sub field {
    my ($entry, $name) = @_;

    return '-' if (!defined($entry->{$name}) || $entry->{$name} eq '');
    return $entry->{$name};
}

sub filtered {
    my ($self, %options) = @_;

    my $filter = $self->{option_results}->{ $options{filter} };
    return 0 if (!defined($filter) || $filter eq '');
    return 1 if ($options{value} !~ /$filter/);
    return 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        partitions_detected => 0,
        groups_detected => 0,
        relationships_detected => 0
    };
    $self->{partitions} = {};
    $self->{groups} = {};
    $self->{partnerships} = {};
    $self->{relationships} = {};

    # request_optional : lspartition n'existe qu'a partir de la 8.7, et les
    # autres commandes peuvent manquer selon le modele. Une commande absente ne
    # doit pas faire echouer le controle sur une baie ou les autres formes de
    # replication fonctionnent.
    my $partitions    = $options{custom}->request_optional(command => 'lspartition');
    my $groups        = $options{custom}->request_optional(command => 'lsvolumegroupreplication');
    my $partnerships  = $options{custom}->request_optional(command => 'lspartnership');
    my $relationships = $options{custom}->request_optional(command => 'lsrcrelationship');

    foreach my $entry (@$partitions) {
        my $name = field($entry, 'name');
        next if ($self->filtered(filter => 'filter_partition', value => $name));

        $self->{global}->{partitions_detected}++;
        $self->{partitions}->{$name} = {
            name => $name,
            ha_status => field($entry, 'ha_status'),
            link_status => field($entry, 'link_status'),
            location1_system_name => field($entry, 'location1_system_name'),
            location1_status => field($entry, 'location1_status'),
            location2_system_name => field($entry, 'location2_system_name'),
            location2_status => field($entry, 'location2_status'),
            migration_status => field($entry, 'migration_status')
        };
    }

    foreach my $entry (@$groups) {
        my $name = field($entry, 'name');
        next if ($self->filtered(filter => 'filter_volume_group', value => $name));
        # Le filtre de partition restreint aussi les groupes, par leur
        # partition d'appartenance : c'est ce qui permet un service PAR
        # partition — meme commande, meme modele, seule la macro de service
        # change. Les partenariats restent hors filtre : un partenariat casse
        # concerne toutes les partitions.
        next if ($self->filtered(filter => 'filter_partition', value => field($entry, 'partition_name')));

        $self->{global}->{groups_detected}++;
        $self->{groups}->{$name} = {
            name => $name,
            partition_name => field($entry, 'partition_name'),
            link1_status => field($entry, 'link1_status'),
            location1_within_rpo => field($entry, 'location1_within_rpo'),
            location2_within_rpo => field($entry, 'location2_within_rpo'),
            location1_replication_mode => field($entry, 'location1_replication_mode'),
            location2_replication_mode => field($entry, 'location2_replication_mode'),
            recovery_test_active => field($entry, 'recovery_test_active')
        };
    }

    foreach my $entry (@$partnerships) {
        my $name = field($entry, 'name');
        my $location = field($entry, 'location');

        # L'entree 'local' decrit la baie interrogee, pas un lien : elle n'a ni
        # partnership ni type, et n'a donc pas d'etat a evaluer.
        next if ($location =~ /^local$/i);
        next if ($self->filtered(filter => 'filter_partnership', value => $name));

        $self->{partnerships}->{$name} = {
            name => $name,
            location => $location,
            partnership => field($entry, 'partnership'),
            type => field($entry, 'type')
        };
    }

    foreach my $entry (@$relationships) {
        my $name = field($entry, 'name');
        next if ($self->filtered(filter => 'filter_relationship', value => $name));

        $self->{global}->{relationships_detected}++;
        $self->{relationships}->{$name} = {
            name => $name,
            state => field($entry, 'state'),
            progress => field($entry, 'progress'),
            freeze_time => field($entry, 'freeze_time')
        };
    }

    # Aucune replication n'est une configuration valide, pas une anomalie ni
    # une erreur de collecte : on le dit, et le service reste OK.
    if (scalar(keys %{$self->{partitions}}) == 0
        && scalar(keys %{$self->{groups}}) == 0
        && scalar(keys %{$self->{partnerships}}) == 0
        && scalar(keys %{$self->{relationships}}) == 0) {
        $self->{output}->output_add(short_msg => 'No replication configured on this system');
    }
}

1;

__END__

=head1 MODE

Check replication health: storage partitions, policy-based volume group
replication, partnerships and remote copy relationships.

All four are queried on every run. A system using none of them reports OK with
an explicit message; a system using several reports on each. Nothing has to be
enabled per array.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=replication --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--filter-partition>

Only check storage partitions whose name matches this regular expression.
Volume group replications are restricted to the matching partitions too, so
one service per partition is a matter of Centreon configuration: create a
service from the same template and set the service-level C<EXTRAOPTIONS>
macro, e.g. C<--filter-partition=Partition_AIX_HA>. Partnerships stay
unfiltered — a broken partnership concerns every partition.

=item B<--filter-volume-group>

Only check volume group replications whose name matches this regular expression.

=item B<--filter-partnership>

Only check partnerships whose name matches this regular expression.

=item B<--filter-relationship>

Only check remote copy relationships whose name matches this regular expression.

=item B<--unknown-partition-status> B<--warning-partition-status> B<--critical-partition-status>

Threshold on the partition state. Available macros: C<ha_status>,
C<link_status>, C<location1_system_name>, C<location1_status>,
C<location2_system_name>, C<location2_status>, C<migration_status>, C<name>.

Default critical: C<%{ha_status} !~ /^(established|healthy|synchronized)$/i>

=item B<--unknown-volume-group-status> B<--warning-volume-group-status> B<--critical-volume-group-status>

Threshold on the volume group replication state. Available macros:
C<link1_status>, C<partition_name>, C<location1_within_rpo>,
C<location2_within_rpo>, C<location1_replication_mode>,
C<location2_replication_mode>, C<recovery_test_active>, C<name>.

The C<within_rpo> macros stay empty in C<2-site-ha> topologies, where they do
not apply; the default expression is inert in that case and only triggers on
asynchronous replication.

=item B<--unknown-partnership-status> B<--warning-partnership-status> B<--critical-partnership-status>

Threshold on the partnership state. Available macros: C<partnership>, C<type>,
C<location>, C<name>.

=item B<--unknown-relationship-status> B<--warning-relationship-status> B<--critical-relationship-status>

Threshold on the remote copy relationship state. Available macros: C<state>,
C<progress>, C<freeze_time>, C<name>.

=item B<--warning-*> B<--critical-*>

Thresholds on the detected counts: C<partitions-detected>,
C<volume-groups-detected>, C<relationships-detected>.

=back

=cut
