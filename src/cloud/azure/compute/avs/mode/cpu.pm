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

package cloud::azure::compute::avs::mode::cpu;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'CpuUsageAverage' => {
            'output' => 'CPU usage',
            'label'  => 'cpu-usage',
            'nlabel' => 'avs.cluster.cpu.usage.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'EffectiveCpuAverage' => {
            'output' => 'Effective CPU',
            'label'  => 'cpu-effective',
            'nlabel' => 'avs.cluster.cpu.effective.percentage',
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
        'api-version:s'    => { name => 'api_version', default => '2024-02-01' },
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
    $self->{az_timeframe}          = defined($self->{option_results}->{timeframe})  ? $self->{option_results}->{timeframe}  : 900;
    $self->{az_interval}           = defined($self->{option_results}->{interval})   ? $self->{option_results}->{interval}   : 'PT5M';
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

Check Azure VMware Solution (AVS) private cloud cluster CPU metrics.

Metric names in the Azure Monitor API:
- C<CpuUsageAverage>: percentage of used CPU resources in the cluster (new)
- C<EffectiveCpuAverage>: percentage of effective CPU resources in the cluster (legacy)

Dimension: C<clustername>

Example:

perl centreon_plugins.pl --plugin=cloud::azure::compute::avs::plugin \
  --custommode=api --mode=cpu \
  --subscription=XXXX --tenant=XXXX --client-id=XXXX --client-secret=XXXX \
  --resource=my-private-cloud --resource-group=my-rg \
  --warning-cpu-usage=80 --critical-cpu-usage=90 --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource name is used).

=item B<--filter-metric>

Filter metrics (can be: C<CpuUsageAverage>, C<EffectiveCpuAverage>) (can be a regexp).

=item B<--warning-cpu-usage>

Warning threshold for cluster CPU usage percentage.

=item B<--critical-cpu-usage>

Critical threshold for cluster CPU usage percentage.

=item B<--warning-cpu-effective>

Warning threshold for effective CPU percentage.

=item B<--critical-cpu-effective>

Critical threshold for effective CPU percentage.

=back

=cut
