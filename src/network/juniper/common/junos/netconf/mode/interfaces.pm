#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::interfaces;

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
            nlabel    => $nlabel,
            unit      => 'b',
            instances => $self->{result_values}->{display},
            value     => $self->{result_values}->{traffic_counter},
            warning   => $warning,
            critical  => $critical,
            min       => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel    => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value     => sprintf('%d', $self->{result_values}->{traffic_per_seconds}),
            warning   => $warning,
            critical  => $critical,
            min       => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value     =>
                                                   $self->{result_values}->{traffic_prct},
                                                   threshold =>
                                                   [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                     { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value     =>
                                                   $self->{result_values}->{traffic_per_seconds},
                                                   threshold =>
                                                   [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                     { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value     =>
                                                   $self->{result_values}->{traffic_counter},
                                                   threshold =>
                                                   [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                     { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
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

    $self->{result_values}->{traffic_per_seconds} = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}
                                                    - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}{label_ref}})
                                                    / $options{delta_time};
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
            nlabel    => $nlabel,
            unit      => '%',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value     => sprintf('%.2f', $self->{result_values}->{prct}),
            warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min       => 0,
            max       => 100
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel    => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value     => $self->{result_values}->{used},
            warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min       => 0,
            max       => $self->{result_values}->{total}
        );
    }
}

sub custom_errors_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_errors} =~ /percent/) {
        $exit = $self->{perfdata}->threshold_check(value     =>
                                                   $self->{result_values}->{prct},
                                                   threshold =>
                                                   [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                     { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value     =>
                                                   $self->{result_values}->{used},
                                                   threshold =>
                                                   [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                     { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s: %.2f%% (%s on %s)',
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
                      - $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} };
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
        $self->{result_values}->{label} = $options{extra_options}->{label_ref2};
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub interface_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking interface '%s'",
        $options{instance_value}->{display}
    );
}

sub prefix_packets_in_output {
    my ($self, %options) = @_;

    return 'packets in ';
}

sub prefix_packets_out_output {
    my ($self, %options) = @_;

    return 'packets out ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name               => 'interfaces', type => 3, cb_prefix_output => 'prefix_interface_output', cb_long_output => 'interface_long_output',
          indent_long_output => '    ', message_multiple => 'All interfaces are ok',
          group              => [
              { name => 'status', type => 0, skipped_code => { -10 => 1 } },
              { name => 'traffic', type => 0, skipped_code => { -10 => 1 } },
              { name => 'packets_in', type => 0, cb_prefix_output => 'prefix_packets_in_output', skipped_code => { -10 => 1 } },
              { name => 'packets_out', type => 0, cb_prefix_output => 'prefix_packets_out_output', skipped_code => { -10 => 1 } },
              { name => 'optical', type => 0, skipped_code => { -10 => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{admstatus} eq "up" and %{opstatus} ne "up"',
            set              => {
                key_values                     => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'in-traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
            key_values                     => [ { name => 'in', diff => 1 }, { name => 'speed_in' }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
            closure_custom_output          => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
            closure_custom_perfdata        => $self->can('custom_traffic_perfdata'),
            closure_custom_threshold_check => $self->can('custom_traffic_threshold')
        }
        },
        { label => 'out-traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
            key_values                     => [ { name => 'out', diff => 1 }, { name => 'speed_out' }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
            closure_custom_output          => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
            closure_custom_perfdata        => $self->can('custom_traffic_perfdata'),
            closure_custom_threshold_check => $self->can('custom_traffic_threshold')
        }
        }
    ];

    $self->{maps_counters}->{packets_in} = [
        { label => 'in-discard', nlabel => 'interface.packets.in.discard.count', set => {
            key_values                     => [ { name => 'indiscard', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'discard' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'discard: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-error', nlabel => 'interface.packets.in.error.count', set => {
            key_values                     => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'error: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-fcserror', nlabel => 'interface.packets.in.fcserror.count', set => {
            key_values                        => [ { name => 'infcserror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'fcs error', label_ref1 => 'in', label_ref2 => 'fcserror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'fcs error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-runts', nlabel => 'interface.packets.in.runts.count', set => {
            key_values                        => [ { name => 'inrunts', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'runts' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'runts: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-giant', nlabel => 'interface.packets.in.giant.count', set => {
            key_values                        => [ { name => 'ingiant', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'giant' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'giant: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-l3-incomplete', nlabel => 'interface.packets.in.l3incomplete.count', set => {
            key_values                        => [ { name => 'inl3incomplete', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'l3 incomplete', label_ref1 => 'in', label_ref2 => 'l3incomplete' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'l3 incomplete: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-fifo-error', nlabel => 'interface.packets.in.fifo.error.count', set => {
            key_values                        => [ { name => 'infifoerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'fifo error', label_ref1 => 'in', label_ref2 => 'fifoerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'fifo error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-l2-mismatch-timeout', nlabel => 'interface.packets.in.l2mismatch.timeout.count', set => {
            key_values                        => [ { name => 'inl2mismatchtimeout', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'l2 mismatch timeout', label_ref1 => 'in', label_ref2 => 'l2mismatchtimeout' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'l2 mismatch timeout: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-drop', nlabel => 'interface.packets.in.drop.count', set => {
            key_values                        => [ { name => 'indrop', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'drop' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'drop: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'in-resource-error', nlabel => 'interface.packets.in.resource.error.count', set => {
            key_values                        => [ { name => 'inresourceerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'resource error', label_ref1 => 'in', label_ref2 => 'resourceerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'resource error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        }
    ];

    $self->{maps_counters}->{packets_out} = [
        { label => 'out-discard', nlabel => 'interface.packets.out.discard.count', set => {
            key_values                     => [ { name => 'outdiscard', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'discard' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'discard: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-error', nlabel => 'interface.packets.out.error.count', set => {
            key_values                     => [ { name => 'outerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'error' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'error: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-drop', nlabel => 'interface.packets.out.drop.count', set => {
            key_values                     => [ { name => 'outdrop', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'drop' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'drop: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-carrier-transition', nlabel => 'interface.packets.out.carrier.transition.count', set => {
            key_values                        => [ { name => 'outcarriertransition', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'carrier transition', label_ref1 => 'out', label_ref2 => 'carriertransition' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'carrier transition: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-collision', nlabel => 'interface.packets.out.collision.count', set => {
            key_values                        => [ { name => 'outcollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'collision' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'collision: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-mtu-error', nlabel => 'interface.packets.out.mtu.error.count', set => {
            key_values                        => [ { name => 'outmtuerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'mtu error', label_ref1 => 'out', label_ref2 => 'mtuerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'mtu error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-aged', nlabel => 'interface.packets.out.aged.count', set => {
            key_values                        => [ { name => 'outaged', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'aged' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'packets out aged: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-hslink-crc-error', nlabel => 'interface.packets.out.hslink.crc.error.count', set => {
            key_values                        => [ { name => 'outhslinkcrcerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'hs link crc error', label_ref1 => 'out', label_ref2 => 'hslinkcrcerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'hs link crc error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-fifo-error', nlabel => 'interface.packets.out.fifo.error.count', set => {
            key_values                        => [ { name => 'outfifoerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'fifo error', label_ref1 => 'out', label_ref2 => 'fifoerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'fifo error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
        { label => 'out-resource-error', nlabel => 'interface.packets.out.resource.error.count', set => {
            key_values                        => [ { name => 'outresourceerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc               => $self->can('custom_errors_calc'),
            closure_custom_calc_extra_options => { label => 'resource error', label_ref1 => 'out', label_ref2 => 'resourceerror' },
            closure_custom_output             => $self->can('custom_errors_output'), output_error_template => 'resource error: %s',
            closure_custom_perfdata           => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check    => $self->can('custom_errors_threshold')
        }
        },
    ];

    $self->{maps_counters}->{optical} = [
        { label => 'input-power', nlabel => 'interface.input.power.dbm', set => {
            key_values                     => [ { name => 'inputPowerDbm' }, { name => 'display' } ],
            output_template                => 'input power: %s dBm',
            closure_custom_threshold_check => sub {
                my ($self, %options) = @_;

                return $self->{perfdata}->threshold_check(
                    value     => $self->{result_values}->{inputPowerDbm},
                    threshold => [
                        {
                            label         => 'critical-' . $self->{thlabel} . '-' . $self->{instance},
                            exit_litteral => 'critical'
                        },
                        {
                            label         => 'warning-' . $self->{thlabel} . '-' . $self->{instance},
                            exit_litteral => 'warning'
                        }
                    ]
                );
            },
            closure_custom_perfdata        => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'dBm',
                    instances => $self->{result_values}->{display},
                    value     => $self->{result_values}->{inputPowerDbm},
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                    min       => 0
                );
            }
        }
        },
        { label => 'bias-current', nlabel => 'interface.bias.current.milliampere', set => {
            key_values      => [ { name => 'biasCurrent' }, { name => 'display' } ],
            output_template => 'bias current: %s mA',
            perfdatas       => [
                { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'output-power', nlabel => 'interface.output.power.dbm', set => {
            key_values                     => [ { name => 'outputPowerDbm' }, { name => 'display' } ],
            output_template                => 'output power: %s dBm',
            closure_custom_threshold_check => sub {
                my ($self, %options) = @_;

                return $self->{perfdata}->threshold_check(
                    value     => $self->{result_values}->{outputPowerDbm},
                    threshold => [
                        {
                            label         => 'critical-' . $self->{thlabel} . '-' . $self->{instance},
                            exit_litteral => 'critical'
                        },
                        {
                            label         => 'warning-' . $self->{thlabel} . '-' . $self->{instance},
                            exit_litteral => 'warning'
                        }
                    ]
                );
            },
            closure_custom_perfdata        => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'dBm',
                    instances => $self->{result_values}->{display},
                    value     => $self->{result_values}->{outputPowerDbm},
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel} . '-' . $self->{instance}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel} . '-' . $self->{instance}),
                    min       => 0
                );
            }
        }
        },
        { label => 'module-temperature', nlabel => 'interface.module.temperature.celsius', set => {
            key_values      => [ { name => 'moduleTemperature' }, { name => 'display' } ],
            output_template => 'module temperature: %.2f C',
            perfdatas       => [
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
        'add-extra-errors'    => { name => 'add_extra_errors' },
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
        !defined($self->{option_results}->{add_errors}) &&
        !defined($self->{option_results}->{add_extra_errors})) {
        $self->{option_results}->{add_status} = 1;
    }

    $self->{checking} = '';
    foreach (('add_status', 'add_errors', 'add_extra_errors', 'add_traffic', 'add_optical')) {
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

    if (defined($self->{option_results}->{add_errors}) || defined($self->{option_results}->{add_extra_errors})) {
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
        !defined($self->{option_results}->{add_errors}) &&
        !defined($self->{option_results}->{add_extra_errors})
    );

    my $results = $options{custom}->get_interface_infos();

    $self->{interfaces} = {};
    foreach (@$results) {
        next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
                 $_->{ $self->{option_results}->{filter_use} } !~ /$self->{option_results}->{filter_interface}/);
        next if (defined($self->{option_results}->{exclude_interface}) && $self->{option_results}->{exclude_interface} ne '' &&
                 $_->{ $self->{option_results}->{filter_use} } =~ /$self->{option_results}->{exclude_interface}/);

        $self->{interfaces}->{ $_->{name} } = {
            display     => $_->{ $self->{option_results}->{display_use} },
            packets_in  => {
                display          => $_->{ $self->{option_results}->{display_use} },
                total_in_packets => $_->{inPkts}
            },
            packets_out => {
                display           => $_->{ $self->{option_results}->{display_use} },
                total_out_packets => $_->{outPkts}
            },
            optical     => {
                display => $_->{ $self->{option_results}->{display_use} },
            }
        };

        if (defined($self->{option_results}->{add_status})) {
            $self->{interfaces}->{ $_->{name} }->{status} = {
                display   => $_->{ $self->{option_results}->{display_use} },
                opstatus  => $_->{opstatus},
                admstatus => $_->{admstatus},
            };
        }

        if (defined($self->{option_results}->{add_traffic})) {
            $self->{interfaces}->{ $_->{name} }->{traffic} = {
                display   => $_->{ $self->{option_results}->{display_use} },
                in        => $_->{in},
                out       => $_->{out},
                speed_in  => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{speed},
                speed_out => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{speed},
            };
        };

        if (defined($self->{option_results}->{add_errors})) {
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{inerror} = $_->{'counter-in-input-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{indiscard} = $_->{'counter-in-input-discards'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outerror} = $_->{'counter-out-output-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outdiscard} = $_->{'counter-out-output-discards'};
        }

        if (defined($self->{option_results}->{add_extra_errors})) {
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{infcserror} = $_->{'counter-in-framing-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{inrunts} = $_->{'counter-in-input-runts'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{ingiant} = $_->{'counter-in-input-giants'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{inl3incomplete} = $_->{'counter-in-input-l3-incompletes'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{infifoerror} = $_->{'counter-in-input-fifo-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{inl2mismatchtimeout} = $_->{'counter-in-input-l2-mismatch-timeouts'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{inresourceerror} = $_->{'counter-in-input-resource-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_in}->{indrop} = $_->{'counter-in-input-drops'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outdrop} = $_->{'counter-out-output-drops'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outcarriertransition} = $_->{'counter-out-carrier-transitions'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outcollision} = $_->{'counter-out-output-collisions'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outmtuerror} = $_->{'counter-out-mtu-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outaged} = $_->{'counter-out-aged-packets'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outhslinkcrcerror} = $_->{'counter-out-hs-link-crc-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outfifoerror} = $_->{'counter-out-output-fifo-errors'};
            $self->{interfaces}->{ $_->{name} }->{packets_out}->{outresourceerror} = $_->{'counter-out-output-resource-errors'};
        }

        foreach my $label (keys %$_) {
            next if ($label !~ /^counter-(.*?)-/);

            $self->{interfaces}->{ $_->{name} }->{'packets_' . $1}->{$label} = $_->{$label};
        }
    }
}

sub do_selection_interface_optical {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $results = $options{custom}->get_interface_optical_infos();
    foreach (@$results) {
        next if (
            (
                defined($self->{option_results}->{add_traffic}) || defined($self->{option_results}->{add_status}) ||
                defined($self->{option_results}->{add_errors}) || defined($self->{option_results}->{add_extra_errors})
            )
            && !defined($self->{interfaces}->{ $_->{name} }));

        # only --add-optical option
        if (!defined($self->{interfaces}->{ $_->{name} })) {
            next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
                     $_->{name} !~ /$self->{option_results}->{filter_interface}/);
            next if (defined($self->{option_results}->{exclude_interface}) && $self->{option_results}->{exclude_interface} ne '' &&
                     $_->{name} =~ /$self->{option_results}->{exclude_interface}/);

            $self->{interfaces}->{ $_->{name} } = { display => $_->{name}, optical => { display => $_->{name} } };
        }

        $self->{interfaces}->{ $_->{name} }->{optical}->{biasCurrent} = $_->{biasCurrent};
        $self->{interfaces}->{ $_->{name} }->{optical}->{moduleTemperature} = $_->{moduleTemperature};

        if (defined($_->{outputPowerDbm})) {
            $self->{interfaces}->{ $_->{name} }->{optical}->{outputPowerDbm} = $_->{outputPowerDbm};
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
            $self->{interfaces}->{ $_->{name} }->{optical}->{inputPowerDbm} = $_->{inputPowerDbm};
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

=item B<--add-extra-errors>

Check interface detailed errors.

=item B<--add-optical>

Check interface optical.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{admstatus}>, C<%{opstatus}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{admstatus} eq "up" and %{opstatus} ne "up"'>).
You can use the following variables: C<%{admstatus}>, C<%{opstatus}>, C<%{display}>

=item B<--warning-bias-current>

Threshold in mA.

=item B<--critical-bias-current>

Threshold in mA.

=item B<--warning-in-discard>

Threshold.

=item B<--critical-in-discard>

Threshold.

=item B<--warning-in-drop>

Threshold.

=item B<--critical-in-drop>

Threshold.

=item B<--warning-in-error>

Threshold.

=item B<--critical-in-error>

Threshold.

=item B<--warning-in-fcserror>

Threshold.

=item B<--critical-in-fcserror>

Threshold.

=item B<--warning-in-fifo-error>

Threshold.

=item B<--critical-in-fifo-error>

Threshold.

=item B<--warning-in-giant>

Threshold.

=item B<--critical-in-giant>

Threshold.

=item B<--warning-in-l2-mismatch-timeout>

Threshold.

=item B<--critical-in-l2-mismatch-timeout>

Threshold.

=item B<--warning-in-l3-incomplete>

Threshold.

=item B<--critical-in-l3-incomplete>

Threshold.

=item B<--warning-in-resource-error>

Threshold.

=item B<--critical-in-resource-error>

Threshold.

=item B<--warning-in-runts>

Threshold.

=item B<--critical-in-runts>

Threshold.

=item B<--warning-in-traffic>

Threshold.

=item B<--critical-in-traffic>

Threshold.

=item B<--warning-input-power>

Threshold in dBm.

=item B<--critical-input-power>

Threshold in dBm.

=item B<--warning-module-temperature>

Threshold in C.

=item B<--critical-module-temperature>

Threshold in C.

=item B<--warning-out-aged>

Threshold.

=item B<--critical-out-aged>

Threshold.

=item B<--warning-out-carrier-transition>

Threshold.

=item B<--critical-out-carrier-transition>

Threshold.

=item B<--warning-out-collision>

Threshold.

=item B<--critical-out-collision>

Threshold.

=item B<--warning-out-discard>

Threshold.

=item B<--critical-out-discard>

Threshold.

=item B<--warning-out-drop>

Threshold.

=item B<--critical-out-drop>

Threshold.

=item B<--warning-out-error>

Threshold.

=item B<--critical-out-error>

Threshold.

=item B<--warning-out-fifo-error>

Threshold.

=item B<--critical-out-fifo-error>

Threshold.

=item B<--warning-out-hslink-crc-error>

Threshold.

=item B<--critical-out-hslink-crc-error>

Threshold.

=item B<--warning-out-mtu-error>

Threshold.

=item B<--critical-out-mtu-error>

Threshold.

=item B<--warning-out-resource-error>

Threshold.

=item B<--critical-out-resource-error>

Threshold.

=item B<--warning-out-traffic>

Threshold.

=item B<--critical-out-traffic>

Threshold.

=item B<--warning-output-power>

Threshold in dBm.

=item B<--critical-output-power>

Threshold in dBm.

=item B<--units-traffic>

Units of thresholds for the traffic (default: C<percent_delta>) (C<percent_delta>, C<bps>, C<counter>).

=item B<--units-errors>

Units of thresholds for errors/discards (default: C<percent_delta>) (C<percent_delta>, C<percent>, C<delta>, C<counter>).

=item B<--filter-use>

Define the value to be used to filter interfaces (default: C<name>) (values: C<name>, C<descr>).

=item B<--display-use>

Define the value that will be used to name the interfaces (default: C<name>) (values: C<name>, C<descr>).

=item B<--filter-interface>

Filter interface name (regexp can be used).

=item B<--exclude-interface>

Exclude interface name (regexp can be used).

=item B<--speed>

Set interface speed (in Mb).

=back

=cut
