#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::aws::health::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Events ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'events.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'open', nlabel => 'events.open.count', set => {
                key_values => [ { name => 'open' } ],
                output_template => 'open: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'closed', nlabel => 'events.closed.count', set => {
                key_values => [ { name => 'closed' } ],
                output_template => 'closed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'upcoming', nlabel => 'events.upcoming.count', set => {
                key_values => [ { name => 'upcoming' } ],
                output_template => 'upcoming: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-service:s@'         => { name => 'filter_service' },
        'filter-region:s@'          => { name => 'filter_region' },
        'filter-entity-value:s@'    => { name => 'filter_entity_value' },
        'filter-event-status:s@'    => { name => 'filter_event_status' },
        'filter-event-category:s@'  => { name => 'filter_event_category' },
        'display-affected-entities' => { name => 'display_affected_entities' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{filter_options} = {};
    foreach (('service', 'region', 'entity_value', 'event_status', 'event_category')) {
        $self->{filter_options}->{'filter_' . $_} = undef;
        if (defined($self->{option_results}->{'filter_' . $_})) {
            foreach my $option (@{$self->{option_results}->{'filter_' . $_}}) {
                next if ($option eq '');

                $self->{filter_options}->{'filter_' . $_} = [] if (!defined($self->{filter_options}->{'filter_' . $_}));
                push @{$self->{filter_options}->{'filter_' . $_}}, $option;
            }
        }
     }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->health_describe_events(
        %{$self->{filter_options}}
    );

    $self->{global} = { total => 0, open => 0, closed => 0, upcoming => 0 };
    my $events = {};
    foreach my $entry (@$results) {
        $self->{global}->{ lc($entry->{statusCode}) }++;
        $self->{global}->{total}++;

        $events->{ $entry->{arn} } = $entry;
    }

    my $affected_entities;
    my @event_arns = sort { $events->{$b}->{startTime} cmp $events->{$a}->{startTime} } keys %$events;
    if (scalar(@event_arns) > 0 && defined($self->{option_results}->{display_affected_entities})) {
        $affected_entities = $options{custom}->health_describe_affected_entities(filter_event_arns => [@event_arns]);
    }

    foreach (@event_arns) {
        my $entity = '';
        if (defined($affected_entities)) {
            $entity = '[affected entity: -]';
            foreach my $affected (@$affected_entities) {
                if ($events->{$_}->{arn} eq $affected->{eventArn}) {
                    $entity = '[affected entity: ' . $affected->{entityValue} . ']';
                    last;
                }
            }
        }

        $self->{output}->output_add(long_msg => 
            sprintf(
                '[service: %s][region: %s][status: %s][type: %s][start: %s]%s',
                $events->{$_}->{service},
                $events->{$_}->{region},
                $events->{$_}->{statusCode},
                $events->{$_}->{eventTypeCode},
                scalar(localtime($events->{$_}->{startTime})),
                $entity
            )
        );
    }
}

1;

__END__

=head1 MODE

Check health events.

=over 8

=item B<--filter-service>

Filter result by service (multiple option).
Example: --filter-service=EC2 --filter-service=RDS

=item B<--filter-region>

Filter result by region (multiple option).
Example: --filter-region=ap-southeast-1 --filter-region=eu-west-1

=item B<--filter-entity-value>

Filter result by entity value (multiple option).
Example: --filter-entity-value=i-34ab692e --filter-entity-value=vol-426ab23e

=item B<--filter-event-status>

Filter result by event status (multiple option).
Example: --filter-event-status=open --filter-event-status=closed

=item B<--filter-event-category>

Filter result by event category (multiple option).
Example: --filter-event-category=issue

=item B<--display-affected-entities>

Display affected entities by the event.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'open', 'closed', 'upcoming'.

=back

=cut
