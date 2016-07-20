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

    my $msg = sprintf("$instance_mode->{option_results}->{format}", $self->{result_values}->{to_output}, $self->{result_values}->{unit});
    return $msg;
}

sub custom_global_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{computed} = $options{new_datas}->{$self->{instance} . '_computed'};

    if (defined($instance_mode->{option_results}->{custom_global}) && $instance_mode->{option_results}->{custom_global} ne '') {
           $self->{result_values}->{computed} = eval "$self->{result_values}->{computed} $instance_mode->{option_results}->{custom_global}";
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

    my ($warning, $critical);
    if ($instance_mode->{option_results}->{perfdata_unit} eq '%' && !defined($instance_mode->{option_results}->{absolute})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-computed', total => $instance_mode->{option_results}->{perfdata_max}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-computed', total => $instance_mode->{option_results}->{perfdata_max}, cast_int => 1);
    } else {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-computed');
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-computed');
    }

    $self->{output}->perfdata_add(label => $instance_mode->{option_results}->{perfdata_global_label},
                                  value => $self->{result_values}->{computed},
                                  warning => $warning,
                                  critical => $critical,
                                  unit => $instance_mode->{option_results}->{perfdata_unit},
                                  min => $instance_mode->{option_results}->{perfdata_min},
                                  max => $instance_mode->{option_results}->{perfdata_max}
                                 );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg = sprintf("$instance_mode->{option_results}->{format_metric}", $self->{result_values}->{instance},
                        $self->{result_values}->{to_output}, $self->{result_values}->{unit});
    return $msg;
}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{instance} = $options{new_datas}->{$self->{instance} . '_display'};

    if (defined($instance_mode->{option_results}->{custom_unit}) && $instance_mode->{option_results}->{custom_unit} ne '') {
             $self->{result_values}->{value} = eval "$self->{result_values}->{value} $instance_mode->{option_results}->{custom_unit}";
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

    my ($warning, $critical);
    if ($instance_mode->{option_results}->{perfdata_unit} eq '%' && !defined($instance_mode->{option_results}->{absolute})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric', total => $instance_mode->{option_results}->{perfdata_max}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric', total => $instance_mode->{option_results}->{perfdata_max}, cast_int => 1);
    } else {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-metric');
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-metric');
    }

    $self->{output}->perfdata_add(label => $self->{result_values}->{instance},
                                  value => $self->{result_values}->{value},
                                  warning => $warning,
                                  critical => $critical,
                                  unit => $instance_mode->{option_results}->{perfdata_unit},
                                  min => $instance_mode->{option_results}->{perfdata_min},
                                  max => $instance_mode->{option_results}->{perfdata_max}
                                 );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'metric', type => 1, message_multiple => 'All metrics are OK' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'computed', set => {
                key_values => [ { name => 'computed' }, ],
                threshold_use => 'computed',
                closure_custom_calc => \&custom_global_calc,
                closure_custom_output => \&custom_global_output,
                closure_custom_perfdata => \&custom_global_perfdata,
            }
        }
    ];
    $self->{maps_counters}->{metric} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'display' } ],
                threshold_use => 'value',
                closure_custom_calc => \&custom_metric_calc,
                closure_custom_output => \&custom_metric_output,
                closure_custom_perfdata => \&custom_metric_perfdata,
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
                                  "format-metric:s"             => { name => 'format_metric', default => 'Metric %s value is %s%s' },
                                  "host-filter:s"               => { name => 'host_filter' },
                                  "service-filter:s"            => { name => 'service_filter' },
                                  "metric-filter:s"             => { name => 'metric_filter' },
                                  "aggregation:s"               => { name => 'aggregation' },
                                  "custom-global:s"             => { name => 'custom_global' },
                                  "custom-unit:s"               => { name => 'custom_unit' },
                                  "change-bytes"                => { name => 'change_bytes' },
                                  "absolute"                    => { name => 'absolute' },
                                  "warning:s"                   => { name => 'warning' },
                                  "critical:s"                  => { name => 'critical' },
                                  "perfdata-global-label"       => { name => 'perfdata_global_label', default => 'computed' },
                                  "perfdata-separator:s"        => { name => 'perfdata_separator', default => '#' },
                                  "perfdata-name:s"             => { name => 'perfdata_name', default => 'value' },
                                  "perfdata-unit:s"             => { name => 'perfdata_unit', default => 'unit'},
                                  "perfdata-min:s"              => { name => 'perfdata_min'},
                                  "perfdata-max:s"              => { name => 'perfdata_max'},
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

}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    my $value = 'NaN';
    my $query = "SELECT index_data.host_name, index_data.service_description, metrics.metric_name, metrics.current_value FROM centreon_storage.index_data, centreon_storage.metrics WHERE index_data.id = metrics.index_id ";
    $query .= "AND index_data.service_description LIKE '" . $self->{option_results}->{service_filter} . "'" if defined($self->{option_results}->{service_filter});
    $query .= "AND index_data.host_name LIKE '" . $self->{option_results}->{host_filter} . "'" if defined($self->{option_results}->{host_filter});
    $query .= "AND metrics.metric_name LIKE '" . $self->{option_results}->{metric_filter} . "'" if defined($self->{option_results}->{metric_filter});
    $self->{sql}->query(query => $query);

    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $m_name = $row->{host_name}.$self->{option_results}->{perfdata_separator}.$row->{service_description}.$self->{option_results}->{perfdata_separator}.$row->{metric_name};
        $self->{metrics}->{selected_value}{$m_name} = $row->{current_value};

        push (@{$self->{metrics}->{selected_value}{all}}, $row->{current_value});
        $self->{metric}->{$m_name} = { value => $row->{current_value},
                                       display => $m_name };
    }

    $value = sprintf("%2.f", min(@{$self->{metrics}->{selected_value}{all}})) if ($self->{option_results}->{aggregation} eq 'min');
    $value = sprintf("%2.f", max(@{$self->{metrics}->{selected_value}{all}})) if ($self->{option_results}->{aggregation} eq 'max');
    $value = sprintf("%2.f", sum(@{$self->{metrics}->{selected_value}{all}})/scalar @{$self->{metrics}->{selected_value}{all}}) if ($self->{option_results}->{aggregation} eq 'avg');

    $self->{global} = { computed => $value };

}

1;

__END__

=head1 MODE

=over 8

=back

=cut

