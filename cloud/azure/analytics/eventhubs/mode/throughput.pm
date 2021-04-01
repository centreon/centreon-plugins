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

package cloud::azure::analytics::eventhubs::mode::throughput;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'capturedbytes' => {
            'output' => 'Captured Bytes',
            'label'  => 'captured-bytes',
            'nlabel' => 'eventhubs.throughput.captured.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'IncomingBytes' => {
            'output' => 'Incoming Bytes',
            'label'  => 'incoming-bytes',
            'nlabel' => 'eventhubs.throughput.incoming.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'OutgoingBytes' => {
            'output' => 'Outgoing Bytes',
            'label'  => 'outgoing-bytes',
            'nlabel' => 'eventhubs.throughput.outgoing.bytes',
            'unit'   => 'B',
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
        'resource-type:s'  => { name => 'resource_type' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group & --resource-type options or --resource <id>.');
        $self->{output}->option_exit();
    }
    my $resource = $self->{option_results}->{resource};
    if ($resource !~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.EventHub\/(.*)\/(.*)$/ && (!defined($self->{option_results}->{resource_group}) ||
        $self->{option_results}->{resource_group} eq '' || !defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '')) {
            $self->{output}->add_option_msg(short_msg => 'Invalid or missing --resource-group or --resource-type option');
            $self->{output}->option_exit();
    }
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    my $resource_type = defined($self->{option_results}->{resource_type}) ? $self->{option_results}->{resource_type} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.EventHub\/(.*)\/(.*)$/) {
        $resource_group = $1;
        $resource_type = $2;
        $resource = $3;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = $resource_type;
    $self->{az_resource_namespace} = 'Microsoft.EventHub';
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

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Event Hub throughput statistics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::analytics::eventhubs::plugin --mode=throughput --custommode=api
--resource=<eventhub_id> --resource-group=<resourcegroup_id> --resource-type=<resource_type> --aggregation='total'
--warning-incoming-bytes='800000000' --critical-incoming-bytes='900000000'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::analytics::eventhubs::plugin --mode=throughput --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.EventHub/<resource_type>/<eventhub_id>'
--aggregation='total' --warning-incoming-bytes='800000000' --critical-incoming-bytes='900000000'

Default aggregation: 'total' / 'average', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--resource-type>

Set resource group (Required if resource's name is used).
Can be: 'namespaces', 'clusters'.

=item B<--warning-*>

Warning threshold where '*' can be:
'outgoing-bytes', 'captured-bytes', 'incoming-bytes'.

=item B<--critical-*>

Critical threshold where '*' can be:
'outgoing-bytes', 'captured-bytes', 'incoming-bytes'.

=back

=cut
