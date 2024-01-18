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

package cloud::azure::compute::aks::mode::allocatableresources;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
	    'kube_node_status_allocatable_cpu_cores' => {
            'output' => 'Allocatable CPU Cores',
            'label'  => 'allocatable-cpu-cores',
            'nlabel' => 'aks.node.allocatable.cpu.cores',
            'unit'   => '',
            'min'    => '0',
        },
        'kube_node_status_allocatable_memory_bytes' => {
            'output' => 'Allocatable Memory Bytes',
            'label'  => 'allocatable-memory-bytes',
            'nlabel' => 'aks.node.allocatable.memory.bytes',
            'unit'   => 'B',
            'min'    => '0',
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

Check remaining Azure Kubernetes Cluster Allocatable CPU Cores and Memory in Bytes.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=allocatable-resources --custommode=api
--resource=<cluster_id> --resource-group=<resourcegroup_id> --warning-allocatable-memory-bytes=16GB: --critical-allocatable-memory-bytes=8GB:

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::compute::aks::plugin --mode=allocatable-resources --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.ContainerService/managedClusters/<cluster_id>' 
--warning-allocatable-memory-bytes=16GB: --critical-allocatable-memory-bytes=8GB:

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-allocatable-memory-bytes>

Set warning threshold for remaining allocatable memory in bytes.
It is a range, set 16GB: to get WARNING if there are less than 16GB allocatable left.

=item B<--critical-allocatable-memory-bytes>

Set critical threshold for remaining allocatable memory in bytes.
It is a range, set 8GB: to get CRITICAL if there are less than 8GB allocatable left.

=item B<--warning-allocatable-cpu-cores>

Set warning threshold for number of remaining allocatable CPU Cores.
It is a range, set 10: to get WARNING if there are less than 10 CPU cores allocatable remaining.

=item B<--critical-allocatable-cpu-cores>

Set critical threshold for number of remaining allocatable CPU Cores.
It is a range, set 5: to get CRITICAL if there are less than 5 CPU cores allocatable remaining.

=back

=cut
