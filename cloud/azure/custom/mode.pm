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

package cloud::azure::custom::mode;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-dimension:s' => { name => 'filter_dimension' },
        'per-sec'            => { name => 'per_second'}
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MODE OPTIONS', once => 1);

    return $self;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value}->{absolute} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{value}->{per_second} = $self->{result_values}->{value}->{absolute} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => defined($self->{instance_mode}->{option_results}->{per_second}) ? $self->{result_values}->{value}->{per_second} : $self->{result_values}->{value}->{absolute},
        threshold => [
            { label => 'critical-' . $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;
    my $options = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}};
    my $value = defined($self->{instance_mode}->{option_results}->{per_second}) ? $self->{result_values}->{value}->{per_second} : $self->{result_values}->{value}->{absolute};
    my $format = defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{template}) ? $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{template} : '%.2f';
    if (defined($self->{instance_mode}->{option_results}->{per_second})) {
        $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{nlabel} .= '.persecond';
        $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{unit} .= '/s';
    }

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        value     => sprintf($format, $value),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{label}),
        %{$options}
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $network = defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{network}) ? { network => '1' } : undef;

    my ($value, $unit) = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{unit} eq 'B' ?
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}->{absolute}, %{$network}) :
        ($self->{result_values}->{value}->{absolute}, $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{unit});

    if (defined($self->{instance_mode}->{option_results}->{per_second})) {
        ($value, $unit) = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{unit} eq 'B' ?
            $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}->{per_second}, %{$network}) :
            ($self->{result_values}->{value}->{per_second}, $unit);
        $unit .=  '/s';
    }
    my $format = defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{template}) ? $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{template} : '%.2f';

    return sprintf('%s: ' . $format . '%s', $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{output}, $value, $unit);
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    $self->{metrics_mapping} = $self->get_metrics_mapping;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        my $entry = {
            label => $self->{metrics_mapping}->{$metric}->{label},
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

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    my $raw_results;

    if (defined($self->{option_results}->{filter_dimension}) && $self->{option_results}->{filter_dimension} ne '') {
        $self->{az_dimension} = $self->{option_results}->{filter_dimension};
    }

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
        foreach my $aggregation (@{$self->{az_aggregations}}) {
            next if (!defined($metric_results{$self->{az_resource}}->{$metric}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

            $self->{metrics}->{$self->{az_resource}}->{display} = $self->{az_resource};
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{display} = lc($aggregation);
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{timeframe} = $self->{az_timeframe};
            $self->{metrics}->{$self->{az_resource}}->{statistics}->{lc($aggregation)}->{$metric} =
                defined($metric_results{$self->{az_resource}}->{$metric}->{lc($aggregation)}) ?
                $metric_results{$self->{az_resource}}->{$metric}->{lc($aggregation)} : 0;
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

Azure custom class for monitor based modes.

=head1 CUSTOM MODE OPTIONS

=over 8

=item B<--filter-dimension>

Specify the metric dimension (required for some specific metrics)
Syntax example:
--filter-dimension="$metricname eq '$metricvalue'"

=item B<--per-sec>

Display the statistics based on a per-second period.

=back

=cut
