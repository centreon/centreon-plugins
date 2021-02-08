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

package cloud::azure::database::elasticpool::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'cpu_limit' => {
        'output' => 'CPU Limit',
        'label'  => 'cpu-limit',
        'nlabel' => 'elasticpool.cpu.limit.count',
        'unit'   => ''
    },
    'cpu_percent' => {
        'output' => 'CPU Percentage Usage',
        'label'  => 'cpu-percent',
        'nlabel' => 'elasticpool.cpu.usage.percentage',
        'unit'   => '%'
    },
    'cpu_used' => {
        'output' => 'CPU Used',
        'label'  => 'cpu-used',
        'nlabel' => 'elasticpool.cpu.used.count',
        'unit'   => ''
    }
);

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        nlabel    => $metrics_mapping{$self->{result_values}->{metric}}->{nlabel},
        unit      => $metrics_mapping{$self->{result_values}->{metric}}->{unit},
        value     => sprintf('%.2f', $self->{result_values}->{value}),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label})
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my ($value, $unit) = ($self->{result_values}->{value}, $metrics_mapping{$self->{result_values}->{metric}}->{unit});

    return sprintf('%s: %.2f %s', $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value, $unit);
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "Elastic Pool '" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking Pool'" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All CPU metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            nlabel => $metrics_mapping{$metric}->{nlabel},
            set => {
                key_values                        => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc               => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output             => $self->can('custom_metric_output'),
                closure_custom_perfdata           => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check    => $self->can('custom_metric_threshold')
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'resource:s@'      => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' },
        'filter-metric:s'  => { name => 'filter_metric' }
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

    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));
    $self->{az_resource_type} = 'servers';
    $self->{az_resource_namespace} = 'Microsoft.Sql';
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

    foreach my $metric (keys %metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{az_metrics}}, $metric;
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    my $raw_results;
    foreach my $resource (@{$self->{az_resource}}) {
        my $resource_group = $self->{az_resource_group};
        my ($resource_display, $resource_name);

        if ($resource =~ /^(.*)\/elasticpools\/(.*)/) {
            ($resource_display, $resource_name) = ($1 . '/' . $2, $resource);
        } else {
            $self->{output}->add_option_msg(short_msg => 'Incorrect resource format');
            $self->{output}->option_exit();
        };

        if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Sql\/servers\/(.*)\/elasticpools\/(.*)$/) {
            $resource_group = $1;
            $resource_display = $2 . '/' . $3;
            $resource_name = $2 . '/elasticpools/' . $3;
        }

        ($metric_results{$resource_display}, $raw_results) = $options{custom}->azure_get_metrics(
            resource => $resource_name,
            resource_group => $resource_group,
            resource_type => $self->{az_resource_type},
            resource_namespace => $self->{az_resource_namespace},
            metrics => $self->{az_metrics},
            aggregations => $self->{az_aggregations},
            timeframe => $self->{az_timeframe},
            interval => $self->{az_interval}
        );

        foreach my $metric (@{$self->{az_metrics}}) {
            foreach my $aggregation (@{$self->{az_aggregations}}) {
                next if (!defined($metric_results{$resource_display}->{$metric}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$resource_display}->{display} = $resource_display;
                $self->{metrics}->{$resource_display}->{statistics}->{lc($aggregation)}->{display} = lc($aggregation);
                $self->{metrics}->{$resource_display}->{statistics}->{lc($aggregation)}->{timeframe} = $self->{az_timeframe};
                $self->{metrics}->{$resource_display}->{statistics}->{lc($aggregation)}->{$metric} =
                    defined($metric_results{$resource_display}->{$metric}->{lc($aggregation)}) ?
                    $metric_results{$resource_display}->{$metric}->{lc($aggregation)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }

}

1;

__END__

=head1 MODE

Check Azure SQL Elastic Pool CPU metrics.
(Only applies to vCore-based elastic pools)

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::database::elasticpool::plugin --custommode=azcli --mode=cpu
--resource=<sqlserver>/elasticpools/<elasticpool> --resource-group=<resourcegroup> --aggregation='average'
--critical-cpu-percent='90' --verbose

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=cpu
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Sql/servers/xxx/elasticpools/xxx'
--aggregation='average' --critical-cpu-percent='90' --verbose

Default aggregation: 'average' / 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--filter-metric>

Filter on specific metrics. The Azure format must be used, for example: 'cpu_percent'
(Can be a regexp).

=item B<--warning-*>

Warning threshold where * can be: 'cpu-limit', 'cpu-percent', 'cpu-used'.

=item B<--critical-*>

Critical threshold where * can be: 'cpu-limit', 'cpu-percent', 'cpu-used'.

=back

=cut
