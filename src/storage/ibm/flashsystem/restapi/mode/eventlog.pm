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

package storage::ibm::flashsystem::restapi::mode::eventlog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_event_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', error code: %s', $self->{result_values}->{error_code})
        if (is_not_empty($self->{result_values}->{error_code}));
    $msg .= sprintf(', event id: %s', $self->{result_values}->{event_id})
        if (is_not_empty($self->{result_values}->{event_id}));
    $msg .= sprintf(', object: %s %s', $self->{result_values}->{object_type}, $self->{result_values}->{object_name})
        if (is_not_empty($self->{result_values}->{object_name}));
    $msg .= sprintf(', last seen: %s', $self->{result_values}->{last_timestamp})
        if (is_not_empty($self->{result_values}->{last_timestamp}));
    $msg .= sprintf(' [%s]', $self->{result_values}->{description})
        if (is_not_empty($self->{result_values}->{description}));

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Unfixed event log entries: ' },
        { name => 'events', type => COUNTER_TYPE_INSTANCE, prefix_output => "Event '%{sequence_number}' ",
          message_multiple => 'No actionable event', skipped_code => { NO_VALUE() => 1 } }
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

    $self->{maps_counters}->{events} = [
        {
            label => 'event-status',
            type => COUNTER_KIND_TEXT,
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
        'include-status:s'      => { name => 'include_status', default => '^alert$' },
        'exclude-status:s'      => { name => 'exclude_status' },
        'include-error-code:s'  => { name => 'include_error_code' },
        'exclude-error-code:s'  => { name => 'exclude_error_code' },
        'include-event-id:s'    => { name => 'include_event_id' },
        'exclude-event-id:s'    => { name => 'exclude_event_id' },
        'include-object-type:s' => { name => 'include_object_type' },
        'exclude-object-type:s' => { name => 'exclude_object_type' },
        'include-object-name:s' => { name => 'include_object_name' },
        'exclude-object-name:s' => { name => 'exclude_object_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $entries = $options{custom}->request(
        command => 'lseventlog',
        payload => { filtervalue => 'fixed=no' }
    );

    $self->{global} = { alerts => 0, messages => 0 };
    $self->{events} = {};

    foreach my $entry (@$entries) {
        my $event = {
            sequence_number => $entry->{sequence_number} // '',
            status => $entry->{status} // '',
            error_code => $entry->{error_code} // '',
            event_id => $entry->{event_id} // '',
            object_type => $entry->{object_type} // '',
            object_name => $entry->{object_name} // '',
            description => $entry->{description} // '',
            last_timestamp => $entry->{last_timestamp} // ''
        };

        next if (is_excluded($event->{error_code}, $self->{option_results}->{include_error_code}, $self->{option_results}->{exclude_error_code}));
        next if (is_excluded($event->{event_id}, $self->{option_results}->{include_event_id}, $self->{option_results}->{exclude_event_id}));
        next if (is_excluded($event->{object_type}, $self->{option_results}->{include_object_type}, $self->{option_results}->{exclude_object_type}));
        next if (is_excluded($event->{object_name}, $self->{option_results}->{include_object_name}, $self->{option_results}->{exclude_object_name}));

        $self->{global}->{alerts}++ if ($event->{status} =~ /^alert$/i);
        $self->{global}->{messages}++ if ($event->{status} =~ /^message$/i);

        next if (is_excluded($event->{status}, $self->{option_results}->{include_status}, $self->{option_results}->{exclude_status}));

        $self->{events}->{$event->{sequence_number}} = $event;
    }
}

1;

__END__

=head1 MODE

Check unfixed event log entries.

Entries with the C<alert> status are the recommended actions of the system. Entries with the C<message> status are informational: they are counted but not checked by default.

=over 8

=item B<--include-status>

Filter entries by status (can be a regexp, default: C<^alert$>).
Set it to an empty value to also check the entries with the C<message> status.

=item B<--exclude-status>

Exclude entries by status (can be a regexp).

=item B<--include-error-code>

Filter entries by error code (can be a regexp).

=item B<--exclude-error-code>

Exclude entries by error code (can be a regexp).

=item B<--include-event-id>

Filter entries by event id (can be a regexp).

=item B<--exclude-event-id>

Exclude entries by event id (can be a regexp).

=item B<--include-object-type>

Filter entries by object type (can be a regexp).

=item B<--exclude-object-type>

Exclude entries by object type (can be a regexp).

=item B<--include-object-name>

Filter entries by object name (can be a regexp).

=item B<--exclude-object-name>

Exclude entries by object name (can be a regexp).

=item B<--warning-event-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{sequence_number}>, C<%{status}>, C<%{error_code}>, C<%{event_id}>, C<%{object_type}>, C<%{object_name}>, C<%{description}>, C<%{last_timestamp}>

=item B<--critical-event-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /^alert$/i'>).
You can use the following variables: C<%{sequence_number}>, C<%{status}>, C<%{error_code}>, C<%{event_id}>, C<%{object_type}>, C<%{object_name}>, C<%{description}>, C<%{last_timestamp}>

=item B<--unknown-event-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{sequence_number}>, C<%{status}>, C<%{error_code}>, C<%{event_id}>, C<%{object_type}>, C<%{object_name}>, C<%{description}>, C<%{last_timestamp}>

=item B<--warning-alerts>

Threshold.

=item B<--critical-alerts>

Threshold.

=item B<--warning-messages>

Threshold.

=item B<--critical-messages>

Threshold.

=back

=cut
