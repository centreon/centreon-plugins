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

package cloud::azure::integration::servicebus::mode::messages;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'activemessages' => {
            'output' => 'Count of active messages in a Queue/Topic',
            'label'  => 'active-messages',
            'nlabel' => 'servicebus.namespace.messages.active.count',
            'unit'   => '',
            'min'    => '0'
        },
        'deadletteredmessages' => {
            'output' => 'Count of dead-lettered messages in a Queue/Topic',
            'label'  => 'deadlettered-messages',
            'nlabel' => 'servicebus.namespace.messages.deadlettered.count',
            'unit'   => '',
            'min'    => '0'
        },
        'incomingmessages' => {
            'output' => 'Incoming Messages',
            'label'  => 'incoming-messages',
            'nlabel' => 'servicebus.namespace.messages.incoming.count',
            'unit'   => '',
            'min'    => '0'
        },
        'messages' => {
            'output' => 'Total messages',
            'label'  => 'total-messages',
            'nlabel' => 'servicebus.namespace.messages.total.count',
            'unit'   => '',
            'min'    => '0'
        },
        'outgoingmessages' => {
            'output' => 'Outgoing Messages',
            'label'  => 'outgoing-messages',
            'nlabel' => 'servicebus.namespace.messages.outgoing.count',
            'unit'   => '',
            'min'    => '0'
        },
        'scheduledmessages' => {
            'output' => 'Count of scheduled messages in a Queue/Topic.',
            'label'  => 'scheduled-messages',
            'nlabel' => 'servicebus.namespace.messages.scheduled.count',
            'unit'   => '',
            'min'    => '0'
        },
        
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
        'resource-group:s' => { name => 'resource_group' }
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
    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.ServiceBus\/namespaces\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'namespaces';
    $self->{az_resource_namespace} = 'Microsoft.ServiceBus';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Service Bus messages metrics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::integration::servicebus::plugin --mode=messages --custommode=api
--resource=<busnamespace_id> --resource-group=<resourcegroup_id> --aggregation='average'
--warning-servicebus-active-messages='1000' --critical-servicebus-active-messages='2000'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::integration::servicebus::plugin --mode=messages --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.ServiceBus/namespaces/<busnamespace_id>'
--aggregation='average' --warning-servicebus-active-messages='1000' --critical-servicebus-active-messages='2000'

Default aggregation: 'average' / 'total', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be:
'active-messages', 'deadlettered-messages', 'total-messages', 'incoming-messages', 'outgoing-messages', 'scheduled-messages'.

=item B<--critical-*>

Critical threshold where '*' can be:
'active-messages', 'deadlettered-messages', 'total-messages', 'incoming-messages', 'outgoing-messages', 'scheduled-messages'.

=back

=cut
