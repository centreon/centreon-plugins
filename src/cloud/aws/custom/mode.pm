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

package cloud::aws::custom::mode;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        nlabel    => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{nlabel}->{per_second} :
            $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{nlabel}->{absolute},
        unit      => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{unit} . '/s' :
            $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{unit},
        value     => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{result_values}->{value_per_sec} :
            $self->{result_values}->{value}),
        min       => $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{min},
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{label}),
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $extra_unit = '';
    my $metric_label = 'value';
    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        $metric_label = 'value_per_sec';
        $extra_unit = '/s';
    }

    my ($value, $unit);
    if ($self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{unit} eq 'B') {
        ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{$metric_label});
    } elsif ($self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{unit} eq 'bps') {
        ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{$metric_label}, network => 1);
        $extra_unit = '/s';
    } else {
        ($value, $unit) = ($self->{result_values}->{$metric_label}, $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{unit});
    }

    my $msg = sprintf("%s: %.2f %s", $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{output}, $value, $unit . $extra_unit);

    return $msg;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
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

    my $data = $self->get_metrics_mapping();
    $self->{metrics_mapping} = $data->{metrics};

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => defined($data->{extra_params}->{message_multiple}) ? $data->{extra_params}->{message_multiple} : 'All metrics are ok',
          indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (sort keys %{$self->{metrics_mapping}}) {
        my $entry = {
            label => $self->{metrics_mapping}->{$metric}->{label},
            set => {
                key_values                          => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc                 => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options   => { metric => $metric },
                closure_custom_output               => $self->can('custom_metric_output'),
                closure_custom_perfdata             => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check      => $self->can('custom_metric_threshold')
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-metric:s'  => { name => 'filter_metric' },
        'per-sec'          => { name => 'per_sec' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;

    $self->{aws_statistics} = ['Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    };

    $self->{aws_metrics} = [];
    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{aws_metrics}}, $metric;
    };
}

1;

__END__

