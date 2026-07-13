#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);


sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
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
        $exit = $self->{perfdata}->threshold_check(
            value     => $self->{result_values}->{prct},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
    } else {
        $exit = $self->{perfdata}->threshold_check(
            value     => $self->{result_values}->{used},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name               => 'interfaces', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_interface_output', cb_long_output => 'interface_long_output',
          indent_long_output => '    ', message_multiple => 'All interfaces are ok',
          group              => [
              { name => 'status', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE => 1 } },
              { name => 'traffic', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE => 1 } },
              { name => 'packets_in', type => COUNTER_MULTIPLE_INSTANCE, cb_prefix_output => 'prefix_packets_in_output', skipped_code => { NO_VALUE => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{state} !~ /up|N\/A/',
            set              => {
                key_values                     => [ { name => 'state' }, { name => 'display' } ],
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
        { label => 'in-error', nlabel => 'interface.packets.in.error.count', set => {
            key_values                     => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
            closure_custom_output          => $self->can('custom_errors_output'), output_error_template => 'error: %s',
            closure_custom_perfdata        => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold')
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
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-interface-name:s'  => { name => 'include_interface_name',  default => '' },
        'exclude-interface-name:s'  => { name => 'exclude_interface_name',  default => '' },
        'add-status'         => { name => 'add_status' },
        'add-traffic'        => { name => 'add_traffic' },
        'add-errors'         => { name => 'add_errors' },
        'units-traffic:s'    => { name => 'units_traffic', default => 'percent_delta' },
        'units-errors:s'     => { name => 'units_errors', default => 'percent_delta' },
        'speed:s'            => { name => 'speed' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    # If no options, we set add-status
    if (!defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors}) &&
        !defined($self->{option_results}->{add_status})) {
        $self->{option_results}->{add_status} = 1;
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

    $self->{checking} = '';
    foreach ('add_status', 'add_errors', 'add_traffic') {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><interface>all</interface></show>',
        ForceArray => ['entry']
    );

    foreach my $interface ((@{$result->{hw}->{entry}}, @{$result->{ifnet}->{entry}})) {
        next if is_excluded($interface->{name}, $self->{option_results}->{include_interface_name}, $self->{option_results}->{exclude_inteface_name});

        my $speed_in = defined($interface->{speed}) && $interface->{speed} =~ /^([0-9]+)$/ ? $interface->{speed} * 1000000 : '';
        my $speed_out = defined($interface->{speed}) && $interface->{speed} =~ /^([0-9]+)$/ ? $interface->{speed} * 1000000 : '';

        $self->{interfaces}->{ $interface->{name} } = { display => $interface->{name} };

        if (defined($self->{option_results}->{add_status})) {
            $self->{interfaces}->{ $interface->{name} }->{status} = {
                display => $interface->{name},
                state => defined($interface->{state}) ? $interface->{state} : 'N/A',
            };
        }
        if (defined($self->{option_results}->{add_traffic})) {
            $self->{interfaces}->{ $interface->{name} }->{traffic} = {
                display => $interface->{name},
                speed_in => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $speed_in,
                speed_out => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $speed_out
            }
        }
        if (defined($self->{option_results}->{add_errors})) {
            $self->{interfaces}->{ $interface->{name} }->{packets_in}  = {
                display => $interface->{name}
            };
        };
    }

    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }

    $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><counter><interface>all</interface></counter></show>',
        ForceArray => ['entry']
    );

    foreach my $interface ((@{$result->{hw}->{entry}}, @{$result->{ifnet}->{ifnet}->{entry}})) {
        next if (!defined($self->{interfaces}->{ $interface->{name} }));

        if (defined($self->{option_results}->{add_traffic})) {
            $self->{interfaces}->{ $interface->{name} }->{traffic}->{in} = $interface->{ibytes};
            $self->{interfaces}->{ $interface->{name} }->{traffic}->{out} = $interface->{obytes};
        }

        if (defined($self->{option_results}->{add_errors})) {
            $self->{interfaces}->{ $interface->{name} }->{packets_in}->{total_in_packets} = $interface->{ipackets};
            $self->{interfaces}->{ $interface->{name} }->{packets_in}->{inerror} = $interface->{ierrors};
            $self->{interfaces}->{ $interface->{name} }->{packets_in}->{indrop} = $interface->{idrops};
        }
    }

    $self->{cache_name} = 'paloalto_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{include_interface_name}) ? $self->{option_results}->{include_interface_name} : '') . '_' .
            (defined($self->{option_results}->{exclude_interface_name}) ? $self->{option_results}->{exclude_interface_name} : '') . '_' .
            $self->{checking}
        );
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--include-interface-name>

Include interface names (regexp).

=item B<--exclude-interface-name>

Exclude interface names (regexp).

=item B<--add-status>

Check interface status.

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{state}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{state} !~ /up|N\/A/'>).
You can use the following variables: C<%{state}>, C<%{display}>

=item B<--warning-in-drop>

Threshold.

=item B<--critical-in-drop>

Threshold.

=item B<--warning-in-error>

Threshold.

=item B<--critical-in-error>

Threshold.

=item B<--warning-in-traffic>

Threshold.

=item B<--critical-in-traffic>

Threshold.

=item B<--warning-out-traffic>

Threshold.

=item B<--critical-out-traffic>

Threshold.

=item B<--units-traffic>

Units of thresholds for the traffic (default: C<percent_delta>) (C<percent_delta>, C<bps>, C<counter>).

=item B<--units-errors>

Units of thresholds for errors/discards (default: C<percent_delta>) (C<percent_delta>, C<percent>, C<delta>, C<counter>).

=item B<--speed>

Set interface speed (in Mb).

=back

=cut
