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
# Ports Fibre Channel — le chemin de donnees, que le mode hardware ne couvre pas.
#
# Deux precisions tirees de l'API :
#
#   - lsportfc n'expose NI compteur d'erreurs NI debit. Les seuls etats sont le
#     statut, la vitesse negociee et le rattachement. Le debit FC ne s'obtient
#     qu'au niveau du noeud, via lsnodecanisterstats.
#   - un port equipe d'un SFP mais non raccorde remonte 'inactive_configured'
#     en permanence, par conception IBM, et aucune option ne change ce
#     comportement. Le seuil par defaut ne le traite donc pas comme une panne :
#     il alerte sur ce qui a cesse d'etre actif, pas sur ce qui ne l'a jamais ete.
#
# lstargetportfc ajoute le nombre de connexions hotes par port : un port actif
# qui perd ses connexions est un chemin perdu, invisible autrement.
#

package storage::ibm::flashsystem::restapi::mode::fcports;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_port_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s, speed: %s, attachment: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{port_speed},
        $self->{result_values}->{attachment}
    );

    $msg .= sprintf(', host logins: %s', $self->{result_values}->{active_login_count})
        if ($self->{result_values}->{active_login_count} ne '-');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Fibre Channel ports: ';
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
          message_multiple => 'All Fibre Channel ports are active', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'fcports.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'active', nlabel => 'fcports.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => '%s active',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'inactive', nlabel => 'fcports.inactive.count', set => {
                key_values => [ { name => 'inactive' } ],
                output_template => '%s inactive',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'host-logins', nlabel => 'fcports.host.logins.count', set => {
                key_values => [ { name => 'host_logins' } ],
                output_template => '%s host login(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # 'inactive_unconfigured' = pas de SFP, 'inactive_configured' = SFP pose mais
    # rien de branche : deux etats normaux sur une baie partiellement cablee.
    # Alerter dessus produirait un Critical perpetuel, ce qui apprend a l'equipe
    # a ignorer le service. On ne retient donc que les etats qui traduisent une
    # degradation reelle.
    $self->{maps_counters}->{ports} = [
        {
            label => 'status',
            type => 2,
            critical_default =>
                '%{status} !~ /^(active|inactive_configured|inactive_unconfigured)$/i',
            warning_default => '%{status} =~ /^inactive_configured$/i and %{attachment} =~ /^switch$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'port_speed' },
                    { name => 'attachment' }, { name => 'node_name' }, { name => 'port_id' },
                    { name => 'type' }, { name => 'active_login_count' }
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
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type' }
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

    # Les connexions hotes se lisent sur les ports virtualises (NPIV), indexes
    # par fc_io_port_id. On les agrege avant de les rattacher aux ports
    # physiques.
    my %logins;
    foreach my $target (@{ $options{custom}->request_optional(command => 'lstargetportfc') }) {
        my $port = field($target, 'fc_io_port_id');
        my $count = $target->{active_login_count};
        next if ($port eq '-' || !defined($count) || $count !~ /^\d+$/);
        $logins{$port} += $count;
    }

    $self->{global} = { detected => 0, active => 0, inactive => 0, host_logins => 0 };
    $self->{ports} = {};

    foreach my $port (@{ $options{custom}->request(command => 'lsportfc') }) {
        # Les identifiants de port ne sont pas contigus — 0 a 3 puis 24 a 27 —
        # donc un service « Port 24 » n'aiderait personne. On nomme par noeud et
        # numero de port, ce que lit un exploitant.
        my $name = field($port, 'node_name') . '-' . field($port, 'port_id');
        my $type = field($port, 'type');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne ''
            && $type !~ /$self->{option_results}->{filter_type}/);

        my $status = field($port, 'status');
        my $io_port = field($port, 'fc_io_port_id');
        my $login_count = defined($logins{$io_port}) ? $logins{$io_port} : '-';

        $self->{global}->{detected}++;
        if ($status =~ /^active$/i) {
            $self->{global}->{active}++;
        } else {
            $self->{global}->{inactive}++;
        }
        $self->{global}->{host_logins} += $login_count if ($login_count ne '-');

        $self->{ports}->{$name} = {
            name => $name,
            status => $status,
            port_speed => field($port, 'port_speed'),
            attachment => field($port, 'attachment'),
            node_name => field($port, 'node_name'),
            port_id => field($port, 'port_id'),
            type => $type,
            active_login_count => $login_count
        };
    }
}

1;

__END__

=head1 MODE

Check the Fibre Channel ports — the data path, which the C<hardware> mode does
not cover.

C<lsportfc> exposes neither error counters nor throughput: status, negotiated
speed and attachment are all there is. Throughput is only available per node,
through C<lsnodecanisterstats>.

Host logins come from C<lstargetportfc>, aggregated per physical port. An active
port that loses its logins is a lost path, and nothing else would show it.

Ports are named after their node and port number — C<node1-1> — because port ids
are not contiguous (0 to 3 then 24 to 27 on a two-canister system), so a service
called "Port 24" would help nobody.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=fc-ports --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure

=over 8

=item B<--filter-name>

Only check ports whose C<node-port> name matches this regular expression.

=item B<--filter-type>

Only check ports of this type (C<fc>, C<ethernet>…).

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each port. Available macros: C<name>, C<status>, C<port_speed>,
C<attachment>, C<node_name>, C<port_id>, C<type>, C<active_login_count>.

Default warning: C<%{status} =~ /^inactive_configured$/i and %{attachment} =~ /^switch$/i>

Default critical: C<%{status} !~ /^(active|inactive_configured|inactive_unconfigured)$/i>

A port fitted with an SFP but cabled to nothing reports C<inactive_configured>
permanently, by IBM design, and no option changes that. Treating it as a fault
would make the service critical forever, which teaches people to ignore it. The
defaults therefore only warn when such a port claims to be attached to a switch,
and only alert on states that mean something actually degraded.

To require a negotiated speed, add it explicitly:

    --critical-status='%{status} !~ /^active$/i || %{port_speed} !~ /^16Gb$/'

=item B<--warning-active> B<--critical-active> B<--warning-inactive> B<--critical-inactive>

Thresholds on the number of active and inactive ports.

=item B<--warning-host-logins> B<--critical-host-logins>

Threshold on the total number of host logins across all ports. Useful to catch
a fabric-wide loss that leaves every port nominally active.

=back

=cut
