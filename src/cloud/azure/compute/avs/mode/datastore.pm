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

package cloud::azure::compute::avs::mode::datastore;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'DiskUsedPercentage' => {
            'output' => 'Disk used',
            'label'  => 'datastore-disk-used-percentage',
            'nlabel' => 'avs.datastore.disk.used.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'DiskUsedLatest' => {
            'output' => 'Disk used',
            'label'  => 'datastore-disk-used',
            'nlabel' => 'avs.datastore.disk.used.bytes',
            'unit'   => 'B',
            'min'    => '0',
            'max'    => ''
        },
        'DiskCapacityLatest' => {
            'output' => 'Disk total capacity',
            'label'  => 'datastore-disk-capacity',
            'nlabel' => 'avs.datastore.disk.capacity.bytes',
            'unit'   => 'B',
            'min'    => '0',
            'max'    => ''
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'api-version:s'    => { name => 'api_version', default => '2018-01-01' },
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

    $self->{api_version} = (defined($self->{option_results}->{api_version}) && $self->{option_results}->{api_version} ne '') ? $self->{option_results}->{api_version} : '2018-01-01';

    my $resource       = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.AVS\/privateClouds\/(.*)$/) {
        $resource_group = $1;
        $resource       = $2;
    }

    $self->{az_resource}           = $resource;
    $self->{az_resource_group}     = $resource_group;
    $self->{az_resource_type}      = 'privateClouds';
    $self->{az_resource_namespace} = 'Microsoft.AVS';
    $self->{az_timeframe}          = defined($self->{option_results}->{timeframe})  ? $self->{option_results}->{timeframe}  : 1800;
    $self->{az_interval}           = defined($self->{option_results}->{interval})   ? $self->{option_results}->{interval}   : 'PT30M';
    $self->{az_aggregations}       = ['Average'];

    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            push @{$self->{az_aggregations}}, ucfirst(lc($stat)) if $stat ne '';
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

Check Azure VMware Solution (AVS) private cloud datastore disk metrics.

Metric names in the Azure Monitor API:
- C<DiskUsedPercentage>: percent of available disk used in the datastore (new)
- C<DiskUsedLatest>: total disk used in the datastore (new)
- C<DiskCapacityLatest>: total disk capacity in the datastore (new)

Dimension: C<dsname>

Note: datastore metrics have a minimum granularity of PT30M. Default timeframe
is set to 1800 seconds (30 minutes) and interval to PT30M accordingly.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::compute::avs::plugin \
  --custommode=api --mode=datastore \
  --subscription=XXXX --tenant=XXXX --client-id=XXXX --client-secret=XXXX \
  --resource=my-private-cloud --resource-group=my-rg \
  --warning-datastore-disk-used-percentage=70 \
  --critical-datastore-disk-used-percentage=85 --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource name is used).

=item B<--filter-metric>

Filter metrics (can be: C<DiskUsedPercentage>, C<DiskUsedLatest>,
C<DiskCapacityLatest>) (can be a regexp).

=item B<--warning-datastore-disk-used-percentage>

Warning threshold for datastore disk usage percentage.

=item B<--critical-datastore-disk-used-percentage>

Critical threshold for datastore disk usage percentage.

=item B<--warning-datastore-disk-used>

Warning threshold for disk used (bytes).

=item B<--critical-datastore-disk-used>

Critical threshold for disk used (bytes).

=item B<--warning-datastore-disk-capacity>

Warning threshold for total disk capacity (bytes).

=item B<--critical-datastore-disk-capacity>

Critical threshold for total disk capacity (bytes).

=back

=cut
