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

package cloud::azure::management::monitor::mode::getmetrics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Data::Dumper;

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{perf_label},
        value => $self->{result_values}->{value},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric'),
    );

}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value},
        threshold => [ { label => 'critical-metric', exit_litteral => 'critical' },
                       { label => 'warning-metric', exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg = "Metric '" . $self->{result_values}->{name}  . "' of resource '" . $self->{result_values}->{display} .
        "' and aggregation '" . $self->{result_values}->{aggregation} . "' value is " . $self->{result_values}->{value};
    return $msg;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{label} = $options{new_datas}->{$self->{instance} . '_label'};
    $self->{result_values}->{aggregation} = $options{new_datas}->{$self->{instance} . '_aggregation'};
    $self->{result_values}->{perf_label} = $options{new_datas}->{$self->{instance} . '_perf_label'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 1, message_multiple => 'All metrics are ok' },
    ];

    $self->{maps_counters}->{metrics} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'name' }, { name => 'label' }, { name => 'aggregation' },
                    { name => 'perf_label' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "resource:s"            => { name => 'resource' },
        "resource-group:s"      => { name => 'resource_group' },
        "resource-type:s"       => { name => 'resource_type' },
        "resource-namespace:s"  => { name => 'resource_namespace' },
        "metric:s@"             => { name => 'metric' },
        "filter-dimension:s"    => { name => 'filter_dimension'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group, --resource-type and --resource-namespace options or --resource <id>.");
        $self->{output}->option_exit();
    }

    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group};
    $self->{az_resource_type} = $self->{option_results}->{resource_type};
    $self->{az_resource_namespace} = $self->{option_results}->{resource_namespace};

    if ($self->{az_resource} =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/(.*)\/(.*)\/(.*)$/) {
        $self->{az_resource_group} = $1;
        $self->{az_resource_namespace} = $2;
        $self->{az_resource_type} = $3;
        $self->{az_resource} = $4;
    }

    $self->{az_metrics} = [];
    if (defined($self->{option_results}->{metric})) {
        $self->{az_metrics} = $self->{option_results}->{metric};
    }
    if (scalar(@{$self->{az_metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --metric option.");
        $self->{output}->option_exit();
    }

    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT1M";

    $self->{az_aggregation} = ['Average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregation} = [];
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation ne '') {
                push @{$self->{az_aggregation}}, ucfirst(lc($aggregation));
            }
        }
    }

    if (defined($self->{option_results}->{filter_dimension}) && $self->{option_results}->{filter_dimension} ne '') {
        $self->{az_metrics_dimension} = $self->{option_results}->{filter_dimension};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($results, $raw_results) = $options{custom}->azure_get_metrics(
        resource => $self->{az_resource},
        resource_group => $self->{az_resource_group},
        resource_type => $self->{az_resource_type},
        resource_namespace => $self->{az_resource_namespace},
        metrics => $self->{az_metrics},
        aggregations => $self->{az_aggregation},
        timeframe => $self->{az_timeframe},
        interval => $self->{az_interval},
        dimension => $self->{az_metrics_dimension}
    );

    $self->{metrics} = {};
    foreach my $label (keys %{$results}) {
        foreach my $aggregation (('minimum', 'maximum', 'average', 'total')) {
            next if (!defined($results->{$label}->{$aggregation}));

            $self->{metrics}->{$label . '_' . $aggregation} = {
                display => $self->{az_resource},
                name => $results->{$label}->{name},
                label => $label,
                aggregation => $aggregation,
                value => $results->{$label}->{$aggregation},
                perf_label => $label . '_' . $aggregation,
            };
        }
    }
    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No metric found (Are the filters properly set?)");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("Raw data:\n%s", Dumper($raw_results)), debug => 1);
}

1;

__END__

=head1 MODE

Check Azure metrics.

Examples:
perl centreon_plugins.pl --plugin=cloud::azure::management::monitor::plugin --custommode=azcli --mode=get-metrics
--resource=MYSQLINSTANCE --resource-group=MYHOSTGROUP --resource-namespace='Microsoft.Compute' --resource-type='virtualMachines'
--metric='Percentage CPU' --aggregation=average –-interval=PT1M --timeframe=600 --warning-metric= --critical-metric=

perl centreon_plugins.pl --plugin=cloud::azure::management::monitor::plugin --custommode=azcli --mode=get-metrics
--resource='/subscriptions/d29fe431/resourceGroups/MYHOSTGROUP/providers/Microsoft.Compute/virtualMachines/MYSQLINSTANCE'
--metric='Percentage CPU' --aggregation=average –-interval=PT1M --timeframe=600 --warning-metric= --critical-metric=

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--resource-namespace>

Set resource namespace (Required if resource's name is used).

=item B<--resource-type>

Set resource type (Required if resource's name is used).

=item B<--metric>

Set monitor metrics (Required) (Can be multiple).

=item B<--filter-dimension>

Specify the metric dimension (required for some specific metrics)
Syntax example:
--filter-dimension="$metricname eq '$metricvalue'"

=item B<--warning-metric>

Threshold warning.

=item B<--critical-metric>

Threshold critical.

=back

=cut
