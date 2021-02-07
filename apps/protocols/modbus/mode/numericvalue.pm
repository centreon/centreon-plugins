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

package apps::protocols::modbus::mode::numericvalue;

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
    my ($change_bytes_metric_selection);
    if (defined($config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}) &&
        defined($config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}->{change_bytes})) { 
        $change_bytes_metric_selection = $config_data->{$elem}->{$self->{result_values}->{instance}}->{formatting}->{change_bytes};
    }

    if ((defined($change_bytes_metric_selection) && $change_bytes_metric_selection) || 
        ($config_data->{formatting}->{change_bytes} && !defined($change_bytes_metric_selection))) {
        ($self->{result_values}->{value}, $self->{result_values}->{unit}) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value});
    }
    return 0;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(label => $self->{result_values}->{instance},
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

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{perfdata_value},
                                                  threshold => [ { label => $label_crit, exit_litteral => 'critical' },
                                                                 { label => $label_warn, exit_litteral => 'warning' } ]);
    return $exit;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [];

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

    $options{options}->add_options(arguments =>
                                {
                                  "config:s"    => { name => 'config' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{config}) || $self->{option_results}->{config} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please define --config option");
        $self->{output}->option_exit();
    }
    
    $config_data = $self->parse_json_config(config => $self->{option_results}->{config});

    if (!defined($config_data->{selection})) {
        $self->{output}->add_option_msg(short_msg => "Config_error: there is no selection section in your JSON configuration !");
        $self->{output}->option_exit();
    }

    $config_data->{formatting}->{printf_msg} = "Metric '%s' value is %d" if (!exists($config_data->{formatting}->{printf_msg}));
    $config_data->{formatting}->{printf_metric_value} = "%d" if (!exists($config_data->{formatting}->{printf_metric_value}));
    $config_data->{formatting}->{custom_message_global} = "Global metrics are OK" if (!exists($config_data->{formatting}->{custom_message_global}));
    $config_data->{formatting}->{custom_message_metric} = "All metrics are OK" if (!exists($config_data->{formatting}->{custom_message_metric}));
    $config_data->{formatting}->{cannonical_separator} = "#" if (!exists($config_data->{formatting}->{cannonical_separator}));
    $config_data->{formatting}->{change_bytes} = 0 if (!exists($config_data->{formatting}->{change_bytes}));
}

sub parse_json_config {
    my ($self, %options) = @_;
    my ($data, $json_text);

    if (-f $options{config} and -r $options{config}) {
        $json_text = do {
            local $/;
            my $fh;
            if (!open($fh, "<:encoding(UTF-8)", $options{config})) {
                $self->{output}->add_option_msg(short_msg => "Can't open file $options{config}: $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    } else {
        $json_text = $options{config};
    }

    eval {
        $data = decode_json($json_text);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json config file: $@");
        $self->{output}->option_exit();
    }
    return $data
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{metrics} = {};
    $self->{vmetrics} = {};
    $self->{metric} = {};
    $self->{global} = {};

    if (defined($config_data->{virtualcurve})) {
        push @{$self->{maps_counters_type}}, {
            name => 'global', type => 1, message_separator => $config_data->{formatting}->{message_separator}, message_multiple => $config_data->{formatting}->{custom_message_global},
        };
    }

    if (defined($config_data->{selection})) {
        my $pushed = 0;
        foreach my $id (keys %{$config_data->{selection}}) {
            next if (!defined($config_data->{selection}->{$id}->{address}));
            my $results = $options{custom}->read_objects(address => $config_data->{selection}->{$id}->{address},
                unit => $config_data->{selection}->{$id}->{unit}, quantity => $config_data->{selection}->{$id}->{quantity},
                type => $config_data->{selection}->{$id}->{type});
            my $i = 0;
            my $extra_num = 0;
            if (scalar(@$results) > 1) {
                $extra_num = 1;
            }
            foreach (@{$results}) {
                my $metric_key = $id;
                $metric_key .= '.' . $i if ($extra_num == 1);
                $self->{metrics}->{$metric_key} = { name => $metric_key };
                $self->{metrics}->{$metric_key}->{display_name} = $metric_key;
                $self->{metrics}->{$metric_key}->{current} = $_;
                $self->{metrics}->{$metric_key}->{unit} = defined($config_data->{selection}->{$id}->{unit_name}) ? $config_data->{selection}->{$id}->{unit_name} : '';
                $self->{metrics}->{$metric_key}->{min} = defined($config_data->{selection}->{$id}->{min}) ? $config_data->{selection}->{$id}->{min} : '';
                $self->{metrics}->{$metric_key}->{max} = defined($config_data->{selection}->{$id}->{max}) ? $config_data->{selection}->{$id}->{max} : '';
                $self->{metrics}->{$metric_key}->{display} = (defined($config_data->{selection}->{$id}->{display}) && $config_data->{selection}->{$id}->{display}) ? 1 : 0;
                $i++;
                
                
                if ($self->{metrics}->{$metric_key}->{display} == 1) {
                    $self->{metric}->{$metric_key} = {
                        display => $self->{metrics}->{$metric_key}->{display_name},
                        type => 'unique',
                        unit => $self->{metrics}->{$metric_key}->{unit},
                        value => $self->{metrics}->{$metric_key}->{current},
                        min => $self->{metrics}->{$metric_key}->{min},
                        max => $self->{metrics}->{$metric_key}->{max} };
                    push @{$self->{maps_counters_type}}, {
                        name => 'metric', type => 1, message_separator => $config_data->{formatting}->{message_separator}, message_multiple => $config_data->{formatting}->{custom_message_metric},
                    } if ($pushed == 0);
                    $pushed = 1;
                }
            }
        }
    }

    foreach my $vcurve (keys %{$config_data->{virtualcurve}}) {
        foreach my $metric (keys %{$self->{metrics}}) {
            $self->{vmetrics}->{$vcurve}->{values} = [] if (!defined($self->{vmetrics}->{$vcurve}));
            if (defined($config_data->{virtualcurve}->{$vcurve}->{pattern}) && $config_data->{virtualcurve}->{$vcurve}->{pattern} ne '') {
                push (@{$self->{vmetrics}->{$vcurve}->{values}}, $self->{metrics}->{$metric}->{current}) if ($self->{metrics}->{$metric}->{name} =~ /$config_data->{virtualcurve}{$vcurve}->{pattern}/);
            } else {
                push (@{$self->{vmetrics}->{$vcurve}->{values}}, $self->{metrics}->{$metric}->{current});
            }
        }

        next if (!defined($self->{vmetrics}->{$vcurve}->{values}) || scalar(@{$self->{vmetrics}->{$vcurve}->{values}}) == 0);
        
        $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf($config_data->{formatting}->{printf_metric_value},
                                                                sum(@{$self->{vmetrics}->{$vcurve}->{values}}) / scalar(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'avg');
        $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf($config_data->{formatting}->{printf_metric_value},
                                                                sum(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'sum');
        $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf($config_data->{formatting}->{printf_metric_value},
                                                                min(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'min');
        $self->{vmetrics}->{$vcurve}->{aggregated_value} = sprintf($config_data->{formatting}->{printf_metric_value},
                                                                max(@{$self->{vmetrics}->{$vcurve}->{values}})) if ($config_data->{virtualcurve}->{$vcurve}->{aggregation} eq 'max');
        $self->{vmetrics}->{$vcurve}->{aggregated_value} = eval "$self->{vmetrics}->{$vcurve}->{aggregated_value} $config_data->{virtualcurve}->{$vcurve}->{custom}" if (defined($config_data->{virtualcurve}->{$vcurve}->{custom}));

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

    if (scalar(keys %{$self->{metric}}) <= 0 && scalar(keys %{$self->{global}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No metrics returned - are your selection correct ?");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Mode to play with modbus metrics
e.g: display two curves of different service on the same graph
e.g: aggregate multiple metrics (min,max,avg,sum) or custom operation

=over 8

=item B<--config>

Specify the config (can be a file or a json string directly).

=item B<--filter-counters>

Filter some counter (can be 'unique' or 'global')
Useless, if you use selection/filter but not
global/virtual curves

=item B<--warning-*>

Warning threshold (can be 'unique' or 'global')
(Override config if set)

=item B<--critical-*>

Critical threshold (can be 'unique' or 'global')
(Override config if set)

=back

=cut
