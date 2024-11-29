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

package network::juniper::common::junos::api::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{opstatus} . ' (admin: ' . $self->{result_values}->{admstatus} . ')';
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            instances => $self->{result_values}->{display},
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => sprintf('%d', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'traffic %s: %s/s (%s)',
        $self->{result_values}->{label}, $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}
sub custom_traffic_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) / 
        $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref} };

    $self->{result_values}->{traffic_per_seconds} = sprintf('%d', $self->{result_values}->{traffic_per_seconds});

    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} ne '' && 
        $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_errors_perfdata {
    my ($self, %options) = @_;

    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;

        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => '%',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => sprintf('%.2f', $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => 100
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0,
            max => $self->{result_values}->{total}
        );
    }
}

sub custom_errors_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;

    return sprintf(
        'packets %s: %.2f%% (%s on %s)',
        $self->{result_values}->{label},
        $self->{result_values}->{prct},
        $self->{result_values}->{used},
        $self->{result_values}->{total}
    );
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    my $errors = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} };
    my $errors_diff = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} } 
        -  $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} };
    my $total = $options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'};
    my $total_diff = $options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'}
        - $options{old_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'};

    $errors_diff = sprintf('%d', $errors_diff);
    $total_diff = sprintf('%d', $total_diff);
    $self->{result_values}->{prct} = 0;
    $self->{result_values}->{used} = $errors_diff;
    $self->{result_values}->{total} = $total_diff;
    if ($self->{instance_mode}->{option_results}->{units_errors} eq 'percent_delta') {
        $self->{result_values}->{prct} = $errors_diff * 100 / $total_diff if ($total_diff > 0);
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'percent') {
        $self->{result_values}->{prct} = $errors * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $errors;
        $self->{result_values}->{total} = $total;
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'delta') {
        $self->{result_values}->{prct} = $errors_diff * 100 / $total_diff if ($total_diff > 0);
        $self->{result_values}->{used} = $errors_diff;
    } else {
        $self->{result_values}->{prct} = $errors * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $errors;
        $self->{result_values}->{total} = $total;
    }

    if (defined($options{extra_options}->{label})) {
        $self->{result_values}->{label} = $options{extra_options}->{label};
    } else {
        $self->{result_values}->{label} = $options{extra_options}->{label_ref1} . ' ' . $options{extra_options}->{label_ref2};
    }

    $self->{result_values}->{label1} = $options{extra_options}->{label_ref1};
    $self->{result_values}->{label2} = $options{extra_options}->{label_ref2};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub skip_counters {
    my ($self, %options) = @_;

    return (defined($self->{option_results}->{$options{filter}})) ? 0 : 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', cb_init_counters => 'skip_counters', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{interfaces} = [
         {
            label => 'status',
            filter => 'add_status',
            type => 2,
            critical_default => '%{admstatus} eq "up" and %{opstatus} ne "up"',
            set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'in-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'out-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'in-discard', filter => 'add_errors', nlabel => 'interface.packets.in.discard.count', set => {
                key_values => [ { name => 'indiscard', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets in discard: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'in-error', filter => 'add_errors', nlabel => 'interface.packets.in.error.count', set => {
                key_values => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets in error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-discard', filter => 'add_errors', nlabel => 'interface.packets.out.discard.count', set => {
                key_values => [ { name => 'outdiscard', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets out discard: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-error', filter => 'add_errors', nlabel => 'interface.packets.out.error.count', set => {
                key_values => [ { name => 'outerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets out error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'input-power', filter => 'add_optical', nlabel => 'interface.input.power.dbm', set => {
                key_values => [ { name => 'inputPowerDbm' }, { name => 'display' } ],
                output_template => 'input power: %s dBm',
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(
                        value => $self->{result_values}->{inputPowerDbm},
                        threshold => [
                            {
                                label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}, 
                                exit_litteral => 'critical'
                            },
                            {
                                label => 'warning-'. $self->{thlabel} . '-' . $self->{instance},
                                exit_litteral => 'warning'
                            }
                        ]
                    );
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'dBm',
                        instances => $self->{result_values}->{display},
                        value => $self->{result_values}->{inputPowerDbm},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                        min => 0
                    );
                }
            }
        },
        { label => 'bias-current', filter => 'add_optical', nlabel => 'interface.bias.current.milliampere', set => {
                key_values => [ { name => 'biasCurrent' }, { name => 'display' } ],
                output_template => 'bias current: %s mA',
                perfdatas => [
                    { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'outputPowerDbm' }, { name => 'display' } ],
                output_template => 'output power: %s dBm',
                closure_custom_threshold_check => sub {
                    my ($self, %options) = @_;

                    return $self->{perfdata}->threshold_check(
                        value => $self->{result_values}->{outputPowerDbm},
                        threshold => [
                            {
                                label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}, 
                                exit_litteral => 'critical'
                            },
                            {
                                label => 'warning-'. $self->{thlabel} . '-' . $self->{instance},
                                exit_litteral => 'warning'
                            }
                        ]
                    );
                },
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'dBm',
                        instances => $self->{result_values}->{display},
                        value => $self->{result_values}->{outputPowerDbm},
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                        min => 0
                    );
                }
            }
        },
        { label => 'module-temperature', filter => 'add_optical', nlabel => 'interface.module.temperature.celsius', set => {
                key_values => [ { name => 'moduleTemperature' }, { name => 'display' } ],
                output_template => 'module temperature: %.2f C',
                perfdatas => [
                    { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-use:s'        => { name => 'filter_use' },
        'display-use:s'       => { name => 'display_use' },
        'add-status'          => { name => 'add_status' },
        'add-traffic'         => { name => 'add_traffic' },
        'add-errors'          => { name => 'add_errors' },
        'add-optical'         => { name => 'add_optical' },
        'filter-interface:s'  => { name => 'filter_interface' },
        'exclude-interface:s' => { name => 'exclude_interface' },
        'units-traffic:s'     => { name => 'units_traffic', default => 'percent_delta' },
        'units-errors:s'      => { name => 'units_errors', default => 'percent_delta' },
        'speed:s'             => { name => 'speed' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # If no options, we set add-status
    if (!defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_status}) &&
        !defined($self->{option_results}->{add_optical}) &&
        !defined($self->{option_results}->{add_errors})) {
        $self->{option_results}->{add_status} = 1;
    }

    $self->{checking} = '';
    foreach (('add_status', 'add_errors', 'add_traffic', 'add_optical')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }

    if (!defined($self->{option_results}->{filter_use}) || $self->{option_results}->{filter_use} eq '') {
        $self->{option_results}->{filter_use} = 'name';
    }
    if ($self->{option_results}->{filter_use} !~ /name|descr/) {
        $self->{output}->add_option_msg(short_msg => "--filter-use must be 'name' or 'descr'");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{display_use}) || $self->{option_results}->{display_use} eq '') {
        $self->{option_results}->{display_use} = 'name';
    }
    if ($self->{option_results}->{display_use} !~ /name|descr/) {
        $self->{output}->add_option_msg(short_msg => "--display-use must be 'name' or 'descr'");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
        if ($self->{option_results}->{speed} !~ /^[0-9]+(\.[0-9]+){0,1}$/) {
            $self->{output}->add_option_msg(short_msg => "Speed must be a positive number '" . $self->{option_results}->{speed} . "' (can be a float also).");
            $self->{output}->option_exit();
        } else {
            $self->{option_results}->{speed} *= 1000000;
        }
    }

    if (defined($self->{option_results}->{add_traffic})) {
        $self->{option_results}->{units_traffic} = 'percent_delta'
            if (!defined($self->{option_results}->{units_traffic}) ||
                $self->{option_results}->{units_traffic} eq '' ||
                $self->{option_results}->{units_traffic} eq '%');
        if ($self->{option_results}->{units_traffic} !~ /^(?:percent|percent_delta|bps|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-traffic.');
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{add_errors})) {
        $self->{option_results}->{units_errors} = 'percent_delta'
            if (!defined($self->{option_results}->{units_errors}) ||
                $self->{option_results}->{units_errors} eq '' ||
                $self->{option_results}->{units_errors} eq '%');
        if ($self->{option_results}->{units_errors} !~ /^(?:percent|percent_delta|delta|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-errors.');
            $self->{output}->option_exit();
        }
    }
}

sub do_selection_interface {
    my ($self, %options) = @_;

    return if (
        !defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_status}) &&
        !defined($self->{option_results}->{add_errors})
    );

    my $results = $options{custom}->get_interface_infos();

    $self->{interfaces} = {};
    foreach (@$results) {
        next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
            $_->{ $self->{option_results}->{filter_use} } !~ /$self->{option_results}->{filter_interface}/);
        next if (defined($self->{option_results}->{exclude_interface}) && $self->{option_results}->{exclude_interface} ne '' &&
            $_->{ $self->{option_results}->{filter_use} } =~ /$self->{option_results}->{exclude_interface}/);

        $self->{interfaces}->{ $_->{name} } = {
            display => $_->{ $self->{option_results}->{display_use} },
            speed_in => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{speed},
            speed_out => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{speed},
            opstatus => $_->{opstatus},
            admstatus => $_->{admstatus},
            in => $_->{in},
            out => $_->{out},
            inerror => $_->{inErrors},
            outerror => $_->{outErrors},
            indiscard => $_->{inDiscards},
            outdiscard => $_->{outDiscards},
            total_in_packets => $_->{inPkts},
            total_out_packets => $_->{outPkts}
        };
    }
}

sub do_selection_interface_optical {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $results = $options{custom}->get_interface_optical_infos();
    foreach (@$results) {
        next if ((defined($self->{option_results}->{add_traffic}) || defined($self->{option_results}->{add_status}))
            && !defined($self->{interfaces}->{ $_->{name} }));
        
        # only --add-optical option
        if (!defined($self->{interfaces}->{ $_->{name} })) {
            next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
                $_->{name} !~ /$self->{option_results}->{filter_interface}/);
            next if (defined($self->{option_results}->{exclude_interface}) && $self->{option_results}->{exclude_interface} ne '' &&
                $_->{name} =~ /$self->{option_results}->{exclude_interface}/);

            $self->{interfaces}->{ $_->{name} } = { display => $_->{name} };
        }

        $self->{interfaces}->{ $_->{name} }->{biasCurrent} = $_->{biasCurrent};
        $self->{interfaces}->{ $_->{name} }->{moduleTemperature} = $_->{moduleTemperature};

        if (defined($_->{outputPowerDbm})) {
            $self->{interfaces}->{ $_->{name} }->{outputPowerDbm} = $_->{outputPowerDbm};
            my ($warn_val, $crit_val) = ('', '');

            if ((!defined($self->{option_results}->{'warning-output-power'}) || $self->{option_results}->{'warning-output-power'} eq '') &&
                (!defined($self->{option_results}->{'critical-output-power'}) || $self->{option_results}->{'critical-output-power'} eq '') &&
                (!defined($self->{option_results}->{'warning-instance-interface-output-power-dbm'}) || $self->{option_results}->{'warning-instance-interface-output-power-dbm'} eq '') &&
                (!defined($self->{option_results}->{'critical-instance-interface-output-power-dbm'}) || $self->{option_results}->{'critical-instance-interface-output-power-dbm'} eq '')) {
                $crit_val = $_->{outputPowerDbmLowAlarmCrit} . ':'
                    if (defined($_->{outputPowerDbmLowAlarmCrit}) && $_->{outputPowerDbmLowAlarmCrit} != 0);
                $crit_val .= $_->{outputPowerDbmHighAlarmCrit}
                    if (defined($_->{outputPowerDbmHighAlarmCrit}) && $_->{outputPowerDbmHighAlarmCrit} != 0);
                $self->{perfdata}->threshold_validate(label => 'critical-instance-interface-output-power-dbm-' . $_->{name}, value => $crit_val);

                $warn_val = $_->{outputPowerDbmLowAlarmWarn} . ':'
                    if (defined($_->{outputPowerDbmLowAlarmWarn}) && $_->{outputPowerDbmLowAlarmWarn} != 0);
                $warn_val .= $_->{outputPowerDbmHighAlarmWarn}
                    if (defined($_->{outputPowerDbmHighAlarmWarn}) && $_->{outputPowerDbmHighAlarmWarn} != 0);
                $self->{perfdata}->threshold_validate(label => 'warning-instance-interface-output-power-dbm-' . $_->{name}, value => $warn_val);
            }
        }

        if (defined($_->{inputPowerDbm})) {
            $self->{interfaces}->{ $_->{name} }->{inputPowerDbm} = $_->{inputPowerDbm};
            my ($warn_val, $crit_val) = ('', '');

            if ((!defined($self->{option_results}->{'warning-input-power'}) || $self->{option_results}->{'warning-input-power'} eq '') &&
                (!defined($self->{option_results}->{'critical-input-power'}) || $self->{option_results}->{'critical-input-power'} eq '') &&
                (!defined($self->{option_results}->{'warning-instance-interface-input-power-dbm'}) || $self->{option_results}->{'warning-instance-interface-input-power-dbm'} eq '') &&
                (!defined($self->{option_results}->{'critical-instance-interface-input-power-dbm'}) || $self->{option_results}->{'critical-instance-interface-input-power-dbm'} eq '')) {
                $crit_val = $_->{inputPowerDbmLowAlarmCrit} . ':'
                    if (defined($_->{inputPowerDbmLowAlarmCrit}) && $_->{inputPowerDbmLowAlarmCrit} != 0);
                $crit_val .= $_->{inputPowerDbmHighAlarmCrit}
                    if (defined($_->{inputPowerDbmHighAlarmCrit}) && $_->{inputPowerDbmHighAlarmCrit} != 0);
                $self->{perfdata}->threshold_validate(label => 'critical-instance-interface-input-power-dbm-' . $_->{name}, value => $crit_val);

                $warn_val = $_->{inputPowerDbmLowAlarmWarn} . ':'
                    if (defined($_->{inputPowerDbmLowAlarmWarn}) && $_->{inputPowerDbmLowAlarmWarn} != 0);
                $warn_val .= $_->{inputPowerDbmHighAlarmWarn}
                    if (defined($_->{inputPowerDbmHighAlarmWarn}) && $_->{inputPowerDbmHighAlarmWarn} != 0);
                $self->{perfdata}->threshold_validate(label => 'warning-instance-interface-input-power-dbm-' . $_->{name}, value => $warn_val);
            }
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->do_selection_interface(custom => $options{custom});
    $self->do_selection_interface_optical(custom => $options{custom});
    
    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'juniper_api_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : 'all') . '_' .
            (defined($self->{option_results}->{filter_interface}) ? $self->{option_results}->{filter_interface} : 'all') . '_' .
            $self->{checking}
        );
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-status>

Check interface status.

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-optical>

Check interface optical.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'input-power' (dBm), 'bias-current' (mA), 'output-power' (dBm), 'module-temperature' (C).

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'counter').

=item B<--filter-use>

Define the value to be used to filter interfaces (default: name) (values: name, descr).

=item B<--display-use>

Define the value that will be used to name the interfaces (default: name) (values: name, descr).

=item B<--filter-interface>

Filter interface name (regexp can be used).

=item B<--exclude-interface>

Exclude interface name (regexp can be used).

=item B<--speed>

Set interface speed (in Mb).

=back

=cut
