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
# Ports Ethernet et IP.
#
# Deux commandes, deux objets differents, et la confusion est facile :
#
#   lsportethernet  le port PHYSIQUE. link_state, vitesse negociee, et les
#                   drapeaux qui disent a quoi il sert : management, host,
#                   storage, replication.
#   lsportip        la configuration IP posee dessus. Une entree par port et par
#                   usage, d'ou plusieurs lignes pour un meme port physique.
#
# Sur les baies relevees, les 12 entrees IP sont 'unconfigured' — l'iSCSI n'est
# pas utilise, tout passe en Fibre Channel — et 2 des 6 ports physiques sont
# actifs a 1 Gb/s. Le mode ne considere donc pas un port inactif comme une
# panne : un port non cable est un choix de cablage, pas un defaut.
#
# ATTENTION aux drapeaux management/host/storage/replication : ce sont les
# usages AUTORISES sur le port, pas les usages en cours. La premiere version de
# ce mode alertait sur « porte un role et lien inactif », ce qui a mis les
# quatre ports non cables en CRITICAL permanent — ils portent tous les roles
# parce que rien ne les interdit, pas parce qu'ils servent. Le seul signe qu'un
# port est reellement en service est une adresse IP configuree dessus.
#

package storage::ibm::flashsystem::restapi::mode::ethports;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# Drapeaux de lsportethernet qui donnent un role au port. Un port sans aucun
# role n'est pas surveille : il n'est simplement pas utilise.
my $ROLES = [
    { field => 'management',  label => 'management' },
    { field => 'host',        label => 'host' },
    { field => 'storage',     label => 'storage' },
    { field => 'replication', label => 'replication' }
];

sub custom_port_output {
    my ($self, %options) = @_;

    my $msg = sprintf('link %s', $self->{result_values}->{link_state});

    $msg .= sprintf(', speed %s', $self->{result_values}->{speed})
        if ($self->{result_values}->{speed} ne '-');
    $msg .= sprintf(', roles: %s', $self->{result_values}->{roles})
        if ($self->{result_values}->{roles} ne '-');
    $msg .= sprintf(', %s', $self->{result_values}->{ip})
        if ($self->{result_values}->{ip} ne '-');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Ethernet ports: ';
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "Port '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'ports', type => 1, cb_prefix_output => 'prefix_port_output',
          message_multiple => 'All Ethernet ports in service are active',
          skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'ethports.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'active', nlabel => 'ethports.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => '%s active',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        # « role-capable » et non « carrying a role » : les drapeaux disent ce
        # qu'un port a le droit de porter. Les six le peuvent, deux servent.
        # Le compteur qui dit combien servent vraiment, c'est ip-configured.
        { label => 'with-role', nlabel => 'ethports.withrole.count', set => {
                key_values => [ { name => 'with_role' } ],
                output_template => '%s role-capable',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'ip-configured', nlabel => 'ethports.ip.configured.count', set => {
                key_values => [ { name => 'ip_configured' } ],
                output_template => '%s IP configured',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Un port inactif non configure est normal : il n'est pas cable. Le seuil
    # ne porte que sur les ports qui portent une adresse IP, seul signe qu'ils
    # sont reellement en service.
    $self->{maps_counters}->{ports} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{configured} eq "yes" and %{link_state} !~ /^active$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'link_state' }, { name => 'speed' },
                    { name => 'roles' }, { name => 'ip' }, { name => 'node_name' },
                    { name => 'port_id' }, { name => 'configured' }
                ],
                closure_custom_output => $self->can('custom_port_output'),
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
        'filter-name:s'  => { name => 'filter_name' },
        'add-unused'     => { name => 'add_unused' }
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

    # lsportip a plusieurs entrees par port physique, indexees par 'id' et non
    # par 'port_id'. On garde la premiere adresse reellement configuree.
    my %addresses;
    my $ip_configured = 0;
    foreach my $entry (@{ $options{custom}->request_optional(command => 'lsportip') }) {
        next unless (ref $entry eq 'HASH');
        my $state = field($entry, 'state');
        next if ($state =~ /^unconfigured$/i);
        $ip_configured++;

        my $key = field($entry, 'node_name') . '-' . field($entry, 'id');
        my $address = field($entry, 'IP_address');
        $addresses{$key} = $address if ($address ne '-' && !exists($addresses{$key}));
    }

    $self->{global} = { detected => 0, active => 0, with_role => 0, ip_configured => $ip_configured };
    $self->{ports} = {};

    foreach my $port (@{ $options{custom}->request(command => 'lsportethernet') }) {
        my $name = field($port, 'node_name') . '-' . field($port, 'port_id');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/);

        my $link = field($port, 'link_state');

        # Un port « porte un role » des qu'un des drapeaux est arme. Les valeurs
        # observees sont 'yes'/'no', mais certains firmwares rendent le nom du
        # role : on accepte tout ce qui n'est ni vide ni 'no'.
        my @roles;
        foreach my $role (@$ROLES) {
            my $value = field($port, $role->{field});
            push @roles, $role->{label} if ($value ne '-' && $value !~ /^no$/i);
        }
        my $roles = @roles ? join('/', @roles) : '-';

        $self->{global}->{detected}++;
        $self->{global}->{active}++ if ($link =~ /^active$/i);
        $self->{global}->{with_role}++ if ($roles ne '-');

        my $configured = exists($addresses{$name}) ? 'yes' : 'no';

        # Ni adresse ni lien : le port n'est pas cable. L'exposer ferait du
        # bruit permanent. --add-unused le rend visible quand on veut
        # l'inventaire complet.
        next if ($configured eq 'no' && $link !~ /^active$/i
                 && !defined($self->{option_results}->{add_unused}));

        $self->{ports}->{$name} = {
            name => $name,
            link_state => $link,
            speed => field($port, 'speed'),
            roles => $roles,
            ip => exists($addresses{$name}) ? $addresses{$name} : '-',
            node_name => field($port, 'node_name'),
            port_id => field($port, 'port_id'),
            configured => $configured
        };
    }
}

1;

__END__

=head1 MODE

Check the Ethernet ports and their IP configuration.

Two commands describe two different things, and mixing them up is easy:

=over 4

=item * C<lsportethernet> is the B<physical> port: link state, negotiated speed,
and the flags saying what it is used for — management, host, storage,
replication.

=item * C<lsportip> is the IP configuration laid on top. There is one entry per
port B<and per use>, so a single physical port produces several rows, keyed on
C<id> rather than C<port_id>.

=back

On the arrays surveyed, all twelve IP entries are C<unconfigured> — iSCSI is not
used, everything goes over Fibre Channel — and two of the six physical ports are
active at 1 Gb/s.

So an inactive port is B<not> treated as a fault: an uncabled port is a cabling
choice, not a defect, and alerting on it would produce permanent noise.

B<Do not threshold on the role flags.> C<management>, C<host>, C<storage> and
C<replication> report what a port is B<allowed> to carry, not what it currently
carries: an uncabled port has them all set simply because nothing forbids them.
Thresholding on "carries a role and link is down" put all four uncabled ports in
permanent CRITICAL. The one reliable sign that a port is in service is an IP
address configured on it, which is what the default threshold uses.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=eth-ports --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure

=over 8

=item B<--filter-name>

Only check ports whose C<node-port> name matches this regular expression.

=item B<--add-unused>

Also report ports that carry no role and have no link — the full inventory
rather than just what is in service.

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each port. Available macros: C<name>, C<link_state>, C<speed>,
C<roles>, C<ip>, C<node_name>, C<port_id>, C<configured>.

Default critical: C<%{configured} eq "yes" and %{link_state} !~ /^active$/i>

To also require a negotiated speed on the management ports:

    --warning-status='%{roles} =~ /management/ && %{speed} !~ /^1Gb/'

With no iSCSI in service, no port carries an address and the mode reports the
inventory without ever alerting. That is the intended behaviour: it starts
alerting by itself the day an address is configured.

=item B<--warning-active> B<--critical-active> B<--warning-with-role> B<--critical-with-role> B<--warning-ip-configured> B<--critical-ip-configured>

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=back

=cut
