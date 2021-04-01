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

package cloud::ibm::softlayer::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_event_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Status is '%s', Impacted items: %d, Start date: %s, End date: %s",
        $self->{result_values}->{status},
        $self->{result_values}->{items},
        ($self->{result_values}->{start_date} ne "-") ? $self->{result_values}->{start_date} . ' (' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since_start}) . ' ago)' : '-',
        ($self->{result_values}->{end_date} ne "-") ? $self->{result_values}->{end_date} . ' (' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since_end}) . ' ago)' : '-'
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Number of events ";
}

sub prefix_events_output {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{id} . "' with subject '" . $options{instance_value}->{subject} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'events', type => 1, cb_prefix_output => 'prefix_events_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'events.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active : %d',
                perfdatas => [
                    { label => 'active_events', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'completed', nlabel => 'events.completed.count', set => {
                key_values => [ { name => 'completed' } ],
                output_template => 'Completed : %d',
                perfdatas => [
                    { label => 'completed_events', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'published',nlabel => 'events.published.count', set => {
                key_values => [ { name => 'published' } ],
                output_template => 'Published : %d',
                perfdatas => [
                    { label => 'published_events', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{events} = [
        { label => 'event', type => 2, critical_default => '%{status} =~ /Active/ && %{items} > 0', set => {
                key_values => [ { name => 'id' }, { name => 'subject' }, { name => 'status' }, { name => 'items' },
                    { name => 'start_date' }, { name => 'since_start' }, { name => 'end_date' }, { name => 'since_end' } ],
                closure_custom_output => $self->can('custom_event_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-status:s' => { name => 'filter_status', default => 'Active' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $current_time = time();
    
    my %status_hash;
    my $events = $options{custom}->get_endpoint(service => 'SoftLayer_Notification_Occurrence_Event', method => 'getAllObjects', extra_content => '');
    foreach my $event (@{$events->{'ns1:getAllObjectsResponse'}->{'getAllObjectsReturn'}->{'item'}}) {
        my $status;
        $status = $event->{statusCode}->{name}->{content} if (defined($event->{statusCode}->{name}->{content}));
        $status_hash{'#' . $event->{statusCode}->{id}} = $event->{statusCode}->{name}->{content} if (defined($event->{statusCode}->{name}->{content}));
        $status = $status_hash{$event->{statusCode}->{href}} if (!defined($event->{statusCode}->{name}->{content}) && defined($event->{statusCode}->{href}));

        next if (defined($self->{option_results}->{filter_status}) && $status !~ /$self->{option_results}->{filter_status}/);

        my $extra_content = '<slapi:SoftLayer_Notification_Occurrence_EventInitParameters>
  <id>' . $event->{id}->{content} . '</id>
</slapi:SoftLayer_Notification_Occurrence_EventInitParameters>';

        my $ressources = $options{custom}->get_endpoint(service => 'SoftLayer_Notification_Occurrence_Event', method => 'getImpactedResources', extra_content => $extra_content);
        my $items = 0;
        if (defined($ressources->{'ns1:getImpactedResourcesResponse'}->{'getImpactedResourcesReturn'}->{'item'})) {
            $items = 1;
            $items = scalar(@{$ressources->{'ns1:getImpactedResourcesResponse'}->{'getImpactedResourcesReturn'}->{'item'}}) if (ref($ressources->{'ns1:getImpactedResourcesResponse'}->{'getImpactedResourcesReturn'}->{'item'}) eq 'ARRAY');
        }

        my $start_epoch = '';
        my $end_epoch = '';
        if (defined($event->{startDate}->{content}) && 
            $event->{startDate}->{content} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(.*)$/) { # 2018-10-18T15:36:54+00:00
            my $dt = DateTime->new(
                year => $1,
                month => $2,
                day => $3,
                hour => $4,
                minute => $5,
                second => $6,
                time_zone => $7
            );
            $start_epoch = $dt->epoch;
        }
        if (defined($event->{endDate}->{content}) && 
            $event->{endDate}->{content} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(.*)$/) { # 2018-10-18T15:36:54+00:00
            my $dt = DateTime->new(
                year => $1,
                month => $2,
                day => $3,
                hour => $4,
                minute => $5,
                second => $6,
                time_zone => $7
            );
            $end_epoch = $dt->epoch;
        }
        
        $self->{events}->{$event->{id}->{content}} = {
            id => $event->{id}->{content},
            subject => $event->{subject}->{content},
            status => $status,
            items => $items,
            start_date => (defined($event->{startDate}->{content})) ? $event->{startDate}->{content} : "-",
            since_start => ($start_epoch ne '') ? $current_time - $start_epoch : "-",
            end_date => (defined($event->{endDate}->{content})) ? $event->{endDate}->{content} : "-",
            since_end => ($end_epoch ne '') ? $current_time - $end_epoch : "-",
        };

        $self->{global}->{lc($status)}++;
    } 
}

1;

__END__

=head1 MODE

Check events status and number of impacted ressources

=over 8

=item B<--filter-status>

Filter events status (Default: 'Active')

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{id}, %{subject}, %{status}, %{items}, 
%{start_date}, %{since_start}, %{end_date}, %{since_end}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /Active/ && %{items} > 0').
Can used special variables like: %{id}, %{subject}, %{status}, %{items}, 
%{start_date}, %{since_start}, %{end_date}, %{since_end}.

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'completed', 'published'.

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'completed', 'published'.

=back

=cut
