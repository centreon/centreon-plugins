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

package cloud::google::gcp::custom::mode;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub prefix_aggregations_output {
    my ($self, %options) = @_;
    
    return "aggregation '" . $options{instance_value}->{display} . "' metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking '" . $options{instance_value}->{display} . "' ";
}

sub custom_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{timeframe} = $options{new_datas}->{ $self->{instance} . '_timeframe' };
    $self->{result_values}->{value}->{absolute} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{metric} };
    $self->{result_values}->{value}->{absolute} = eval $self->{result_values}->{value}->{absolute} . $self->{instance_mode}->{metrics_mapping}->{$options{extra_options}->{metric}}->{calc}
        if (defined($self->{instance_mode}->{metrics_mapping}->{$options{extra_options}->{metric}}->{calc}));
    $self->{result_values}->{value}->{per_second} = $self->{result_values}->{value}->{absolute} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_threshold {
    my ($self, %options) = @_;

    my $threshold = $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{threshold};
    my $value = $self->{result_values}->{value}->{absolute};
    if (defined($self->{instance_mode}->{option_results}->{per_second})) {
        $value = $self->{result_values}->{value}->{per_second};
    }
    my $exit = $self->{perfdata}->threshold_check(
        value => $value,
        threshold => [
            { label => 'critical-' . $threshold, exit_litteral => 'critical' },
            { label => 'warning-' . $threshold, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_perfdata {
    my ($self, %options) = @_;

    my $threshold = $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{threshold};
    my $options = $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{perfdata}->{absolute};
    my $value = sprintf(
        $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{perfdata}->{absolute}->{format},
        $self->{result_values}->{value}->{absolute}
    );
    if (defined($self->{instance_mode}->{option_results}->{per_second}) && 
        defined($self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{perfdata}->{per_second})) {
        $value = sprintf(
            $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{perfdata}->{per_second}->{format},
            $self->{result_values}->{value}->{per_second}
        );
        $options = $self->{instance_mode}->{metrics_mapping}->{ $self->{result_values}->{metric} }->{perfdata}->{per_second};
    }

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        value => $value,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $threshold),
        critical => $self->{perfdata}->get_perfdata_for_output( label => 'critical-' . $threshold),
        %{$options}
    );
}

sub custom_output {
    my ($self, %options) = @_;
    
    my $unit = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{perfdata}->{absolute}->{unit};
    my $output = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{output_string};

    my $value = $self->{result_values}->{value}->{absolute};
    if (defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{perfdata}->{absolute}->{change_bytes})) {
        ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}->{absolute});
    }
    if (defined($self->{instance_mode}->{option_results}->{per_second}) &&
        defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{perfdata}->{per_second})) {
        $unit = $self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{perfdata}->{per_second}->{unit};
        $value = $self->{result_values}->{value}->{per_second};
        
        if (defined($self->{instance_mode}->{metrics_mapping}->{$self->{result_values}->{metric}}->{perfdata}->{per_second}->{change_bytes})) {
            ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}->{per_second});
            $unit .= "/s";
        }
    }

    my $msg = sprintf($output, $value);
    $msg .= " " . $unit if (defined($unit) && $unit ne "");

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{metrics_mapping} = $self->get_metrics_mapping();
    
    $self->{maps_counters_type} = [
        {
            type => 3,
            name => 'metrics',
            cb_prefix_output => 'prefix_output',
            cb_long_output => 'long_output',
            message_multiple => 'All metrics are ok',
            indent_long_output => '    ',
            group => [
                {
                    type => 1,
                    name => 'aggregations',
                    cb_prefix_output => 'prefix_aggregations_output',
                    display_long => 1,
                    message_multiple => 'all metrics are ok',
                    skipped_code => { -10 => 1 }
                }
            ]
        }
    ];

    foreach my $metric (sort { $self->{metrics_mapping}->{$a}->{order} <=> $self->{metrics_mapping}->{$b}->{order} } keys %{$self->{metrics_mapping}}) {
        my $entry = {
            label => $self->{metrics_mapping}->{$metric}->{threshold},
            set => {
                key_values => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output => $self->can('custom_output'),
                closure_custom_perfdata => $self->can('custom_perfdata'),
                closure_custom_threshold_check => $self->can('custom_threshold')
            }
        };
        push @{$self->{maps_counters}->{aggregations}}, $entry;
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{dimension_value})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --dimension-value <value>.");
        $self->{output}->option_exit();
    }

    $self->{gcp_timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : 900;

    my $aggregations = [];
    if (defined($self->{option_results}->{aggregation})) {
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation !~ /average|maximum|minimum|total/i) {
                $self->{output}->add_option_msg(short_msg => "Aggregation '" . $aggregation . "' is not handled");
                $self->{output}->option_exit();
            }
            
            push @$aggregations, $aggregation;
        }
    }
    $self->{gcp_aggregations} = ['average'];
    if (scalar(@$aggregations) > 0) {
        $self->{gcp_aggregations} = $aggregations;
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{gcp_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{metrics} = {};
    foreach my $metric (@{$self->{gcp_metrics}}) {
        my ($metric_results) = $options{custom}->gcp_get_metrics(
            dimension_name => $self->{gcp_dimension_name},
            dimension_operator => $self->{gcp_dimension_operator},
            dimension_value => $self->{gcp_dimension_value},
            instance_key => $self->{gcp_instance_key},
            metric => $metric,
            api => $self->{gcp_api},
            aggregations => $self->{gcp_aggregations},
            timeframe => $self->{gcp_timeframe},
            dimension_zeroed => $self->{gcp_dimension_zeroed}
        );

        foreach my $instance_name (keys %$metric_results) {
            foreach my $aggregation (@{$self->{gcp_aggregations}}) {
                if (!defined($self->{metrics}->{$instance_name})) {
                    $self->{metrics}->{$instance_name} = {
                        display => $instance_name,
                        aggregations => {}
                    };
                }
                if (!defined($self->{metrics}->{$instance_name}->{aggregations}->{lc($aggregation)})) {
                    $self->{metrics}->{$instance_name}->{aggregations}->{lc($aggregation)} = {
                        display => $aggregation,
                        timeframe => $self->{gcp_timeframe}
                    };
                }
                $self->{metrics}->{$instance_name}->{aggregations}->{lc($aggregation)}->{$metric} =
                    defined($metric_results->{$instance_name}->{$metric}->{lc($aggregation)}) ? $metric_results->{$instance_name}->{$metric}->{lc($aggregation)} : 0
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(
            short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values'
        );
        $self->{output}->option_exit();
    }
}

1;

__END__

