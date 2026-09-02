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
# Etat du materiel.
#
# lsenclosure porte deja les compteurs online/total de chaque sous-ensemble du
# chassis : alimentations, canisters, ventilateurs, SEM. Une seule commande
# suffit donc la ou l'approche naive en demandait quatre.
#
# Un sous-ensemble dont le total vaut 0 n'est pas installe sur ce modele : il
# est ignore et non compte comme defaillant. C'est ce qui permet au meme mode
# de couvrir un FlashSystem 5300 sans SEM et un chassis qui en possede.
#

package storage::ibm::flashsystem::restapi::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# Les familles d'objets interrogees, avec le libelle affiche. La liste est
# parcourue telle quelle : ajouter une famille ne demande qu'une ligne.
#
# id_fields : les champs ou chercher l'identite, dans l'ordre. Le premier
# renseigne gagne. Les objets de Storage Virtualize ne portent pas tous la meme
# clef — un ventilateur s'appelle fan_module_id, un quorum applicatif n'a ni
# name ni id et n'est designe que par quorum_index. Essayer plusieurs champs
# evite d'avoir a le deviner famille par famille, et evite surtout le « '-' »
# qui rendait le message d'alerte illisible.
my $COMPONENT_COMMANDS = [
    { command => 'lsenclosure',         label => 'enclosure' },
    { command => 'lsnodecanister',      label => 'node canister' },
    { command => 'lsenclosurecanister', label => 'expansion canister' },
    { command => 'lsenclosurepsu',      label => 'power supply' },
    { command => 'lsenclosurebattery',  label => 'battery' },
    { command => 'lsenclosurefanmodule', label => 'fan module', id_fields => [ 'fan_module_id' ] },
    { command => 'lsdrive',             label => 'drive' },
    { command => 'lsarray',             label => 'array' },
    { command => 'lsmdisk',             label => 'mdisk' },
    { command => 'lsquorum',            label => 'quorum', id_fields => [ 'quorum_index' ] }
];

# Sous-ensembles decrits par un couple online_X / total_X dans lsenclosure.
my $ENCLOSURE_SUBSYSTEMS = [
    { field => 'PSUs',        label => 'power supplies' },
    { field => 'canisters',   label => 'canisters' },
    { field => 'fan_modules', label => 'fan modules' },
    { field => 'sems',        label => 'secondary expander modules' }
];

sub custom_component_output {
    my ($self, %options) = @_;

    return sprintf('status: %s', $self->{result_values}->{status});
}

sub custom_subsystem_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s online: %s/%s',
        $self->{result_values}->{label},
        $self->{result_values}->{online},
        $self->{result_values}->{total}
    );
}

# Compteurs environnementaux exposes par lssystemstats. Ce sont des grandeurs
# physiques du chassis, pas de la performance : leur place est ici.
my $ENVIRONMENT_STATS = [
    { stat => 'temp_c',  key => 'temperature', label => 'temperature', unit => 'C' },
    { stat => 'power_w', key => 'power',       label => 'power draw',  unit => 'W' }
];

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Hardware: ';
}

sub prefix_environment_output {
    my ($self, %options) = @_;

    return 'Enclosure: ';
}

sub prefix_component_output {
    my ($self, %options) = @_;

    return ucfirst($options{instance_value}->{type}) . " '" . $options{instance_value}->{name} . "' ";
}

sub prefix_subsystem_output {
    my ($self, %options) = @_;

    return "Enclosure '" . $options{instance_value}->{enclosure} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'components', type => 1, cb_prefix_output => 'prefix_component_output',
          message_multiple => 'All hardware components are online', skipped_code => { -10 => 1 } },
        { name => 'environment', type => 0, cb_prefix_output => 'prefix_environment_output' },
        { name => 'subsystems', type => 1, cb_prefix_output => 'prefix_subsystem_output',
          message_multiple => 'All enclosure subsystems are fully populated', skipped_code => { -10 => 1 } }
    ];

    # Grandeurs physiques du chassis. Aucun seuil par defaut : le bon reglage
    # depend de la salle et du modele, pas d'une regle generale. La metrique est
    # tracee dans tous les cas, ce qui permet de la regler sur l'observe.
    $self->{maps_counters}->{environment} = [
        { label => 'temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature %s C',
                perfdatas => [ { template => '%s', unit => 'C' } ]
            }
        },
        { label => 'power', nlabel => 'hardware.power.watt', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'power draw %s W',
                perfdatas => [ { template => '%s', unit => 'W', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'components-detected', nlabel => 'hardware.components.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s component(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'components-degraded', nlabel => 'hardware.components.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s not online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # CRITICAL = perte de SERVICE, WARNING = perte de REDONDANCE. Tout ce
    # materiel est redonde (2 alimentations, 2 canisters, 6 ventilateurs, DRAID
    # sur 12 disques) : un composant 'degraded' entame la marge, il n'arrete
    # rien. Le confondre avec 'offline' reveille l'astreinte pour un defaut qui
    # attend l'heure ouvree — et, a l'inverse, noie le vrai arret dans le lot.
    $self->{maps_counters}->{components} = [
        {
            label => 'component-status',
            type => 2,
            critical_default => '%{status} =~ /^(offline|excluded)$/i',
            warning_default => '%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'type' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_component_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    # Meme principe sur les sous-ensembles du chassis : une alimentation sur
    # deux est une redondance perdue (WARNING), zero alimentation en ligne est
    # un arret (CRITICAL).
    $self->{maps_counters}->{subsystems} = [
        {
            label => 'subsystem-status',
            type => 2,
            critical_default => '%{online} == 0',
            warning_default => '%{online} < %{total}',
            set => {
                key_values => [ { name => 'enclosure' }, { name => 'label' }, { name => 'online' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_subsystem_output'),
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
        'filter-type:s' => { name => 'filter_type' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub field {
    my ($entry, $name) = @_;

    return '-' if (!defined($entry->{$name}) || $entry->{$name} eq '');
    return $entry->{$name};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0, degraded => 0 };
    $self->{environment} = {};
    $self->{components} = {};
    $self->{subsystems} = {};

    # Temperature et consommation viennent de lssystemstats, avec les compteurs
    # de performance — mais ce sont des grandeurs physiques du chassis, donc
    # elles se lisent ici plutot que dans le mode performance.
    my %stats;
    foreach my $entry (@{ $options{custom}->request_optional(command => 'lssystemstats') }) {
        next unless (ref $entry eq 'HASH' && defined($entry->{stat_name}));
        $stats{ $entry->{stat_name} } = $entry->{stat_current};
    }
    foreach my $measure (@$ENVIRONMENT_STATS) {
        my $value = $stats{ $measure->{stat} };
        next if (!defined($value) || $value !~ /^-?\d+(?:\.\d+)?$/);
        $self->{environment}->{ $measure->{key} } = $value;
    }

    foreach my $family (@$COMPONENT_COMMANDS) {
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne ''
            && $family->{label} !~ /$self->{option_results}->{filter_type}/);

        # Une famille absente du modele ou du firmware ne doit pas faire
        # echouer le controle des autres.
        my $entries = $options{custom}->request_optional(command => $family->{command});

        foreach my $entry (@$entries) {
            # Tous les objets n'ont pas de champ 'name' : un disque ou une
            # alimentation ne portent qu'un identifiant. On prend le premier
            # champ renseigne, en commencant par ceux propres a la famille.
            my @candidates = ('name');
            push @candidates, @{ $family->{id_fields} } if (defined($family->{id_fields}));
            push @candidates, 'id';

            my $name = '-';
            foreach my $candidate (@candidates) {
                next if (!defined($entry->{$candidate}) || $entry->{$candidate} eq '');
                $name = $entry->{$candidate};
                last;
            }
            my $instance = $family->{label} . '.' . $name;

            next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
                && $name !~ /$self->{option_results}->{filter_name}/);

            my $status = field($entry, 'status');

            $self->{global}->{detected}++;
            $self->{global}->{degraded}++ if ($status !~ /^online$/i);

            $self->{components}->{$instance} = {
                name => $name,
                type => $family->{label},
                status => $status
            };

            next if ($family->{command} ne 'lsenclosure');

            # Compteurs online/total portes par le chassis lui-meme.
            foreach my $subsystem (@$ENCLOSURE_SUBSYSTEMS) {
                my $online = $entry->{'online_' . $subsystem->{field}};
                my $total  = $entry->{'total_' . $subsystem->{field}};

                next if (!defined($online) || !defined($total));
                next if ($online !~ /^\d+$/ || $total !~ /^\d+$/);
                # total = 0 : le sous-ensemble n'existe pas sur ce materiel.
                next if ($total == 0);

                $self->{subsystems}->{ $name . '.' . $subsystem->{field} } = {
                    enclosure => $name,
                    label => $subsystem->{label},
                    online => $online,
                    total => $total
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check hardware health: enclosures, node and expansion canisters, power
supplies, batteries, drives, arrays, mdisks and quorum devices.

Enclosure subsystems are additionally checked through the C<online_*>/C<total_*>
counters the enclosure itself reports. A subsystem whose total is zero is not
fitted on that model and is skipped rather than counted as missing.

Families that do not exist on a given model or firmware are skipped silently,
so the same mode covers every Storage Virtualize system.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=hardware --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--filter-type>

Only check component families whose label matches this regular expression
(enclosure, node canister, expansion canister, power supply, battery, drive,
array, mdisk, quorum).

=item B<--filter-name>

Only check components whose name or id matches this regular expression.

=item B<--unknown-component-status> B<--warning-component-status> B<--critical-component-status>

Threshold on each component. Available macros: C<name>, C<type>, C<status>.

Default critical: C<%{status} =~ /^(offline|excluded)$/i>

Default warning: C<%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i>

Critical means B<service lost>, warning means B<redundancy lost>. Every part
here is redundant — two power supplies, two canisters, six fan modules, a DRAID
across twelve drives — so a degraded component eats the margin without stopping
anything. Merging the two wakes someone up for a fault that can wait for
business hours, and buries the real outage among them.

=item B<--unknown-subsystem-status> B<--warning-subsystem-status> B<--critical-subsystem-status>

Threshold on each enclosure subsystem. Available macros: C<enclosure>,
C<label>, C<online>, C<total>.

Default critical: C<%{online} == 0> — nothing left in that subsystem.

Default warning: C<%{online} E<lt> %{total}> — one power supply out of two is a
lost redundancy, not an outage.

=item B<--warning-components-degraded> B<--critical-components-degraded>

Thresholds on the number of components that are not online.

=back

=cut
