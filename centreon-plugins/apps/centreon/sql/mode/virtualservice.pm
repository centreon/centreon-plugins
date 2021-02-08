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

package apps::centreon::sql::mode::virtualservice;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use List::Util qw (min max sum);
use JSON;
my $config_data;

sub custom_metric_output {
    my ($self, %options) = @_;
    my $msg;
    my $message;

    if ($self->{result_values}->{type} eq 'unique') {
        if (defined($config_data->{selection}->{$self->{result_values}->{instance}}->{formatting}->{printf_var}) && defined($config_data->{selection}->{$self->{result_values}->{instance}}->{formatting}->{printf_msg})) {
            eval {
                local $SIG{__WARN__} = sub { $message = $_[0]; };
                local $SIG{__DIE__} = sub { $message = $_[0]; };
                $msg = sprintf("$config_data->{selection}->{$self->{result_values}->{instance}}->{formatting}->{printf_msg}",
                                eval "$config_data->{selection}->{$self->{result_values}->{instance}}->{formatting}->{printf_var}");
            };
        } elsif (defined($config_data->{filters}->{formatting}->{printf_var}) && defined($config_data->{filters}->{formatting}->{printf_msg})) {
            eval {
                local $SIG{__WARN__} = sub { $message = $_[0]; };
                local $SIG{__DIE__} = sub { $message = $_[0]; };
                $msg = sprintf("$config_data->{filters}->{formatting}->{printf_msg}", eval "$config_data->{filters}->{formatting}->{printf_var}");
            };
        } else {
            $msg = sprintf("Metric '%s' value is '%s'", $self->{result_values}->{instance}, $self->{result_values}->{value});
        }
    }

    if ($self->{result_values}->{type} eq 'global') {
        if (defined($config_data->{virtualcurve}->{$self->{result_values}->{instance}}->{formatting})) {
            eval {
                local $SIG{__WARN__} = sub { $message = $_[0]; };
                local $SIG{__DIE__} = sub { $message = $_[0]; };
                $msg = sprintf("$config_data->{virtualcurve}->{$self->{result_values}->{instance}}->{formatting}->{printf_msg}",
                                eval "$config_data->{virtualcurve}->{$self->{result_values}->{instance}}->{formatting}->{printf_var}");
            };
        } elsif (defined($config_data->{formatting}->{printf_var}) && defined($config_data->{formatting}->{printf_msg})) {
            eval {
                local $SIG{__WARN__} = sub { $message = $_[0]; };
                local $SIG{__DIE__} = sub { $message = $_[0]; };
                $msg = sprintf("$config_data->{formatting}->{printf_msg}", eval "$config_data->{formatting}->{printf_var}");
            };
        } else {
            $msg = sprintf("Metric '%s' value is '%s'", $self->{result_values}->{instance}, $self->{result_values}->{value});
        }
    }

    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'printf expression problem: ' . $message);
        $self->{output}->option_exit();
    }

    return $msg;

}

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{unit} = $options{new_datas}->{$self->{instance} . '_unit'};
    $self->{result_values}->{instance} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{perfdata_value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{perfdata_unit} = $options{new_datas}->{$self->{instance} . '_unit'};
    $self->{result_values}->{min} = $options{new_datas}->{$self->{instance} . '_min'};
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_max'};

    my $elem = $self->{result_values}->{type} eq 'unique' ? 'selection' : 'virtualcurve';

    my ($change_bytes, $change_bytes_network) = (0, 0);
    if (defined($config_data->{filters}->{formatting}) && defined($config_data->{filters}->{formatting}->{change_bytes})) {
        $change_bytes = $config_data->{filters}->{formatting}->{change_bytes};
        $change_bytes_network = $config_data->{filters}->{formatting}->{change_bytes_network};
    } elsif (defined($config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}) && defined($config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}->{change_bytes})) { 
        $change_bytes = $config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}->{change_bytes};
        $change_bytes_network = $config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}->{change_bytes_network};
    } elsif (defined($config_data->{formatting}) && defined($config_data->{formatting}->{change_bytes})) {
        $change_bytes = $config_data->{formatting}->{change_bytes};
        $change_bytes_network = $config_data->{formatting}->{change_bytes_network};
    }

    if ($change_bytes) {
        ($self->{result_values}->{value}, $self->{result_values}->{unit}) = $self->{perfdata}->change_bytes(
            value => $self->{result_values}->{value},
            network => defined($change_bytes_network) && $change_bytes_network ? 1 : undef
        );
    }

    return 0;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{instance},
        value => $self->{result_values}->{perfdata_value},
        warning => $self->{perfdata}->get_perfdata_for_output(label => ($self->{result_values}->{type} eq 'unique') ? 'warning-metric' : 'warning-global-'.$self->{result_values}->{instance}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => ($self->{result_values}->{type} eq 'unique') ? 'critical-metric' : 'critical-global-'.$self->{result_values}->{instance}),
        unit => $self->{result_values}->{perfdata_unit},
        min => $self->{result_values}->{min},
        max => $self->{result_values}->{max},
    );
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $label_warn = ($self->{result_values}->{type} eq 'unique') ? 'warning-metric' : 'warning-global-'.$self->{result_values}->{instance};
    my $label_crit = ($self->{result_values}->{type} eq 'unique') ? 'critical-metric' : 'critical-global-'.$self->{result_values}->{instance};

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{perfdata_value},
        threshold => [
            { label => $label_crit, exit_litteral => 'critical' },
            { label => $label_warn, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
    ];

    $self->{maps_counters}->{global} = [
        { label => 'global', set => {
                key_values => [ { name => 'value' }, { name => 'display' }, { name => 'type' }, { name => 'unit' }, { name => 'min' }, { name => 'max' }  ],
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
            }
        }
    ];

    $self->{maps_counters}->{metric} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'display' }, { name => 'type' }, { name => 'unit' }, { name => 'min' }, { name => 'max' } ],
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
        'config-file:s' => { name => 'config_file' },
        'json-data:s'   => { name => 'json_data' },
        'database:s'    => { name => 'database' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{config_file}) && !defined($self->{option_results}->{json_data})) {
        $self->{output}->add_option_msg(short_msg => "Please define --config-file or --json-data option");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{config_file}) && $self->{option_results}->{config_file} ne '') {
        $config_data = $self->parse_json_config(config => $self->{option_results}->{config_file});
    } elsif (defined($self->{option_results}->{json_data}) && $self->{option_results}->{json_data} ne  '') {
        $config_data = $self->parse_json_config(config => $self->{option_results}->{json_data});
    } else {
        $self->{output}->add_option_msg(short_msg => "Can't find plugin configuration file / Cannot read from --json-data option");
        $self->{output}->option_exit();
    }

    if (!exists($config_data->{selection}) && !exists($config_data->{filters})) {
        $self->{output}->add_option_msg(short_msg => "Config_error: there is neither filters nor selection section in your JSON configuration !");
        $self->{output}->option_exit();
    }

    $config_data->{formatting}->{printf_msg} = "Metric '%s' value is %d" if (!exists($config_data->{formatting}->{printf_msg}));
    $config_data->{formatting}->{printf_metric_value} = "%d" if (!exists($config_data->{formatting}->{printf_metric_value}));
    $config_data->{formatting}->{custom_message_global} = "Global metrics are OK" if (!exists($config_data->{formatting}->{custom_message_global}));
    $config_data->{formatting}->{custom_message_metric} = "All metrics are OK" if (!exists($config_data->{formatting}->{custom_message_metric}));
    $config_data->{formatting}->{cannonical_separator} = "#" if (!exists($config_data->{formatting}->{cannonical_separator}));
    $config_data->{formatting}->{change_bytes} = 0 if (!exists($config_data->{formatting}->{change_bytes}));
    $config_data->{formatting}->{change_bytes_network} = 0 if (!exists($config_data->{formatting}->{change_bytes_network}));

    $self->{option_results}->{database} = 
        (defined($self->{option_results}->{database}) && $self->{option_results}->{database} ne '') ?
            $self->{option_results}->{database} . '.' : 'centreon_storage.';
}

sub parse_json_config {
    my ($self, %options) = @_;
    my $data;
    my $message;

    my $json_text = do {
       open(my $json_fh, "<:encoding(UTF-8)", $options{config})
         or die("Can't open \$filename\": $!\n");
         local $/;
         <$json_fh>
    };

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        $data = JSON->new->utf8->decode($json_text);
    };
    if ($message) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json config file: $message");
        $self->{output}->option_exit();
    }
    return $data
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{metrics} = {};
    $self->{vmetrics} = {};

    if (exists($config_data->{virtualcurve})) {
        push @{$self->{maps_counters_type}}, {
            name => 'global', type => 1, message_separator => $config_data->{formatting}->{message_separator}, message_multiple => $config_data->{formatting}->{custom_message_global},
        };
    }

    # Selection is prefered can't mix selection and sql matching
    if (exists($config_data->{selection})) {
        push @{$self->{maps_counters_type}}, {
            name => 'metric', type => 1, message_separator => $config_data->{formatting}->{message_separator}, message_multiple => $config_data->{formatting}->{custom_message_metric},
        };
        foreach my $id (keys %{$config_data->{selection}}) {
            my $query = "SELECT index_data.host_name, index_data.service_description, metrics.metric_name, metrics.current_value, metrics.unit_name, metrics.min, metrics.max ";
            $query .= "FROM $self->{option_results}->{database}index_data, $self->{option_results}->{database}metrics WHERE index_data.id = metrics.index_id ";
            $query .= "AND index_data.service_description = '" . $config_data->{selection}->{$id}->{service_name} . "'";
            $query .= "AND index_data.host_name = '" . $config_data->{selection}->{$id}->{host_name} . "'" ;
            $query .= "AND metrics.metric_name = '" . $config_data->{selection}->{$id}->{metric_name} . "'";
            $self->{sql}->query(query => $query);
            while ((my $row = $self->{sql}->fetchrow_hashref())) {
                my $metric_key = $id;
                $self->{metrics}->{$metric_key} = { name => $row->{metric_name} };
                $self->{metrics}->{$metric_key}->{display_name} = $id;
                $self->{metrics}->{$metric_key}->{current} = $row->{current_value};
                $self->{metrics}->{$metric_key}->{unit} = defined($row->{unit_name}) ? $row->{unit_name} : '';
                $self->{metrics}->{$metric_key}->{min} = defined($row->{min}) ? $row->{min} : '';
                $self->{metrics}->{$metric_key}->{max} = defined($row->{max}) ? $row->{max} : '';
                $self->{metrics}->{$metric_key}->{display} = (defined($config_data->{selection}->{$id}->{display}) && $config_data->{selection}->{$id}->{display}) ? 1 : 0;
            }
        }
    } elsif (exists($config_data->{filters})) {
        push @{$self->{maps_counters_type}}, {
            name => 'metric', type => 1, message_separator => $config_data->{formatting}->{message_separator}, message_multiple => $config_data->{formatting}->{custom_message_metric},
        };
        my $query = "SELECT index_data.host_name, index_data.service_description, metrics.metric_name, metrics.current_value, metrics.unit_name, metrics.min, metrics.max ";
        $query .= "FROM $self->{option_results}->{database}index_data, $self->{option_results}->{database}metrics, $self->{option_results}->{database}services WHERE index_data.id = metrics.index_id AND services.service_id = index_data.service_id AND services.host_id = index_data.host_id ";
        $query .= "AND index_data.service_description LIKE '" . $config_data->{filters}->{service} . "' " if (defined($config_data->{filters}->{service}) && ($config_data->{filters}->{service} ne ''));
        $query .= "AND index_data.host_name LIKE '" . $config_data->{filters}->{host} . "' " if (defined($config_data->{filters}->{host}) && ($config_data->{filters}->{host} ne ''));
        $query .= "AND metrics.metric_name LIKE '" . $config_data->{filters}->{metric} . "' " if (defined($config_data->{filters}->{metric}) && ($config_data->{filters}->{metric} ne ''));
        $query .= "AND services.enabled = '1'";
        $self->{sql}->query(query => $query);
        while ((my $row = $self->{sql}->fetchrow_hashref())) {
            my $metric_key = $row->{host_name}.$config_data->{formatting}->{cannonical_separator}.$row->{service_description}.$config_data->{formatting}->{cannonical_separator}.$row->{metric_name};
            $self->{metrics}->{$metric_key} = { display_name => $metric_key};
            $self->{metrics}->{$metric_key}->{name} = $row->{metric_name};
            $self->{metrics}->{$metric_key}->{current} = $row->{current_value};
            $self->{metrics}->{$metric_key}->{unit} = defined($row->{unit_name}) ? $row->{unit_name} : '';
            $self->{metrics}->{$metric_key}->{min} = defined($row->{min}) ? $row->{min} : '';
            $self->{metrics}->{$metric_key}->{max} = defined($row->{max}) ? $row->{max} : '';
            $self->{metrics}->{$metric_key}->{display} = (defined($config_data->{filters}->{display}) && $config_data->{filters}->{display}) ? 1 : 0;
        }
    }

    foreach my $metric (keys %{$self->{metrics}}) {
        foreach my $vcurve (keys %{$config_data->{virtualcurve}}) {
            $self->{vmetrics}->{$vcurve}->{values} = [] if (!defined($self->{vmetrics}->{$vcurve}->{values}));
            if (defined($config_data->{virtualcurve}->{$vcurve}->{pattern}) && $config_data->{virtualcurve}->{$vcurve}->{pattern} ne '') {
                push (@{$self->{vmetrics}->{$vcurve}->{values}}, $self->{metrics}->{$metric}->{current}) if $self->{metrics}->{$metric}->{name} =~ /$config_data->{virtualcurve}{$vcurve}->{pattern}/;
            } else {
                push (@{$self->{vmetrics}->{$vcurve}->{values}}, $self->{metrics}->{$metric}->{current});
            }

            next if (scalar(@{$self->{vmetrics}->{$vcurve}->{values}}) == 0);

            $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf(
                $config_data->{formatting}->{printf_metric_value},
                sum(@{$self->{vmetrics}->{$vcurve}->{values}}) / scalar(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'avg');
            $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf(
                $config_data->{formatting}->{printf_metric_value},
                sum(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'sum');
            $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf(
                $config_data->{formatting}->{printf_metric_value},
                min(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'min');
            $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf(
                $config_data->{formatting}->{printf_metric_value},
                max(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'max');

            if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'none') {
                $self->{vmetrics}->{$vcurve}->{aggregated_value} = ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'none' && defined($config_data->{virtualcurve}->{$vcurve}->{custom})) ?
                                                                eval "$config_data->{virtualcurve}->{$vcurve}->{custom}" :
                                                                eval "$self->{vmetrics}->{$vcurve}->{aggregated_value} $config_data->{virtualcurve}->{$vcurve}->{custom}";
            }

            $self->{vmetrics}->{$vcurve}->{unit} = (defined($config_data->{virtualcurve}->{$vcurve}->{unit})) ? $config_data->{virtualcurve}->{$vcurve}->{unit} : '';
            $self->{vmetrics}->{$vcurve}->{min} = (defined($config_data->{virtualcurve}->{$vcurve}->{min})) ? $config_data->{virtualcurve}->{$vcurve}->{min} : '';
            $self->{vmetrics}->{$vcurve}->{max} = (defined($config_data->{virtualcurve}->{$vcurve}->{max})) ? $config_data->{virtualcurve}->{$vcurve}->{max} : '';

            if (defined($self->{option_results}->{'warning-global'}) || defined($config_data->{virtualcurve}->{$vcurve}->{warning})) {
               $self->{perfdata}->threshold_validate(label => 'warning-global-' . $vcurve,
                                                     value => (defined($self->{option_results}->{'warning-global'})) ? $self->{option_results}->{'warning-global'} : $config_data->{virtualcurve}->{$vcurve}->{warning});
            }
            if (defined($self->{option_results}->{'critical-global'}) || defined($config_data->{virtualcurve}->{$vcurve}->{critical})) {
               $self->{perfdata}->threshold_validate(label => 'critical-global-' . $vcurve,
                                                     value => (defined($self->{option_results}->{'critical-global'})) ? $self->{option_results}->{'critical-global'} : $config_data->{virtualcurve}->{$vcurve}->{critical});
            }

            $self->{global}->{$vcurve} = {
                display => $vcurve,
                type => 'global',
                unit => $self->{vmetrics}->{$vcurve}->{unit},
                value => $self->{vmetrics}->{$vcurve}->{aggregated_value},
                min => $self->{vmetrics}->{$vcurve}->{min},
                max => $self->{vmetrics}->{$vcurve}->{max}
            };
        }

        $self->{metric}->{$metric} = {
            display => $self->{metrics}->{$metric}->{display_name},
            type => 'unique',
            unit => $self->{metrics}->{$metric}->{unit},
            value => $self->{metrics}->{$metric}->{current},
            min => $self->{metrics}->{$metric}->{min},
            max => $self->{metrics}->{$metric}->{max}
        } if ($self->{metrics}->{$metric}->{display} == 1);
    }

    if (scalar(keys %{$self->{metric}}) <= 0 && scalar(keys %{$self->{vmetrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics returned - are your selection/filters correct ?');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Mode to play with centreon metrics
e.g: display two curves of different service on the same graph
e.g: aggregate multiple metrics (min,max,avg,sum) or custom operation

=over 8

=item B<--database>

Specify the database (default: 'centreon_storage')

=item B<--config-file>

Specify the full path to a json config file

=item B<--json-data>

Specify the full path to a json config file

=item B<--filter-counters>

Filter some counter (can be 'unique' or 'global')
Useless, if you use selection/filter but not
global/virtual curves

=item B<--warning-*>

Warning threshold (can be 'unique' or 'global')
(Override config_file if set)

=item B<--critical-*>

Critical threshold (can be 'unique' or 'global')
(Override config_file if set)

=back

=cut
