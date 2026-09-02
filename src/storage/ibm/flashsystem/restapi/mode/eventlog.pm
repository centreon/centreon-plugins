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
# Journal d'evenements non resolus.
#
# Piege central de cette commande : filtrer sur 'fixed=no' seul ne suffit pas.
# Le journal melange des entrees 'alert', qui appellent une action, et des
# entrees 'message' purement informatives, qui ne se resolvent jamais parce
# qu'un message ne se corrige pas. Une baie peut ainsi porter des centaines
# d'entrees non resolues sans qu'aucune ne soit un probleme.
#
# Ce sont les entrees 'alert' qui reproduisent le panneau "Recommended Actions"
# de l'interface. Les 'message' sont comptes et exposes en metrique, mais ne
# declenchent rien par defaut.
#

package storage::ibm::flashsystem::restapi::mode::eventlog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_event_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', error code: %s', $self->{result_values}->{error_code})
        if ($self->{result_values}->{error_code} ne '-');
    $msg .= sprintf(', event id: %s', $self->{result_values}->{event_id})
        if ($self->{result_values}->{event_id} ne '-');
    $msg .= sprintf(', object: %s %s', $self->{result_values}->{object_type}, $self->{result_values}->{object_name})
        if ($self->{result_values}->{object_name} ne '-');
    $msg .= sprintf(', last seen: %s', $self->{result_values}->{last_timestamp})
        if ($self->{result_values}->{last_timestamp} ne '-');
    $msg .= sprintf(' [%s]', $self->{result_values}->{description})
        if ($self->{result_values}->{description} ne '-');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Unfixed event log entries: ';
}

sub prefix_event_output {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{sequence_number} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'events', type => 1, cb_prefix_output => 'prefix_event_output',
          message_multiple => 'No actionable event', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alerts', nlabel => 'eventlog.alerts.count', set => {
                key_values => [ { name => 'alerts' } ],
                output_template => '%s alert(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'messages', nlabel => 'eventlog.messages.count', set => {
                key_values => [ { name => 'messages' } ],
                output_template => '%s message(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Toute entree retenue est signalee : le tri a deja eu lieu au moment de la
    # selection. On ne masque rien ici.
    $self->{maps_counters}->{events} = [
        {
            label => 'event-status',
            type => 2,
            critical_default => '%{status} =~ /^alert$/i',
            set => {
                key_values => [
                    { name => 'sequence_number' }, { name => 'status' }, { name => 'error_code' },
                    { name => 'event_id' }, { name => 'object_type' }, { name => 'object_name' },
                    { name => 'description' }, { name => 'last_timestamp' }
                ],
                closure_custom_output => $self->can('custom_event_output'),
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
        'filter-status:s'      => { name => 'filter_status' },
        'filter-error-code:s'  => { name => 'filter_error_code' },
        'filter-event-id:s'    => { name => 'filter_event_id' },
        'filter-object-type:s' => { name => 'filter_object_type' },
        'filter-object-name:s' => { name => 'filter_object_name' }
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

    # Le tri se fait cote plugin plutot que dans le filtervalue de l'API : on
    # veut compter les 'message' pour les exposer en metrique, sans les
    # transformer en instances a evaluer.
    my $entries = $options{custom}->request(
        command => 'lseventlog',
        payload => { filtervalue => 'fixed=no' }
    );

    # Par defaut on ne retient que les alertes comme instances a evaluer. Le
    # filtre est une option, pas une valeur en dur : une baie dont on voudrait
    # aussi voir les messages se configure sans toucher au code.
    my $status_filter = defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne ''
        ? $self->{option_results}->{filter_status}
        : '^alert$';

    $self->{global} = { alerts => 0, messages => 0 };
    $self->{events} = {};

    foreach my $entry (@$entries) {
        my $status = field($entry, 'status');

        if ($status =~ /^alert$/i) {
            $self->{global}->{alerts}++;
        } elsif ($status =~ /^message$/i) {
            $self->{global}->{messages}++;
        }

        next if ($status !~ /$status_filter/i);

        my $error_code  = field($entry, 'error_code');
        my $event_id    = field($entry, 'event_id');
        my $object_type = field($entry, 'object_type');
        my $object_name = field($entry, 'object_name');

        next if (defined($self->{option_results}->{filter_error_code}) && $self->{option_results}->{filter_error_code} ne ''
            && $error_code !~ /$self->{option_results}->{filter_error_code}/);
        next if (defined($self->{option_results}->{filter_event_id}) && $self->{option_results}->{filter_event_id} ne ''
            && $event_id !~ /$self->{option_results}->{filter_event_id}/);
        next if (defined($self->{option_results}->{filter_object_type}) && $self->{option_results}->{filter_object_type} ne ''
            && $object_type !~ /$self->{option_results}->{filter_object_type}/);
        next if (defined($self->{option_results}->{filter_object_name}) && $self->{option_results}->{filter_object_name} ne ''
            && $object_name !~ /$self->{option_results}->{filter_object_name}/);

        my $sequence = field($entry, 'sequence_number');
        $self->{events}->{$sequence} = {
            sequence_number => $sequence,
            status => $status,
            error_code => $error_code,
            event_id => $event_id,
            object_type => $object_type,
            object_name => $object_name,
            description => field($entry, 'description'),
            last_timestamp => field($entry, 'last_timestamp')
        };
    }
}

1;

__END__

=head1 MODE

Check unfixed entries of the event log.

The array reports two kinds of unfixed entries: C<alert>, which require an
action and populate the "Recommended Actions" panel of the GUI, and C<message>,
which are informational and never clear. Only alerts are evaluated by default;
messages are counted and exposed as a metric.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=eventlog --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--filter-status>

Regular expression selecting which entries become checkable instances
(default: C<^alert$>). Set it to C<.> to also evaluate informational messages.

=item B<--filter-error-code> B<--filter-event-id> B<--filter-object-type> B<--filter-object-name>

Further restrict the selected entries. Empty by default: nothing is hidden
unless it is explicitly excluded.

=item B<--unknown-event-status> B<--warning-event-status> B<--critical-event-status>

Threshold on each selected entry. Available macros: C<status>, C<error_code>,
C<event_id>, C<object_type>, C<object_name>, C<description>,
C<last_timestamp>, C<sequence_number>.

Default critical: C<%{status} =~ /^alert$/i>

=item B<--warning-alerts> B<--critical-alerts> B<--warning-messages> B<--critical-messages>

Thresholds on the number of unfixed alerts and messages.

=back

=cut
