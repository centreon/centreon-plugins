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
# Etat des hotes declares sur la baie.
#
# Aucune exclusion n'est ecrite dans le plugin. Un hote hors ligne remonte,
# qu'il le soit par panne ou par construction : c'est le role de la supervision
# de refleter l'etat reel. Un hote hors ligne en toute connaissance de cause
# s'acquitte ou se met en maintenance dans Centreon — ce qui laisse une trace
# et une date de revue, la ou un filtre code en dur le ferait disparaitre
# silencieusement.
#
# --filter-name reste disponible pour restreindre le perimetre d'un service,
# mais il est vide par defaut.
#

package storage::ibm::flashsystem::restapi::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_host_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', ports: %s', $self->{result_values}->{port_count})
        if ($self->{result_values}->{port_count} ne '-');
    $msg .= sprintf(', host cluster: %s', $self->{result_values}->{host_cluster_name})
        if ($self->{result_values}->{host_cluster_name} ne '-');
    $msg .= sprintf(', partition: %s', $self->{result_values}->{partition_name})
        if ($self->{result_values}->{partition_name} ne '-');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Hosts: ';
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'hosts', type => 1, cb_prefix_output => 'prefix_host_output',
          message_multiple => 'All hosts are online', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'hosts.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s declared',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'online', nlabel => 'hosts.online.count', set => {
                key_values => [ { name => 'online' } ],
                output_template => '%s online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'offline', nlabel => 'hosts.offline.count', set => {
                key_values => [ { name => 'offline' } ],
                output_template => '%s offline',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'degraded', nlabel => 'hosts.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s degraded',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Les deux etats ne disent pas ce qu'on croit, et l'ordre de gravite
    # naturel est INVERSE :
    #
    #   offline  = plus aucun WWPN de l'hote ne se connecte. La baie ne sait
    #              pas distinguer un serveur eteint a dessein d'un serveur en
    #              panne — et le cas courant est le premier (reserves,
    #              sauvegardes). Ce n'est pas un defaut de la baie : WARNING,
    #              visible sans reveiller l'astreinte.
    #   degraded = une PARTIE seulement des chemins repond. L'hote tourne, en
    #              production, sur une redondance entamee : le prochain chemin
    #              perdu lui coupe son stockage. C'est actionnable tout de
    #              suite (zoning, SFP, switch) et souvent le seul endroit ou ce
    #              defaut de fabrique se voit : CRITICAL.
    $self->{maps_counters}->{hosts} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /^degraded$/i',
            warning_default => '%{status} =~ /^offline$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'port_count' },
                    { name => 'host_cluster_name' }, { name => 'partition_name' }
                ],
                closure_custom_output => $self->can('custom_host_output'),
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
        'filter-name:s'      => { name => 'filter_name' },
        'filter-partition:s' => { name => 'filter_partition' }
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

    my $entries = $options{custom}->request(command => 'lshost');

    $self->{global} = { detected => 0, online => 0, offline => 0, degraded => 0 };
    $self->{hosts} = {};

    foreach my $entry (@$entries) {
        my $name = field($entry, 'name');
        my $partition = field($entry, 'partition_name');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_partition}) && $self->{option_results}->{filter_partition} ne ''
            && $partition !~ /$self->{option_results}->{filter_partition}/);

        my $status = field($entry, 'status');

        $self->{global}->{detected}++;
        $self->{global}->{online}++   if ($status =~ /^online$/i);
        $self->{global}->{offline}++  if ($status =~ /^offline$/i);
        $self->{global}->{degraded}++ if ($status =~ /^degraded$/i);

        $self->{hosts}->{$name} = {
            name => $name,
            status => $status,
            port_count => field($entry, 'port_count'),
            host_cluster_name => field($entry, 'host_cluster_name'),
            partition_name => $partition
        };
    }
}

1;

__END__

=head1 MODE

Check the status of the hosts declared on the system.

Every declared host is evaluated. A host that is offline on purpose — a spare
LPAR profile, an idle backup host — still reports offline: acknowledging it in
Centreon records who decided it is expected and when that should be revisited,
which a hard-coded exclusion would not.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=hosts --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--filter-name>

Only check hosts whose name matches this regular expression. Empty by default.

=item B<--filter-partition>

Only check hosts belonging to a storage partition matching this regular
expression. Empty by default.

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each host. Available macros: C<name>, C<status>, C<port_count>,
C<host_cluster_name>, C<partition_name>.

Default warning: C<%{status} =~ /^offline$/i>

Default critical: C<%{status} =~ /^degraded$/i>

The natural order of severity is B<inverted> here, on purpose. C<offline> means
no WWPN of that host connects any more: the array cannot tell a deliberately
powered-off server from a failed one, and the common case is the former
(spares, backup hosts) — a warning keeps it visible without waking anyone.
C<degraded> means only B<part> of the paths answer: the host is running, in
production, on eaten-into redundancy, and the next lost path cuts its storage.
That is actionable right now (zoning, SFP, switch) and is often the only place
such a fabric fault shows up.

=item B<--warning-offline> B<--critical-offline> B<--warning-degraded> B<--critical-degraded>

Thresholds on the number of offline and degraded hosts.

=back

=cut
