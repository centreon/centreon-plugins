#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::azure::integration::eventgrid::mode::events;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'deadletteredcount' => {
            'output' => 'Dead Lettered Events',
            'label'  => 'deadlettered-events',
            'nlabel' => 'eventgrid.deadlettered.events.count',
            'unit'   => '',
            'min'    => '0'
        },
        'droppedeventcount' => {
            'output' => 'Dropped Events',
            'label'  => 'dropped-events',
            'nlabel' => 'eventgrid.dropped.events.count',
            'unit'   => '',
            'min'    => '0'
        },
        'matchedeventcount' => {
            'output' => 'Matched Events',
            'label'  => 'matched-events',
            'nlabel' => 'eventgrid.matched.events.count',
            'unit'   => '',
            'min'    => '0'
        },
        'unmatchedeventcount' => {
            'output' => 'Unmatched Events',
            'label'  => 'unmatched-events',
            'nlabel' => 'eventgrid.unmatched.events.count',
            'unit'   => '',
            'min'    => '0'
        }
    };

    return $metrics_mapping;
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-metric:s'  => { name => 'filter_metric' },
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' },
        'resource-type:s'  => { name => 'resource_type', default => 'topics' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{resource_type}) || 
        $self->{option_results}->{resource_type} !~ /topics|systemTopics|partnerTopic|partnerNamespaces|extensionTopics|eventSubscriptions|domains/) {
        $self->{output}->add_option_msg(short_msg => 'Please specify an existing Azure Event Grid resource type');
        $self->{output}->option_exit();
    }

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    my $resource_type = $self->{option_results}->{resource_type};
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.EventGrid\/(.*)\/(.*)$/) {
        $resource_group = $1;
        $resource_type = $2;
        $resource = $3;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = $resource_type;
    $self->{az_resource_namespace} = 'Microsoft.EventGrid';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Total'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    my $type;
    if ($resource_type =~ /topics|systemTopics|partnerTopic|partnerNamespaces/) {
        $type = 'topics';

    } elsif ($resource_type eq 'extensionTopics') {
        $type = 'extensionTopics';
    
    } else {
        $type = 'eventSubscriptions';
    }

    my $resource_mapping = {
        'topics' => [ 'deadletteredcount', 'droppedeventcount', 'matchedeventcount', 'unmatchedeventcount' ],
        'extensionTopics' => [ 'unmatchedeventcount' ],
        'eventSubscriptions' => [ 'deadletteredcount', 'droppedeventcount', 'matchedeventcount' ]
    };

    my $metrics_mapping_transformed;
    foreach my $metric_type (@{$resource_mapping->{$type}}) {
        $metrics_mapping_transformed->{$metric_type} = $self->{metrics_mapping}->{$metric_type};
    }

    foreach my $metric (keys %{$metrics_mapping_transformed}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Event Grid events.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::integration::eventgrid::plugin --mode=events --custommode=api
--resource=<topic_rsc_id> --resource-group=<resourcegroup_id> --aggregation='average'
--warning-matched-events='20' --critical-matched-events='50'

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::integration::eventgrid::plugin --mode=events --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.EventGrid/<EventGridType>/<topic_rsc_id>'
--aggregation='average' --warning-matched-events='20' --critical-matched-events='50'

Default aggregation: 'average' / 'total', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--resource-type>

Set resource type (default: 'topics'). Can be 'topics', 
'systemTopics', 'partnerTopics', 'partnerNamespaces',
'extensionTopics', 'extensionTopics', 'domains').

=item B<--warning-*>

Warning threshold where '*' can be:
'matched-events', 'deadlettered-events', 'unmatched-events', 
'dropped-events'.

=item B<--critical-*>

Critical threshold where '*' can be:
'matched-events', 'deadlettered-events', 'unmatched-events', 
'dropped-events'.

=back

=cut
