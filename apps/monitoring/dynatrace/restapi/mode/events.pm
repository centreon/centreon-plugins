#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::dynatrace::restapi::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        "event '%s' [event type: %s] [management zone: %s] [entity: %s]",
        $self->{result_values}->{displayName},
        $self->{result_values}->{eventType},
        $self->{result_values}->{managementZone},
        $self->{result_values}->{entityName}
    );
}

sub prefix_management_zones_output {
    my ($self, %options) = @_;

    return "Management Zone '" . $options{instance_value}->{displayName} . "' ";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{displayName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'management_zone', type => 1, cb_prefix_output => 'prefix_management_zones_output',  skipped_code => { -10 => 1 } },
        { name => 'event', type => 2,
          group => [ { name => 'event' } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'events', nlabel => 'total.events.count', display_ok => 0, set => {
                key_values => [ { name => 'events' } ],
                output_template => 'number of events : %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{management_zone} = [
        { label => 'managementzone-events', nlabel => 'events.count', display_ok => 0, set => {
                key_values => [ { name => 'events' }, { name => 'displayName' } ],
                output_template => 'number of event : %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'displayName' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{event} = [
        { label => 'status', type => 2, critical_default => '%{status} eq "OPEN"', set => {
                key_values => [
                    { name => 'status' },  { name => 'entityName' }, { name => 'entityId' }, 
                    { name => 'displayName' }, { name => 'startTime' }, { name => 'endTime' }, 
                    { name => 'time' }, { name => 'managementZone' }, { name => 'eventType' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-entity:s'          => { name => 'filter_entity' },
        'filter-event-type:s'      => { name => 'filter_event_type' },
        'filter-management-zone:s' => { name => 'filter_management_zone' },
        'relative-time:s'          => { name => 'relative_time', default => '2h' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $event = $options{custom}->get_events(relative_time => $options{options}->{relative_time});
    my ($i, $time) = (1, time());
    my $management_zones;
    my $entities;

    foreach my $item (@{$event->{events}}) {

        $management_zones = join(",", centreon::plugins::misc::uniq(map { "$_->{name}" } @{$item->{managementZones}})),
        $entities = join(",", centreon::plugins::misc::uniq(map { "$_->{name}" } $item->{entityId}));

        if (defined($self->{option_results}->{filter_event_type}) && $self->{option_results}->{filter_event_type} ne '' &&
            $item->{eventType} !~ /$self->{option_results}->{filter_event_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $item->{eventType} . "': no matching filter.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_management_zone}) && $self->{option_results}->{filter_management_zone} ne '' &&
            $management_zones !~ /$self->{option_results}->{filter_management_zone}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $management_zones . "': no matching filter.", debug => 1);
            next;
        }
        
        if (defined($self->{option_results}->{filter_entity}) && $self->{option_results}->{filter_entity} ne '' &&
            $entities !~ /$self->{option_results}->{filter_entity}/) {
            $self->{output}->output_add(long_msg => "skipping '" .  $entities . "': no matching filter.", debug => 1);
            next;
        }

        foreach my $management_zones (@{$item->{managementZones}}) {
            $self->{global}->{events}++;
            $self->{management_zone}->{$management_zones->{name}}->{events}++;
            $self->{management_zone}->{$management_zones->{name}}->{displayName} = $management_zones->{name};
        }
        
        $self->{event}->{global}->{event}->{$i} = {
            displayName    => $item->{title},
            status         => $item->{status},
            eventType      => $item->{eventType},
            managementZone => $management_zones,
            entityName     => $entities,
            entityId       => join(",", centreon::plugins::misc::uniq(map { "$_->{entityId}->{id}" } $item->{entityId})),
            startTime      => $item->{startTime} / 1000,
            endTime        => $item->{endTime} > -1 ? $item->{endTime} / 1000 : -1,
            time           => $time
        };
        $i++;
    }
}

1;

__END__

=head1 MODE

Check events.

=over 8

=item B<--relative-time>

Set request relative time (Default: '2h').
Can use: Xm (minutes), Xh (hours), Xd (days), Xm (months), Xy (year) where 'X' is the amount of time.

=item B<--filter-event-type>

Filter event by type (can be a regexp).

=item B<--filter-management>

Filter events by management zone (can be a regexp).

=item B<--filter-entity>

Filter events by entity (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can use special variables like: %{status}, %{managementZone}, %{entityName}, %{entityId}, %{eventType}, %{startTime}, %{endTime}, %{time}

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{managementZone}, %{entityName}, %{entityId}, %{eventType}, %{startTime}, %{endTime}, %{time}

=item B<--critical-status>

Set critical threshold for status.
Can use special variables like: %{status}, %{managementZone}, %{entityName}, %{entityId}, %{eventType}, %{startTime}, %{endTime}, %{time}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'events', 'managementzone-events'.

=back

=cut
