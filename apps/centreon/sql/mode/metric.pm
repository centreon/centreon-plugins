#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::centreon::sql::mode::metric;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use List::Util qw (min max sum);

my $instance_mode;

sub custom_global_output {
    my ($self, %options) = @_;

    my $msg = sprintf("$instance_mode->{option_results}->{format}",
                       $self->{result_values}->{to_output}, $self->{result_values}->{unit}, $instance_mode->{option_results}->{format_suffix});

    return $msg;

}

sub custom_global_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{computed} = $options{new_datas}->{$self->{instance} . '_computed'};

    if (defined($instance_mode->{option_results}->{custom_global})) {
           $self->{result_values}->{computed} = eval "$self->{result_values}->{computed} $instance_mode->{option_results}->{custom_global}";
    }

    if (defined($instance_mode->{perfdata_max}->{computed})) {
        $self->{result_values}->{free} = $instance_mode->{perfdata_max}->{computed} - $self->{result_values}->{computed};
        $self->{result_values}->{prct_used} = $self->{result_values}->{computed} * 100 / $instance_mode->{perfdata_max}->{computed};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    }

    if (defined($instance_mode->{option_results}->{change_bytes})) {
        ($self->{result_values}->{to_output}, $self->{result_values}->{unit}) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{computed});
    } else {
        ($self->{result_values}->{to_output}, $self->{result_values}->{unit}) = ($self->{result_values}->{computed}, $instance_mode->{option_results}->{perfdata_unit});
    }
    return 0;
}

sub custom_global_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(label => $instance_mode->{option_results}->{perfdata_global_label},
                                  value => $self->{result_values}->{computed},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-computed', total => $instance_mode->{perfdata_max}->{computed}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-computed', total => $instance_mode->{perfdata_max}->{computed}, cast_int => 1),
                                  unit => $instance_mode->{option_results}->{perfdata_unit},
                                  min => $instance_mode->{option_results}->{perfdata_min},
                                  max => $instance_mode->{perfdata_max}->{computed}
                                 );
}

sub custom_computed_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{computed};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{threshold_unit} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    print "$threshold_value -- #\n";
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_global2_output {
    my ($self, %options) = @_;

    my $msg = sprintf("$instance_mode->{option_results}->{format2}",
                      $self->{result_values}->{to_output2}, $self->{result_values}->{unit},
                      $instance_mode->{option_results}->{format_suffix}, $instance_mode->{option_results}->{format_suffix});

    return $msg;
}

sub custom_global2_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{computed2} = $options{new_datas}->{$self->{instance} . '_computed2'};

    if (defined($instance_mode->{option_results}->{custom_global})) {
           $self->{result_values}->{computed2} = eval "$self->{result_values}->{computed2} $instance_mode->{option_results}->{custom_global}";
    }

    if (defined($instance_mode->{perfdata_max}->{computed2})) {
        $self->{result_values}->{free} = $instance_mode->{perfdata_max}->{computed2} - $self->{result_values}->{computed2};
        $self->{result_values}->{prct_used} = $self->{result_values}->{computed2} * 100 / $instance_mode->{perfdata_max}->{computed2};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    }

    if (defined($instance_mode->{option_results}->{change_bytes})) {
        ($self->{result_values}->{to_output2}, $self->{result_values}->{unit}) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{computed2});
    } else {
        ($self->{result_values}->{to_output2}, $self->{result_values}->{unit}) = ($self->{result_values}->{computed2}, $instance_mode->{option_results}->{perfdata_unit});
    }
    return 0;
}

sub custom_global2_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);

    $self->{output}->perfdata_add(label => $instance_mode->{option_results}->{perfdata_global_label2},
                                  value => $self->{result_values}->{computed2},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-computed2', total => $instance_mode->{perfdata_max}->{computed2}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-computed2', total => $instance_mode->{perfdata_max}->{computed2}, cast_int => 1),
                                  unit => $instance_mode->{option_results}->{perfdata_unit},
                                  min => $instance_mode->{option_results}->{perfdata_min},
                                  max => $instance_mode->{perfdata_max}->{computed2},
                                 );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg = sprintf("$instance_mode->{option_results}->{format_metric}", $self->{result_values}->{instance},
                       $self->{result_values}->{to_output}, $self->{result_values}->{unit}, $instance_mode->{option_results}->{format_suffix});
    return $msg;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_max'};
    $self->{result_values}->{instance} = $options{new_datas}->{$self->{instance} . '_display'};

    if (defined($instance_mode->{option_results}->{custom_unit})) {
             $self->{result_values}->{value} = eval "$self->{result_values}->{value} $instance_mode->{option_results}->{custom_unit}";
    }


    if (defined($self->{result_values}->{max}) && $self->{result_values}->{max} > 0) {
        $self->{result_values}->{free} = $self->{result_values}->{max} - $self->{result_values}->{value};
        $self->{result_values}->{prct_used} = $self->{result_values}->{value} * 100 / $self->{result_values}->{max};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    }
    if (defined($instance_mode->{option_results}->{change_bytes})) {
       ($self->{result_values}->{to_output}, $self->{result_values}->{unit}) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value});
    } else {
       ($self->{result_values}->{to_output}, $self->{result_values}->{unit}) = ($self->{result_values}->{value}, $instance_mode->{option_results}->{perfdata_unit});
    }
    return 0;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(label => $self->{result_values}->{instance},
                                  value => $self->{result_values}->{value},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric', total => $self->{result_values}->{max}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric', total => $self->{result_values}->{max}, cast_int => 1),
                                  unit => $instance_mode->{option_results}->{perfdata_unit},
                                  min => $instance_mode->{option_results}->{perfdata_min},
                                  max => $self->{result_values}->{max},
                                 );
}

sub custom_global_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{computed};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{threshold_unit} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_global2_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{computed2};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{threshold_unit} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{value};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{threshold_unit} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'metric', type => 1, message_multiple => 'All metrics are OK' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'computed', set => {
                key_values => [ { name => 'computed' } ],
                closure_custom_calc => \&custom_global_calc,
                closure_custom_output => \&custom_global_output,
                closure_custom_perfdata => \&custom_global_perfdata,
                closure_custom_threshold_check => \&custom_global_threshold,

            }
        },
        { label => 'computed2', set => {
                key_values => [ { name => 'computed2' } ],
                closure_custom_calc => \&custom_global2_calc,
                closure_custom_output => \&custom_global2_output,
                closure_custom_perfdata => \&custom_global2_perfdata,
                closure_custom_threshold_check => \&custom_global2_threshold,
            }
        },
    ];

    $self->{maps_counters}->{metric} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'max' }, { name => 'display' } ],
                closure_custom_calc => \&custom_metric_calc,
                closure_custom_output => \&custom_metric_output,
                closure_custom_perfdata => \&custom_metric_perfdata,
                closure_custom_threshold_check => \&custom_metric_threshold,
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "format:s"                    => { name => 'format', default => 'Aggregated value is %s%s' },
                                  "format2:s"                   => { name => 'format2', default => 'Aggregated value2 is %s%s' },
                                  "format-suffix:s"             => { name => 'format_suffix', default => ' ' },
                                  "format-metric:s"             => { name => 'format_metric', default => 'Metric %s value is %s%s' },
                                  "host-filter:s"               => { name => 'host_filter' },
                                  "service-filter:s"            => { name => 'service_filter' },
                                  "metric-filter:s"             => { name => 'metric_filter' },
                                  "split-rule:s"                => { name => 'split_rule' },
                                  "aggregation:s"               => { name => 'aggregation' },
                                  "custom-global:s"             => { name => 'custom_global' },
                                  "custom-unit:s"               => { name => 'custom_unit' },
                                  "change-bytes"                => { name => 'change_bytes' },
                                  "free"                        => { name => 'free' },
                                  "perfdata-global-label"       => { name => 'perfdata_global_label', default => 'computed' },
                                  "perfdata-global-label2"      => { name => 'perfdata_global_label2', default => 'computed2' },
                                  "perfdata-separator:s"        => { name => 'perfdata_separator', default => '#' },
                                  "perfdata-unit:s"             => { name => 'perfdata_unit', default => 'unit'},
                                  "perfdata-min:s"              => { name => 'perfdata_min'},
                                  "perfdata-max:s"              => { name => 'perfdata_max'},
                                  "perfdata-max-metric:s"       => { name => 'perfdata_max_metric'},
                                  "threshold-unit:s"            => { name => 'threshold_unit', default => 'absolute' },
                                });
    return $self;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "Metric '" . $options{instance_value}->{display} . "' ";
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;

    if (defined($self->{option_results}->{custom}) && defined($self->{option_results}->{aggregation})) {
        $self->{output}->add_option_msg(short_msg => "Cannot use aggregation and custom operation ");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{custom}) && !defined($self->{option_results}->{aggregation})) {
        $self->{output}->add_option_msg(short_msg => "Please choose either custom operation (see --custom) or aggregation (see --aggregation) ");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{split_rule}) && $self->{option_results}->{split_rule} ne '') {
        ($self->{pattern1}, $self->{pattern2}) = split /,/, $self->{option_results}->{split_rule};
    }

}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{perfdata_max} = {};
    my ($value, $value2);

    my $query = "SELECT index_data.host_name, index_data.service_description, metrics.metric_name, metrics.current_value, metrics.max FROM centreon_storage.index_data, centreon_storage.metrics WHERE index_data.id = metrics.index_id ";
    $query .= "AND index_data.service_description LIKE '" . $self->{option_results}->{service_filter} . "'" if defined($self->{option_results}->{service_filter});
    $query .= "AND index_data.host_name LIKE '" . $self->{option_results}->{host_filter} . "'" if defined($self->{option_results}->{host_filter});
    $query .= "AND metrics.metric_name LIKE '" . $self->{option_results}->{metric_filter} . "'" if defined($self->{option_results}->{metric_filter});
    $self->{sql}->query(query => $query);

    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $m_name = $row->{host_name}.$self->{option_results}->{perfdata_separator}.$row->{service_description}.$self->{option_results}->{perfdata_separator}.$row->{metric_name};
        $self->{metrics}->{selected_value}{$m_name} = $row->{current_value};

        if (defined($self->{pattern1}) && defined($self->{pattern2})) {
            push (@{$self->{metrics}->{selected_value}{$self->{pattern1}}}, $row->{current_value}) if $row->{metric_name} =~ /$self->{pattern1}/;
            push (@{$self->{metrics}->{selected_value}{$self->{pattern2}}}, $row->{current_value}) if $row->{metric_name} =~ /$self->{pattern2}/;

            $self->{perfdata_max}{computed} += $row->{max} if (defined($row->{max}) && ($row->{metric_name} =~ /$self->{pattern1}/));
            $self->{perfdata_max}{computed2} += $row->{max} if (defined($row->{max}) && ($row->{metric_name} =~ /$self->{pattern2}/));
        }

        push (@{$self->{metrics}->{selected_value}{all}}, $row->{current_value});
        $self->{perfdata_max}{computed} += $row->{max} if defined($row->{max});
        $self->{metric}->{$m_name} = { value => $row->{current_value},
                                       max => defined($row->{max}) ? $row->{max} : $self->{option_results}->{perfdata_max_m},
                                       display => $m_name };
    }

    if (scalar(keys %{$self->{metrics}->{selected_value}}) <= 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "No metric returned - check you filters (host-service-metric) and split-rule");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if (defined($self->{option_results}->{split_rule})) {
        $value = sprintf("%2.f", min(@{$self->{metrics}->{selected_value}{$self->{pattern1}}})) if ($self->{option_results}->{aggregation} eq 'min');
        $value = sprintf("%2.f", max(@{$self->{metrics}->{selected_value}{$self->{pattern1}}})) if ($self->{option_results}->{aggregation} eq 'max');
        $value = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{$self->{pattern1}}})) if ($self->{option_results}->{aggregation} eq 'sum');
        $value = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{$self->{pattern1}}})/scalar @{$self->{metrics}->{selected_value}{$self->{pattern1}}}) if ($self->{option_results}->{aggregation} eq 'avg');

        $value2 = sprintf("%2.f", min(@{$self->{metrics}->{selected_value}{$self->{pattern2}}})) if ($self->{option_results}->{aggregation} eq 'min');
        $value2 = sprintf("%2.f", max(@{$self->{metrics}->{selected_value}{$self->{pattern2}}})) if ($self->{option_results}->{aggregation} eq 'max');
        $value2 = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{$self->{pattern2}}})) if ($self->{option_results}->{aggregation} eq 'sum');
        $value2 = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{$self->{pattern2}}})/scalar @{$self->{metrics}->{selected_value}{$self->{pattern2}}}) if ($self->{option_results}->{aggregation} eq 'avg');

        $self->{global} = { computed => $value,
                            computed2 => $value2 };

    } else {
        $value = sprintf("%2.f", min(@{$self->{metrics}->{selected_value}{all}})) if ($self->{option_results}->{aggregation} eq 'min');
        $value = sprintf("%2.f", max(@{$self->{metrics}->{selected_value}{all}})) if ($self->{option_results}->{aggregation} eq 'max');
        $value = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{all}})) if ($self->{option_results}->{aggregation} eq 'sum');
        $value = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{all}})/scalar @{$self->{metrics}->{selected_value}{all}}) if ($self->{option_results}->{aggregation} eq 'avg');

        $self->{global} = { computed => $value };
    }

}

1;

__END__

=head1 MODE

Aggregate and compute results of metrics - allow to mix values from several plugins
e.g one service displaying sum of CPU on ESX - one service displaying average traffic of all port on a switch

=over 8

=item B<--warning-*>

Warning threshold
Can be 'computed', 'computed2', 'metric'

=item B<--critical-*>

Warning threshold
Can be 'computed', 'computed2', 'metric'

=item B<--filter-counters>

Only display some counters. Can be 'metric', 'global'

=item B<--format>

sprintf-like format to display first computed metric (Default is 'Aggregated value is %s%s')

=item B<--format2>

sprintf-like format to display second computed metric (Default is 'Aggregated value2 is %s%s')

=item B<--format-suffix>

string to suffix global message (useful when you want to specify Bits/s)

=item B<--format-metric>

sprintf-like format to display unit metric message (Default is: 'Metric %s value is %s%s')

=item B<--host-filter>

filter for host_name in query (SQL syntax, only '%' wildcard)

=item B<--service-filter>

filter for service_description in query (SQL syntax, only '%' wildcard)

=item B<--metric-filter>

filter for metric_name in query (SQL syntax, only '%' wildcard)

=item B<--aggregation>

choose aggregation method. Can be 'sum', 'min', 'max', 'average'

=item B<--split-rule>

format --split-rule pattern1,pattern2 . useful when you want to split traffic in/out or read/write iops for aggregation/compute

=item B<--custom-global>

use eval to compute global aggregated metrics (e.g --custom-global "/ 2" will divide by two aggregated metrics values )

=item B<--custom-unit>

use eval to compute on each metrics (e.g --custom-unit "- 200" will substract 200 to the metric value)

=item B<--change-bytes>

allow you to display output in more readable way (value should be byte of course ;)

=item B<--perfdata-unit>

unit of perfdata to use in the RRD graph

=item B<--perfdata-min>

minimum value of perfdata to use in the RRD graph

=item B<--perfdata-separator>

separator to use in perfdata between "hostname"<separator>"service"<separator>"metric_name"

=item B<--perfdata-max-metric>

maximum value of perfdata to use in the RRD graph for each unique metric (will not ignored if a max value is present in metric table)

=item B<--perfdata-max>

maximum value of agregated values to use in the RRD graph for each unique metric (will not ignored if a max value is present in metric table)

=item B<--threshold-unit>

threshold unit to use (default is 'absolute', can be '%')

=back

=cut
