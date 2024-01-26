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

package cloud::azure::datafactory::factories::mode::factoryusage;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'factory_percentage_usage' => {
            'output' => 'Factory usage',
            'label'  => 'factory-percentage-usage',
            'nlabel' => 'azdatafactory.factoryusage.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'resource_percentage_usage' => {
            'output' => 'Resource usage',
            'label'  => 'resource-percentage-usage',
            'nlabel' => 'azdatafactory.factoryusage.resource.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'FactorySizeInGbUnits' => {
            'output' => 'Factory size',
            'label'  => 'factory-size',
            'nlabel' => 'azdatafactory.factoryusage.size.bytes',
            'unit'   => 'B',
            'min'    => '0',
            'change_bytes' => '2'
        },
        'ResourceCount' => {
            'output' => 'Resource count',
            'label'  => 'resource-count',
            'nlabel' => 'azdatafactory.factoryusage.resource.count',
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
        'api-version:s'    => { name => 'api_version', default => '2018-01-01'},
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group option or --resource <id>.");
        $self->{output}->option_exit();
    }

    $self->{api_version} = (defined($self->{option_results}->{api_version}) && $self->{option_results}->{api_version} ne "") ? $self->{option_results}->{api_version} : "2018-01-01";

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.DataFactory\/factories\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'factories';
    $self->{az_resource_namespace} = 'Microsoft.DataFactory';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";
    $self->{az_aggregations} = ['Maximum'];

    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric ('FactorySizeInGbUnits', 'MaxAllowedFactorySizeInGbUnits', 'ResourceCount', 'MaxAllowedResourceCount') {
        push @{$self->{az_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    my $raw_results;

    ($metric_results{$self->{az_resource}}, $raw_results) = $options{custom}->azure_get_metrics(
        aggregations       => $self->{az_aggregations},
        dimension          => $self->{az_dimension},
        interval           => $self->{az_interval},
        metrics            => $self->{az_metrics},
        resource           => $self->{az_resource},
        resource_group     => $self->{az_resource_group},
        resource_namespace => $self->{az_resource_namespace},
        resource_type      => $self->{az_resource_type},
        timeframe          => $self->{az_timeframe}
    );

    my $datas = 0;
    $self->{metrics}->{$self->{az_resource}}->{display} = $self->{az_resource};
    foreach my $aggregation (@{$self->{az_aggregations}}) {
        next if (!defined($aggregation) && !defined($self->{option_results}->{zeroed}));
        $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{display} = lc($aggregation);
        $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{timeframe} = $self->{az_timeframe};
        foreach my $metric (@{$self->{az_metrics}}) {
            my $metric_name = lc($metric);
            $metric_name =~ s/ /_/g;
            next if (!defined($metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{$metric} =
                defined($metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)}) ?
                $metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)} : 0;
                $datas = 1;
        }
        # Compute percentages from metrics
        next if (!defined($self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}));
        my $metricsAggregation = $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)};
        if (defined($metricsAggregation->{FactorySizeInGbUnits})) {
            $metricsAggregation->{FactorySizeInGbUnits} = $metricsAggregation->{FactorySizeInGbUnits} * 1024 * 1024 * 1024;
        }
        if (defined($metricsAggregation->{MaxAllowedFactorySizeInGbUnits}) || defined($self->{option_results}->{zeroed})) {
            $metricsAggregation->{MaxAllowedFactorySizeInGbUnits} = $metricsAggregation->{MaxAllowedFactorySizeInGbUnits} * 1024 * 1024 * 1024;
            my $max_allowed_factory_size_in_gb_units = $metricsAggregation->{MaxAllowedFactorySizeInGbUnits};
            if ($max_allowed_factory_size_in_gb_units > 0) {
                $metricsAggregation->{factory_percentage_usage} = ($metricsAggregation->{FactorySizeInGbUnits} / $max_allowed_factory_size_in_gb_units) * 100;
            } else {
                $metricsAggregation->{factory_percentage_usage} = 0;
            }
            $datas = 1;
        }
        if (defined($metricsAggregation->{MaxAllowedResourceCount}) || defined($self->{option_results}->{zeroed})) {
            my $max_allowed_resource_count = $metricsAggregation->{MaxAllowedResourceCount};
            if ($max_allowed_resource_count > 0) {
                $metricsAggregation->{resource_percentage_usage} = ($metricsAggregation->{ResourceCount} / $max_allowed_resource_count) * 100;
            } else {
                $metricsAggregation->{resource_percentage_usage} = 0;
            }
            $datas = 1;
        }
    }

    if (!$datas) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Azure Data Factory for factory size and resource usage.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::datafactory::factory::plugin --mode=factoryusage --custommode=api
--resource=<factory_id> --resource-group=<resourcegroup_id>

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::datafactory::factory::plugin --mode=factoryusage --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.DataFactory/factories/<factory_id>'


=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--warning-$metric$>

Warning thresholds ($metric$ can be: 'factory-percentage-usage', 'resource-percentage-usage', 'factory-size', 'resource-count').

=item B<--critical-$metric$>

Critical thresholds ($metric$ can be: 'factory-percentage-usage', 'resource-percentage-usage', 'factory-size', 'resource-count').

=back

=cut
