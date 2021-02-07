#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package apps::monitoring::netdata::restapi::mode::getchart;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{perf_label},
        value => $self->{result_values}->{value},
        unit  => $self->{result_values}->{unit},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric')
    );
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value},
        threshold => [
            { label => 'critical-metric', exit_litteral => 'critical' },
            { label => 'warning-metric', exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_output {
    my ($self, %options) = @_;

    return sprintf(
        "Metric '%s' value is %.2f %s",
        $self->{result_values}->{display}, $self->{result_values}->{value}, $self->{result_values}->{unit}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, message_multiple => 'All metrics are ok' }
    ];

    $self->{maps_counters}->{metric} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'perf_label' }, { name => 'display' }, { name => 'unit' } ],
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
          'chart-name:s'        => { name => 'chart_name' },
          'chart-period:s'      => { name => 'chart_period', default => '300' },
          'chart-statistics:s'  => { name => 'chart_statistics', default => 'average' },
          'filter-metric:s'     => { name => 'filter_metric' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{chart_name}) || $self->{option_results}->{chart_name} eq '') {
       $self->{output}->add_option_msg(short_msg => "Missing --chart-name option or value.");
       $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my $dimensions = '';

    if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne '') {
        $dimensions = $self->{option_results}->{filter_metric}
    };

    my $unit = $options{custom}->get_chart_properties(chart => $self->{option_results}->{chart_name}, filter_info => 'units');
    my $result = $options{custom}->get_data(
        chart => $self->{option_results}->{chart_name},
        points => $self->{option_results}->{chart_point},
        after_period => $self->{option_results}->{chart_period},
        group => $self->{option_results}->{chart_statistics},
        dimensions => $dimensions
    );

    my $chart_name = $self->{option_results}->{chart_name};
    my $stat = $self->{option_results}->{chart_statistics};

    foreach my $chart_value (@{$result->{data}}) {
        foreach my $chart_label (@{$result->{labels}}) {
            $self->{metrics}->{$chart_name}->{$chart_label} = shift @{$chart_value};
        }
    }

    foreach my $metric (keys %{$self->{metrics}->{$chart_name}}) {
        next if ($metric eq 'time');
        foreach my $value (values %{$self->{metrics}->{$chart_name}}) {
            $self->{metric}->{$metric . '_' . $stat} = {
                    display => $metric . '_' . $stat,
                    value => $value,
                    unit => $unit,
                    perf_label => $metric . '_' . $stat
            };
        }
    }
};

1;

__END__

=head1 MODE

Get data for charts available on the Netdata RestAPI.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=get-chart --hostname=10.0.0.1 --chart-name='system.cpu' --filter-metric=iowait

More information on'https://learn.netdata.cloud/docs/agent/web/api'.

=over 8

=item B<--chart-name>

The Netdata chart name to query
This option is mandatory

=item B<--chart-period>

The period in seconds on which the values are calculated
Default: 300

=item B<--chart-statistic>

The statistic calculation method used to parse the collected data.
Can be : average, sum, min, max
Default: average

=item B<--filter-metric>

Filter on specific chart metric.
By default, all the metrics will be displayed

=item B<--warning-metric>

Warning threshold (global to all the collected metrics)

=item B<--critical-metric>

Critical threshold (global to all the collected metrics)


=back

=cut
