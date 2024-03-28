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

package os::linux::exporter::mode::interface;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::common::monitoring::openmetrics::scrape;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'Status : ' . $self->{result_values}->{opstatus};
    if (defined($self->{instance_mode}->{option_results}->{add_duplex_status})) {
        $msg .= ' (duplex: ' . $self->{result_values}->{duplexstatus} . ')';
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{duplexstatus} = $options{new_datas}->{$self->{instance} . '_duplexstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(
            label => 'warning-' . $self->{thlabel},
            total => $self->{result_values}->{speed},
            cast_int => 1
        );
        $critical = $self->{perfdata}->get_perfdata_for_output(
            label => 'critical-' . $self->{thlabel},
            total => $self->{result_values}->{speed},
            cast_int => 1
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(
            label => 'warning-' . $self->{thlabel}
        );
        $critical = $self->{perfdata}->get_perfdata_for_output(
            label => 'critical-' . $self->{thlabel}
        );
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
            unit => 'b/s',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0,
            max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{traffic_prct},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{traffic_per_seconds},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{traffic_counter},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
                ]
            );
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'Traffic %s : %s/s (%s)',
            $self->{result_values}->{label_output},
            $traffic_value . $traffic_unit,
            defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{speed} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_speed} };

    my $diff_traffic = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_bytes} } -
        $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_bytes} });
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_bytes} };
    $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 /
        $self->{result_values}->{speed};

    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    $self->{result_values}->{display} = $options{new_datas}->{ $self->{instance} . '_display' };

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
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'deltaps') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/persecond/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => '/s',
            instances => $self->{result_values}->{display},
            value => sprintf('%.2f', $self->{result_values}->{used_ps}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0
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
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{prct},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
                ]
        );
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'deltaps') {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{used_ps},
            threshold => [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
            ]
        );
    } else {
        $exit = $self->{perfdata}->threshold_check(
            value => $self->{result_values}->{used},
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

    if ($self->{instance_mode}->{option_results}->{units_errors} eq 'deltaps') {
        return sprintf(
            'Packets %s : %.2f/s (%.2f%% - %s on %s)',
                $self->{result_values}->{label_output},
                $self->{result_values}->{used_ps},
                $self->{result_values}->{prct},
                $self->{result_values}->{used},
                $self->{result_values}->{total}
        );
    }

    return sprintf(
        'Packets %s : %.2f%% (%s on %s)',
            $self->{result_values}->{label_output},
            $self->{result_values}->{prct},
            $self->{result_values}->{used},
            $self->{result_values}->{total}
    );
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    my $errors = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_packets} };
    my $errors_diff = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_packets} } - 
        $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_packets} });
    my $total = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_total} };
    my $total_diff = ($options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_total} } - 
        $options{old_datas}->{ $self->{instance} . '_' . $options{extra_options}->{label_total} });

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
    } elsif ($self->{instance_mode}->{option_results}->{units_errors} eq 'deltaps') {
        $self->{result_values}->{prct} = $errors_diff * 100 / $total_diff if ($total_diff > 0);
        $self->{result_values}->{used} = $errors_diff;
        $self->{result_values}->{used_ps} = $errors_diff / $options{delta_time};
    } else {
        $self->{result_values}->{prct} = $errors * 100 / $total if ($total > 0);
        $self->{result_values}->{used} = $errors;
        $self->{result_values}->{total} = $total;
    }

    $self->{result_values}->{label_output} = $options{extra_options}->{label_output};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub custom_speed_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_node_network_speed_bytes'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters_status {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{interfaces}}, 
        {
            filter => 'add_status',
            label => 'status',
            type => 2,
            warning_default => $self->default_warning_status(),
            critical_default => $self->default_critical_status(),
            set => {
                key_values => [
                    { name => 'opstatus' },
                    { name => 'duplexstatus' },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ;
}

sub set_counters_traffic {
    my ($self, %options) = @_;

    return if ($self->{no_traffic} != 0 && $self->{no_set_traffic} != 0);

    push @{$self->{maps_counters}->{interfaces}},
        {
            filter => 'add_traffic',
            label => 'traffic-in',
            nlabel => 'interface.traffic.in.bitspersecond',
            set => {
                key_values => [
                    { name => 'node_network_receive_bytes_total', diff => 1 },
                    { name => 'node_network_speed_bytes_in' },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => {
                    label_bytes => 'node_network_receive_bytes_total',
                    label_speed => 'node_network_speed_bytes_in',
                    label_output => 'In'
                },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        {
            filter => 'add_traffic',
            label => 'traffic-out',
            nlabel => 'interface.traffic.out.bitspersecond',
            set => {
                key_values => [
                    { name => 'node_network_transmit_bytes_total', diff => 1 },
                    { name => 'node_network_speed_bytes_out' },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_traffic_calc'),
                closure_custom_calc_extra_options => {
                    label_bytes => 'node_network_transmit_bytes_total',
                    label_speed => 'node_network_speed_bytes_out',
                    label_output => 'Out'
                },
                closure_custom_output => $self->can('custom_traffic_output'),
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ;
}

sub set_counters_errors {
    my ($self, %options) = @_;

    return if ($self->{no_errors} != 0 && $self->{no_set_errors} != 0);

    push @{$self->{maps_counters}->{interfaces}},
        {
            filter => 'add_errors',
            label => 'in-discard', 
            nlabel => 'interface.packets.in.discard.count',
            set => {
                key_values => [
                    { name => 'node_network_receive_drop_total', diff => 1 },
                    { name => 'node_network_receive_packets_total', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => {
                    label_packets => 'node_network_receive_drop_total',
                    label_total => 'node_network_receive_packets_total',
                    label_output => 'In Discard'
                },
                closure_custom_output => $self->can('custom_errors_output'),
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        {
            filter => 'add_errors',
            label => 'in-error', 
            nlabel => 'interface.packets.in.error.count',
            set => {
                key_values => [
                    { name => 'node_network_receive_errs_total', diff => 1 },
                    { name => 'node_network_receive_packets_total', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => {
                    label_packets => 'node_network_receive_errs_total',
                    label_total => 'node_network_receive_packets_total',
                    label_output => 'In Error'
                },
                closure_custom_output => $self->can('custom_errors_output'),
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        {
            filter => 'add_errors',
            label => 'out-discard', 
            nlabel => 'interface.packets.in.discard.count',
            set => {
                key_values => [
                    { name => 'node_network_transmit_drop_total', diff => 1 },
                    { name => 'node_network_transmit_packets_total', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => {
                    label_packets => 'node_network_transmit_drop_total',
                    label_total => 'node_network_transmit_packets_total',
                    label_output => 'Out Discard'
                },
                closure_custom_output => $self->can('custom_errors_output'),
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        {
            filter => 'add_errors',
            label => 'out-error', 
            nlabel => 'interface.packets.in.error.count',
            set => {
                key_values => [
                    { name => 'node_network_transmit_errs_total', diff => 1 },
                    { name => 'node_network_transmit_packets_total', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => {
                    label_packets => 'node_network_transmit_errs_total',
                    label_total => 'node_network_transmit_packets_total',
                    label_output => 'Out Error'
                },
                closure_custom_output => $self->can('custom_errors_output'),
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ;
}

sub set_counters_speed {
    my ($self, %options) = @_;

    return if ($self->{no_speed} != 0 && $self->{no_set_speed} != 0);

    push @{$self->{maps_counters}->{interfaces}},
        {
            filter => 'add_speed',
            label => 'speed',
            nlabel => 'interface.speed.bitspersecond',
            set => {
                key_values => [
                    { name => 'node_network_speed_bytes' },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_speed_calc'),
                output_template => 'Speed : %s %s/s',
                output_error_template => 'Speed : %s %s/s',
                output_change_bytes => 2,
                output_use => 'speed',
                threshold_use => 'speed',
                perfdatas => [
                    {
                        label => 'speed',
                        value => 'speed',
                        template => '%s',
                        unit => 'b/s',
                        min => 0,
                        label_extra_instance => 1,
                        instance_use => 'display'
                    }
                ]
            }
        }
    ;
}

sub set_counters_volume {
    my ($self, %options) = @_;

    return if ($self->{no_volume} != 0 && $self->{no_set_volume} != 0);

    push @{$self->{maps_counters}->{interfaces}},
        {
            filter => 'add_volume', 
            label => 'in-volume',
            nlabel => 'interface.volume.in.bytes',
            set => {
                key_values => [
                    { name => 'node_network_receive_bytes_total', diff => 1 },
                    { name => 'display' }
                ],
                output_template => 'Volume In : %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    {
                        label => 'volume_in',
                        value => 'node_network_receive_bytes_total',
                        template => '%s',
                        unit => 'B',
                        min => 0,
                        label_extra_instance => 1,
                        instance_use => 'display'
                    }
                ]
            }
        },
        {
            filter => 'add_volume', 
            label => 'out-volume',
            nlabel => 'interface.volume.out.bytes',
            set => {
                key_values => [
                    { name => 'node_network_transmit_bytes_total', diff => 1 },
                    { name => 'display' }
                ],
                output_template => 'Volume Out : %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    {
                        label => 'volume_out',
                        value => 'node_network_transmit_bytes_total',
                        template => '%s',
                        unit => 'B',
                        min => 0,
                        label_extra_instance => 1,
                        instance_use => 'display'
                    }
                ]
            }
        }
    ;
}

sub skip_interface {
    my ($self, %options) = @_;

    return ($self->{checking} =~ /errors|traffic|status|volume/ ? 0 : 1);
}

sub skip_counters {
    my ($self, %options) = @_;

    return (defined($self->{option_results}->{$options{filter}})) ? 0 : 1;
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Interface '%s' ",
            $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'interfaces',
            type => 1,
            cb_init => 'skip_interface',
            cb_init_counters => 'skip_counters',
            cb_prefix_output => 'prefix_interface_output',
            message_multiple => 'All interfaces are ok',
            skipped_code => { -10 => 1 }
        },
    ];

    foreach (('traffic', 'errors', 'speed', 'volume')) {
        $self->{'no_' . $_} = defined($options{'no_' . $_}) && $options{'no_' . $_} =~ /^[01]$/ ? $options{'no_' . $_} : 0;
        $self->{'no_set_' . $_} = defined($options{'no_set_' . $_}) && $options{'no_set_' . $_} =~ /^[01]$/ ? $options{'no_set_' . $_} : 0;
    }

    $self->{maps_counters} = { interfaces => [] } if (!defined($self->{maps_counters}));
    $self->set_counters_status();
    $self->set_counters_traffic();
    $self->set_counters_errors();
    $self->set_counters_speed();
    $self->set_counters_volume();
}

sub default_warning_status {
    my ($self, %options) = @_;

    return '';
}

sub default_critical_status {
    my ($self, %options) = @_;

    return '%{opstatus} ne "up"';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'interface:s'       => { name => 'interface' },
        'add-status'        => { name => 'add_status' },
        'add-duplex-status' => { name => 'add_duplex_status' },
        'units-traffic:s'   => { name => 'units_traffic', default => 'percent_delta' },
        'units-errors:s'    => { name => 'units_errors', default => 'percent_delta' },
        'speed:s'           => { name => 'speed' },
        'speed-in:s'        => { name => 'speed_in' },
        'speed-out:s'       => { name => 'speed_out' },
    });
    if ($self->{no_traffic} == 0) {
        $options{options}->add_options(arguments => { 'add-traffic' => { name => 'add_traffic' } });
    }
    if ($self->{no_errors} == 0) {
        $options{options}->add_options(arguments => { 'add-errors' => { name => 'add_errors' } });
    }
    if ($self->{no_speed} == 0) {
        $options{options}->add_options(arguments => { 'add-speed' => { name => 'add_speed' } });
    }
    if ($self->{no_volume} == 0) {
        $options{options}->add_options(arguments => { 'add-volume' => { name => 'add_volume' } });
    }

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{add_traffic})) {
        $self->{option_results}->{units_traffic} = 'percent_delta'
            if (!defined($self->{option_results}->{units_traffic}) ||
                $self->{option_results}->{units_traffic} eq '' ||
                $self->{option_results}->{units_traffic} eq '%');
        $self->{option_results}->{units_traffic} = 'bps' if ($self->{option_results}->{units_traffic} eq 'absolute'); # compat
        if ($self->{option_results}->{units_traffic} !~ /^(?:percent_delta|bps|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-traffic.');
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{add_errors})) {
        $self->{option_results}->{units_errors} = 'percent_delta'
            if (!defined($self->{option_results}->{units_errors}) ||
                $self->{option_results}->{units_errors} eq '' ||
                $self->{option_results}->{units_errors} eq '%');
        $self->{option_results}->{units_errors} = 'delta' if ($self->{option_results}->{units_errors} eq 'absolute'); # compat
        if ($self->{option_results}->{units_errors} !~ /^(?:percent|percent_delta|delta|deltaps|counter)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong option --units-errors.');
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{add_speed}) &&
        ((defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') ||
        (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '') ||
        (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne ''))) {
        $self->{output}->add_option_msg(short_msg => 'Cannot use option --add-speed with --speed, --speed-in or --speed-out options.');
        $self->{output}->option_exit();
    }
    
    # If no options, we set status
    if (!defined($self->{option_results}->{add_status}) && !defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors}) && !defined($self->{option_results}->{add_speed}) &&
        !defined($self->{option_results}->{add_volume})) {
        $self->{option_results}->{add_status} = 1;
    }
    $self->{checking} = '';
    foreach (('add_status', 'add_traffic', 'add_errors', 'add_speed', 'add_volume')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{interfaces} = {};

    $self->{cache_name} = 'exporter_' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all'));

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'node_network_info|node_network_receive|node_network_transmit|node_network_speed_bytes',
        %options
    );

    # node_network_info{address="00:50:56:93:27:e9",broadcast="ff:ff:ff:ff:ff:ff",device="ens192",duplex="full",ifalias="",operstate="up"} 1
    # node_network_receive_bytes_total{device="ens192"} 6.488096021e+09
    # node_network_receive_compressed_total{device="ens192"} 0
    # node_network_receive_drop_total{device="ens192"} 200
    # node_network_receive_errs_total{device="ens192"} 0
    # node_network_receive_fifo_total{device="ens192"} 0
    # node_network_receive_frame_total{device="ens192"} 0
    # node_network_receive_multicast_total{device="ens192"} 25339
    # node_network_receive_packets_total{device="ens192"} 5.580605e+06
    # node_network_speed_bytes{device="ens192"} 1.25e+09
    # node_network_transmit_bytes_total{device="ens192"} 3.524060718e+09
    # node_network_transmit_carrier_total{device="ens192"} 0
    # node_network_transmit_colls_total{device="ens192"} 0
    # node_network_transmit_compressed_total{device="ens192"} 0
    # node_network_transmit_drop_total{device="ens192"} 0
    # node_network_transmit_errs_total{device="ens192"} 0
    # node_network_transmit_fifo_total{device="ens192"} 0
    # node_network_transmit_packets_total{device="ens192"} 7.324806e+06
    # node_network_transmit_queue_length{device="ens192"} 1000

    foreach my $metric (keys %{$raw_metrics}) {
        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{interface}) && $data->{dimensions}->{device} !~ /$self->{option_results}->{interface}/i);

            $self->{interfaces}->{$data->{dimensions}->{device}}->{$metric} = $data->{value};
            $self->{interfaces}->{$data->{dimensions}->{device}}->{$metric} *= 8 if ($metric =~ /bytes/);
            $self->{interfaces}->{$data->{dimensions}->{device}}->{display} = $data->{dimensions}->{device};

            if ($metric =~ /node_network_info/) {
                $self->{interfaces}->{$data->{dimensions}->{device}}->{duplexstatus} = $data->{dimensions}->{duplex};
                $self->{interfaces}->{$data->{dimensions}->{device}}->{opstatus} = $data->{dimensions}->{operstate};
            }
    
            if ($metric =~ /node_network_speed_bytes/) {
                $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_in} = $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes};
                $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_out} = $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes};

                if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
                    $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes} = $self->{option_results}->{speed} * 1000000;
                    $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_in} = $self->{option_results}->{speed} * 1000000;
                    $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_out} = $self->{option_results}->{speed} * 1000000;
                }
                $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
                $self->{interfaces}->{$data->{dimensions}->{device}}->{node_network_speed_bytes_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
            }
        }
    }

    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interfaces found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check interfaces status, traffic, packets error/discard, speed and volume.

=over 8

=item B<--interface> 

Specify which interface to monitor. Can be a regex.

Default: all interfaces are monitored.

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta')
(Can be: 'percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta')
(Can be: 'percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{opstatus} ne "up"').
You can use the following variables: %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-volume', 'out-volume', 'speed' (b/s).

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=back

=cut