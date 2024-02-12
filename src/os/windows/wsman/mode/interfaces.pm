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

package os::windows::wsman::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

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
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
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
        (($options{new_datas}->{$self->{instance} . '_Timestamp_Sys100NS'} - $options{old_datas}->{$self->{instance} . '_Timestamp_Sys100NS'}) / 
        $options{new_datas}->{$self->{instance} . '_Frequency_Sys100NS'});
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

##############
# Errors
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
    my $errors_diff = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} } -  $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2} }) /
        (($options{new_datas}->{$self->{instance} . '_Timestamp_Sys100NS'} - $options{old_datas}->{$self->{instance} . '_Timestamp_Sys100NS'}) /
        $options{new_datas}->{$self->{instance} . '_Frequency_Sys100NS'});
    my $total = $options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'};
    my $total_diff = ($options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'} - $options{old_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'}) /
        (($options{new_datas}->{$self->{instance} . '_Timestamp_Sys100NS'} - $options{old_datas}->{$self->{instance} . '_Timestamp_Sys100NS'}) /
        $options{new_datas}->{$self->{instance} . '_Frequency_Sys100NS'});

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
        { label => 'in-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', diff => 1 }, { name => 'Timestamp_Sys100NS' }, { name => 'Frequency_Sys100NS' }, { name => 'speed_in' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic in: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'out-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', diff => 1 }, { name => 'Timestamp_Sys100NS' }, { name => 'Frequency_Sys100NS' }, { name => 'speed_out' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'traffic out: %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'in-discard', filter => 'add_errors', nlabel => 'interface.packets.in.discard.count', set => {
                key_values => [ { name => 'indiscard', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'Frequency_Sys100NS' }, {  name => 'Timestamp_Sys100NS' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets in discard: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'in-error', filter => 'add_errors', nlabel => 'interface.packets.in.error.count', set => {
                key_values => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'Frequency_Sys100NS' }, {  name => 'Timestamp_Sys100NS' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets in error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-discard', filter => 'add_errors', nlabel => 'interface.packets.out.discard.count', set => {
                key_values => [ { name => 'outdiscard', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'Frequency_Sys100NS' }, {  name => 'Timestamp_Sys100NS' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets out discard: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-error', filter => 'add_errors', nlabel => 'interface.packets.out.error.count', set => {
                key_values => [ { name => 'outerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'Frequency_Sys100NS' }, {  name => 'Timestamp_Sys100NS' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'packets out error: %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-traffic'         => { name => 'add_traffic' },
        'add-errors'          => { name => 'add_errors' },
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

    # If no options, we set add-traffic
    if (!defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors})) {
        $self->{option_results}->{add_traffic} = 1;
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

sub do_selection {
    my ($self, %options) = @_;

    my $WQL = 'Select CurrentBandwidth,BytesReceivedPerSec,BytesSentPerSec,Name,Frequency_Sys100NS,OutputQueueLength,PacketsReceivedErrors,PacketsReceivedPerSec,PacketsSentPerSec,Timestamp_Sys100NS, PacketsOutboundErrors,PacketsReceivedDiscarded, PacketsOutboundDiscarded from Win32_PerfRawData_Tcpip_NetworkInterface';
    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'array'
    );

    #
    #'CLASS: Win32_PerfRawData_Tcpip_NetworkInterface
    #BytesReceivedPersec;BytesSentPersec;CurrentBandwidth;Frequency_Sys100NS;Name;OutputQueueLength;PacketsOutboundDiscarded;PacketsOutboundErrors;PacketsReceivedDiscarded;PacketsReceivedErrors;PacketsReceivedPersec;PacketsSentPersec;Timestamp_Sys100NS
    #7784631;2497355;1000000000;10000000;AWS PV Network Device _0;0;0;0;5;0;11351;7746;132869914560700000
    #
    $self->{interfaces} = {};
    foreach (@$results) {
        next if (defined($self->{option_results}->{filter_interface}) && $self->{option_results}->{filter_interface} ne '' &&
            $_->{Name} !~ /$self->{option_results}->{filter_interface}/);
         next if (defined($self->{option_results}->{exclude_interface}) && $self->{option_results}->{exclude_interface} ne '' &&
            $_->{Name} =~ /$self->{option_results}->{exclude_interface}/);

        $self->{interfaces}->{ $_->{Name} } = {
            display => $_->{Name},
            speed_in => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{CurrentBandwidth},
            speed_out => defined($self->{option_results}->{speed}) ? $self->{option_results}->{speed} : $_->{CurrentBandwidth},
            Frequency_Sys100NS => $_->{Frequency_Sys100NS},
            Timestamp_Sys100NS => $_->{Timestamp_Sys100NS},
            in => $_->{BytesReceivedPersec} * 8,
            out => $_->{BytesSentPersec} * 8,
            indiscard => $_->{PacketsReceivedDiscarded},
            inerror => $_->{PacketsReceivedErrors},
            outdiscard => $_->{PacketsOutboundDiscarded},
            outerror => $_->{PacketsOutboundErrors},
            total_out_packets => $_->{PacketsSentPersec},
            total_in_packets => $_->{PacketsReceivedPersec}
        };
    }
    
    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->do_selection(wsman => $options{wsman});
    $self->{cache_name} = 'windows_wsman_' . $options{wsman}->get_hostname() . '_' . $options{wsman}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_interface}) ? md5_hex($self->{option_results}->{filter_interface}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'counter').

=item B<--filter-interface>

Filter interface name (regexp can be used).

=item B<--exclude-interface>

Exclude interface name (regexp can be used).

=item B<--speed>

Set interface speed (in Mb).

=back

=cut
