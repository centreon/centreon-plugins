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

package cloud::azure::datafactory::factory::mode::factoryusage;

# use base qw(centreon::plugins::templates::counter);
use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'factory_size_usage' => {
            'output' => 'Factory usage',
            'label'  => 'factory-size-usage',
            'nlabel' => 'azdatafactory.factoryusage.size.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        },
        'resource_usage' => {
            'output' => 'Resource usage',
            'label'  => 'resource-usage',
            'nlabel' => 'azdatafactory.factoryusage.resource.percentage',
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

    foreach my $metric (@{$self->{az_metrics}}) {
        my $metric_name = lc($metric);
        $metric_name =~ s/ /_/g;
        foreach my $aggregation (@{$self->{az_aggregations}}) {
            next if (!defined($metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)}) && !defined($aggregation) && !defined($self->{option_results}->{zeroed}));
            next if (defined($self->{skip_aggregation}->{$metric}->{lc($aggregation)}) && $self->{skip_aggregation}->{$metric}->{lc($aggregation)} == 0);
            $self->{metrics}->{$self->{az_resource}}->{display} = $self->{az_resource};
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{display} = lc($aggregation);
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{timeframe} = $self->{az_timeframe};
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{$metric} =
                defined($metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)}) ?
                $metric_results{$self->{az_resource}}->{$metric_name}->{lc($aggregation)} : 0;
        }
    }

    foreach my $aggregation (@{$self->{az_aggregations}}) {
        my $factory_size_usage = 0;
        if (defined($self->{metrics}->{$self->{az_resource}}->{statistics}->{lc('MaxAllowedFactorySizeInGbUnits')}) && defined($self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('MaxAllowedFactorySizeInGbUnits')})) {
            my $max_allowed_factory_size_in_gb_units = $self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('MaxAllowedFactorySizeInGbUnits')};
            if ($max_allowed_factory_size_in_gb_units > 0) {
                $factory_size_usage = ($self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('FactorySizeInGbUnits')} / $max_allowed_factory_size_in_gb_units) * 100;
            }
        }
        $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{factory_size_usage} = $factory_size_usage;

        my $resource_usage = 0;
        if (defined($self->{metrics}->{$self->{az_resource}}->{statistics}->{lc('MaxAllowedResourceCount')}) && defined($self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('MaxAllowedResourceCount')})) {
            my $max_allowed_resource_count = $self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('MaxAllowedResourceCount')};
            if ($max_allowed_resource_count > 0) {
                $resource_usage = ($self->{metrics}->{$self->{az_resource}}->{statistics}->{$aggregation}->{lc('ResourceCount')} / $max_allowed_resource_count) * 100;
            }
        }
        $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{resource_usage} = $resource_usage;
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Azure Data Factory for factory size and resource usage.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::datafactory::usine:::plugin --mode=factoryusage --custommode=api --subscription='test' --tenant='test' --client-id='test' --client-secret='test' --resource=test

perl centreon_plugins.pl --plugin=cloud::azure::datafactory::factory::plugin --mode=factoryusage --custommode=api
--resource=<factory_id> --resource-group=<resourcegroup_id>

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::datafactory::factory::plugin --mode=factoryusage --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.DataFactory/factories/<factory_id>'


=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-$metric$>

Thresholds warning ($metric$ can be: 'factory-size-usage', 'resource-usage').

=item B<--critical-$metric$>

Thresholds critical ($metric$ can be: 'factory-size-usage', 'resource-usage').

=back

=cut
