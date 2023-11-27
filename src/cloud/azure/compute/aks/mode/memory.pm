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

package cloud::azure::compute::aks::mode::memory;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'node_memory_rss_bytes' => { 
            'output' => 'memory RSS Usage',
            'label'  => 'memory-rss-usage',
            'nlabel' => 'aks.node.memory.rss.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'node_memory_rss_percentage' => {
            'output' => 'Memory RSS Percent',
            'label'  => 'memory-rss-percent',
            'nlabel' => 'aks.node.memory.rss.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'node_memory_working_set_bytes' => { 
            'output' => 'memory Usage',
            'label'  => 'memory-usage',
            'nlabel' => 'aks.node.memory.working.set.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'node_memory_working_set_percentage' => {
            'output' => 'Memory Percent',
            'label'  => 'memory-percent',
            'nlabel' => 'aks.node.memory.working.set.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
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
    my $resource_type = $self->{option_results}->{resource_type};
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.ContainerService\/managedClusters\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'managedClusters';
    $self->{az_resource_namespace} = 'Microsoft.ContainerService';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Average'];
 
    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Memory usage on Azure Kubernetes Cluster. 

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=memory --custommode=api
--resource=<cluster_id> --resource-group=<resourcegroup_id> --warning-memory-percent='90' --critical-memory-percent='95'

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=storage --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.ContainerService/managedClusters/<cluster_id>' 
--warning-memory-percent='90' --critical-memory-percent='95'

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-memory-usage>

Warning threshold in Bytes.

=item B<--critical-memory-usage>

Critical threshold in Bytes.

=item B<--warning-memory-percent>

Warning threshold in percent.

=item B<--critical-memory-percent>

Critical threshold in percent.

=item B<--warning-rss-memory-usage>

Warning threshold in Bytes.

=item B<--critical-rss-memory-usage>

Critical threshold in Bytes.

=item B<--warning-rss-memory-percent>

Warning threshold in percent.

=item B<--critical-rss-memory-percent>

Critical threshold in percent.

=back

=cut
