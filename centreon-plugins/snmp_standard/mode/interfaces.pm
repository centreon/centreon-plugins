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

package snmp_standard::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

#########################
# Calc functions
#########################
sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{warning_status}") {
            $status = 'warning';
        }

        $self->{instance_mode}->{last_status} = 0;
        if (eval "$self->{instance_mode}->{check_status}") {
            $self->{instance_mode}->{last_status} = 1;
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'Status : ' . $self->{result_values}->{opstatus} . ' (admin: ' . $self->{result_values}->{admstatus} . ')';
    if (defined($self->{instance_mode}->{option_results}->{add_duplex_status})) {
        $msg .= ' (duplex: ' . $self->{result_values}->{duplexstatus} . ')';
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    $self->{result_values}->{duplexstatus} = $options{new_datas}->{$self->{instance} . '_duplexstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_cast_calc {
    my ($self, %options) = @_;

    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_cast'} ne $options{old_datas}->{$self->{instance} . '_mode_cast'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    my $diff_cast = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    my $total = $diff_cast
        + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}}) 
        + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}});

    if ($total == 0 && !defined($self->{instance_mode}->{option_results}->{no_skipped_counters})) {
        $self->{error_msg} = "skipped";
        return -2;
    }

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{$options{extra_options}->{label_ref} . '_prct'} = $total == 0 ? 0 : $diff_cast * 100 / $total;
    return 0;
}

##############
# Traffic
sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    if (defined($self->{instance_mode}->{option_results}->{nagvis_perfdata})) {
        $self->{result_values}->{traffic_per_seconds} /= 8;
        $self->{result_values}->{speed} /= 8 if (defined($self->{result_values}->{speed}));
    }

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }

    if (defined($self->{instance_mode}->{option_results}->{nagvis_perfdata})) {
        $self->{output}->perfdata_add(
            label => $self->{result_values}->{label},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    } else {
        $self->{output}->perfdata_add(
            label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
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
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    return sprintf(
        'Traffic %s : %s/s (%s)',
        ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_traffic'} ne $options{old_datas}->{$self->{instance} . '_mode_traffic'}) {
        $self->{error_msg} = 'buffer creation';
        return -2;
    }
  
    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    if ($diff_traffic == 0 && !defined($self->{instance_mode}->{option_results}->{no_skipped_counters})) {
        $self->{error_msg} = 'skipped';
        return -2;
    }

    $self->{result_values}->{traffic_per_seconds} = $diff_traffic / $options{delta_time};
    if (defined($options{new_datas}->{$self->{instance} . '_speed_' . $options{extra_options}->{label_ref}}) && 
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

    if ($self->{instance_mode}->{option_results}->{units_errors} eq '%') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/count$/percentage/;
        $self->{output}->perfdata_add(
            label => 'packets_' . $self->{result_values}->{label2} . '_' . $self->{result_values}->{label1}, unit => '%',
            nlabel => $nlabel,
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => sprintf("%.2f", $self->{result_values}->{prct}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
            min => 0, max => 100
        );
    } else {
        $self->{output}->perfdata_add(
            label => 'packets_' . $self->{result_values}->{label2} . '_' . $self->{result_values}->{label1},
            nlabel => $self->{nlabel},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{used},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
            min => 0, max => $self->{result_values}->{total}
        );
    }
}

sub custom_errors_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{units_errors} eq '%') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;

    return sprintf(
        'Packets %s : %.2f%% (%s)',
        $self->{result_values}->{label},
        $self->{result_values}->{prct}, $self->{result_values}->{used}
    );
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_cast'} ne $options{old_datas}->{$self->{instance} . '_mode_cast'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    my $diff = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2}} - 
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2}});
    my $total = ($options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'} - 
        $options{old_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'});
    if ($total == 0 && !defined($self->{instance_mode}->{option_results}->{no_skipped_counters})) {
        $self->{error_msg} = "skipped";
        return -2;
    }

    $self->{result_values}->{prct} = $total == 0 ? 0 : $diff * 100 / $total;
    $self->{result_values}->{used} = $diff;
    $self->{result_values}->{total} = $total;
    if (defined($options{extra_options}->{label})) {
        $self->{result_values}->{label} = $options{extra_options}->{label};
    } else {
        $self->{result_values}->{label} = ucfirst($options{extra_options}->{label_ref1}) . ' ' . ucfirst($options{extra_options}->{label_ref2});
    }
    $self->{result_values}->{label1} = $options{extra_options}->{label_ref1};
    $self->{result_values}->{label2} = $options{extra_options}->{label_ref2};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_speed_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_speed'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

#########################
# OIDs mapping functions
#########################

sub set_counters_global {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{global}}, 
        { label => 'total-port', filter => 'add_global', nlabel => 'total.interfaces.count', set => {
                key_values => [ { name => 'total_port' } ],
                output_template => 'Total port : %s', output_error_template => 'Total port : %s',
                output_use => 'total_port',  threshold_use => 'total_port',
                perfdatas => [
                    { label => 'total_port', value => 'total_port', template => '%s',
                      min => 0, max => 'total_port' }
                ]
            }
        },
        { label => 'global-admin-up', filter => 'add_global', nlabel => 'total.interfaces.admin.up.count', set => {
                key_values => [ { name => 'global_admin_up' }, { name => 'total_port' } ],
                output_template => 'AdminStatus Up : %s', output_error_template => 'AdminStatus Up : %s',
                output_use => 'global_admin_up',  threshold_use => 'global_admin_up',
                perfdatas => [
                    { label => 'total_admin_up', template => '%s', min => 0, max => 'total_port' }
                ]
            }
        },
        { label => 'total-admin-down', filter => 'add_global', nlabel => 'total.interfaces.admin.down.count', set => {
                key_values => [ { name => 'global_admin_down' }, { name => 'total_port' } ],
                output_template => 'AdminStatus Down : %s', output_error_template => 'AdminStatus Down : %s',
                output_use => 'global_admin_down',  threshold_use => 'global_admin_down',
                perfdatas => [
                    { label => 'total_admin_down', template => '%s', min => 0, max => 'total_port' }
                ]
            }
        },
        { label => 'total-oper-up', filter => 'add_global', nlabel => 'total.interfaces.operational.up.count', set => {
                key_values => [ { name => 'global_oper_up' }, { name => 'total_port' } ],
                output_template => 'OperStatus Up : %s', output_error_template => 'OperStatus Up : %s',
                output_use => 'global_oper_up',  threshold_use => 'global_oper_up',
                perfdatas => [
                    { label => 'total_oper_up', template => '%s', min => 0, max => 'total_port' }
                ]
            }
        },
        { label => 'total-oper-down', filter => 'add_global', nlabel => 'total.interfaces.operational.down.count', set => {
                key_values => [ { name => 'global_oper_down' }, { name => 'total_port' } ],
                output_template => 'OperStatus Down : %s', output_error_template => 'OperStatus Down : %s',
                output_use => 'global_oper_down',  threshold_use => 'global_oper_down',
                perfdatas => [
                    { label => 'global_oper_down', template => '%s', min => 0, max => 'total_port' }
                ]
            }
        }
    ;
}

sub set_counters_status {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{int}}, 
        { label => 'status', filter => 'add_status', threshold => 0, set => {
                key_values => $self->set_key_values_status(),
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output')
            }
        }
    ;
}

sub set_counters_traffic {
    my ($self, %options) = @_;

    return if ($self->{no_traffic} != 0 && $self->{no_set_traffic} != 0);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => $self->set_key_values_in_traffic(),
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'out-traffic', filter => 'add_traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => $self->set_key_values_out_traffic(),
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ;
}

sub set_counters_errors {
    my ($self, %options) = @_;

    return if ($self->{no_errors} != 0 && $self->{no_set_errors} != 0);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-discard', filter => 'add_errors', nlabel => 'interface.packets.in.discard.count', set => {
                key_values => [ { name => 'indiscard', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Discard : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'in-error', filter => 'add_errors', nlabel => 'interface.packets.in.error.count', set => {
                key_values => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-discard', filter => 'add_errors', nlabel => 'interface.packets.out.discard.count', set => {
                key_values => [ { name => 'outdiscard', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Discard : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-error', filter => 'add_errors', nlabel => 'interface.packets.out.error.count', set => {
                key_values => [ { name => 'outerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ;
}

sub set_counters_cast {
    my ($self, %options) = @_;

    return if ($self->{no_cast} != 0 && $self->{no_set_cast} != 0);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-ucast', filter => 'add_cast', nlabel => 'interface.packets.in.unicast.count', set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'iucast', total_ref1 => 'ibcast', total_ref2 => 'imcast' },
                output_template => 'In Ucast : %.2f %%', output_error_template => 'In Ucast : %s',
                output_use => 'iucast_prct',  threshold_use => 'iucast_prct',
                perfdatas => [
                    { value => 'iucast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'in-bcast', filter => 'add_cast', nlabel => 'interface.packets.in.broadcast.count', set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'ibcast', total_ref1 => 'iucast', total_ref2 => 'imcast' },
                output_template => 'In Bcast : %.2f %%', output_error_template => 'In Bcast : %s',
                output_use => 'ibcast_prct',  threshold_use => 'ibcast_prct',
                perfdatas => [
                    { value => 'ibcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'in-mcast', filter => 'add_cast', nlabel => 'interface.packets.in.multicast.count', set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'imcast', total_ref1 => 'iucast', total_ref2 => 'ibcast' },
                output_template => 'In Mcast : %.2f %%', output_error_template => 'In Mcast : %s',
                output_use => 'imcast_prct',  threshold_use => 'imcast_prct',
                perfdatas => [
                    { value => 'imcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-ucast', filter => 'add_cast', nlabel => 'interface.packets.out.unicast.count', set => {
                key_values => [ { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'oucast', total_ref1 => 'omcast', total_ref2 => 'obcast' },
                output_template => 'Out Ucast : %.2f %%', output_error_template => 'Out Ucast : %s',
                output_use => 'oucast_prct',  threshold_use => 'oucast_prct',
                perfdatas => [
                    { value => 'oucast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-bcast', filter => 'add_cast', nlabel => 'interface.packets.out.broadcast.count', set => {
                key_values => [ { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'obcast', total_ref1 => 'omcast', total_ref2 => 'oucast' },
                output_template => 'Out Bcast : %.2f %%', output_error_template => 'Out Bcast : %s',
                output_use => 'obcast_prct',  threshold_use => 'obcast_prct',
                perfdatas => [
                    { value => 'obcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-mcast', filter => 'add_cast', nlabel => 'interface.packets.out.multicast.count', set => {
                key_values => [ { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'omcast', total_ref1 => 'oucast', total_ref2 => 'obcast' },
                output_template => 'Out Mcast : %.2f %%', output_error_template => 'Out Mcast : %s',
                output_use => 'omcast_prct',  threshold_use => 'omcast_prct',
                perfdatas => [
                    { value => 'omcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ;
}

sub set_counters_speed {
    my ($self, %options) = @_;

    return if ($self->{no_speed} != 0 && $self->{no_set_speed} != 0);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'speed', filter => 'add_speed', nlabel => 'interface.speed.bitspersecond', set => {
                key_values => [ { name => 'speed' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_speed_calc'),
                output_template => 'Speed : %s%s/s', output_error_template => 'Speed : %s%s/s',
                output_change_bytes => 2,
                output_use => 'speed',  threshold_use => 'speed',
                perfdatas => [
                    { value => 'speed', template => '%s',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ;
}

sub set_counters_volume {
    my ($self, %options) = @_;

    return if ($self->{no_volume} != 0 && $self->{no_set_volume} != 0);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-volume', filter => 'add_volume', nlabel => 'interface.volume.in.bytes', set => {
                key_values => [ { name => 'in_volume', diff => 1 }, { name => 'display' } ],
                output_template => 'Volume In : %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'volume_in', value => 'in_volume', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-volume', filter => 'add_volume', nlabel => 'interface.volume.out.bytes', set => {
                key_values => [ { name => 'out_volume', diff => 1 }, { name => 'display' } ],
                output_template => 'Volume Out : %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'volume_out', value => 'out_volume', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'int', type => 1, cb_init => 'skip_interface', cb_init_counters => 'skip_counters', cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', skipped_code => { -10 => 1 } },
    ];

    foreach (('traffic', 'errors', 'cast', 'speed', 'volume')) {
        $self->{'no_' . $_} = defined($options{'no_' . $_}) && $options{'no_' . $_} =~ /^[01]$/ ? $options{'no_' . $_} : 0;
        $self->{'no_set_' . $_} = defined($options{'no_set_' . $_}) && $options{'no_set_' . $_} =~ /^[01]$/ ? $options{'no_set_' . $_} : 0;
    }

    $self->{maps_counters} = { int => [], global => [] } if (!defined($self->{maps_counters}));
    $self->set_counters_global();
    $self->set_counters_status();
    $self->set_counters_traffic();
    $self->set_counters_errors();
    $self->set_counters_cast();
    $self->set_counters_speed();
    $self->set_counters_volume();
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "'$options{instance_value}->{extra_display} "
}

sub skip_global {
    my ($self, %options) = @_;

    return (defined($self->{option_results}->{add_global}) ? 0 : 1);
}

sub skip_interface {
    my ($self, %options) = @_;

    return ($self->{checking} =~ /cast|errors|traffic|status|volume/ ? 0 : 1);
}

sub skip_counters {
    my ($self, %options) = @_;

    return (defined($self->{option_results}->{$options{filter}})) ? 0 : 1;
}

sub set_key_values_status {
    my ($self, %options) = @_;

    return [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'duplexstatus' }, { name => 'display' } ];
}

sub set_key_values_in_traffic {
    my ($self, %options) = @_;

    return [ { name => 'in', diff => 1 }, { name => 'speed_in'}, { name => 'display' }, { name => 'mode_traffic' } ];
}

sub set_key_values_out_traffic {
     my ($self, %options) = @_;

     return [ { name => 'out', diff => 1 }, { name => 'speed_out'}, { name => 'display' }, { name => 'mode_traffic' } ];
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'ifdesc'  => { oid => '.1.3.6.1.2.1.2.2.1.2', get => 'reload_get_simple', cache => 'reload_cache_index_value' },
        'ifalias' => { oid => '.1.3.6.1.2.1.31.1.1.1.18', get => 'reload_get_simple', cache => 'reload_cache_index_value' },
        'ifname'  => { oid => '.1.3.6.1.2.1.31.1.1.1.1', get => 'reload_get_simple', cache => 'reload_cache_index_value' },
        'ipaddr'  => { oid => '.1.3.6.1.2.1.4.20.1.2',  get => 'reload_get_simple', cache => 'reload_cache_values_index' }
    };
}

sub set_oids_status {
    my ($self, %options) = @_;

    $self->{oid_adminstatus} = '.1.3.6.1.2.1.2.2.1.7';
    $self->{oid_adminstatus_mapping} = {
        1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown',
    };
    $self->{oid_opstatus} = '.1.3.6.1.2.1.2.2.1.8';
    $self->{oid_opstatus_mapping} = {
        1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown',
    };
    $self->{oid_duplexstatus} = '.1.3.6.1.2.1.10.7.2.1.19';
    $self->{oid_duplexstatus_mapping} = {
        1 => 'unknown', 2 => 'halfDuplex', 3 => 'fullDuplex',
    };
}

sub set_oids_errors {
    my ($self, %options) = @_;

    $self->{oid_ifInDiscards} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oid_ifInErrors} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oid_ifOutDiscards} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oid_ifOutErrors} = '.1.3.6.1.2.1.2.2.1.20';
}

sub set_oids_traffic {
    my ($self, %options) = @_;

    $self->{oid_speed32} = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
    $self->{oid_in32} = '.1.3.6.1.2.1.2.2.1.10'; # in B
    $self->{oid_out32} = '.1.3.6.1.2.1.2.2.1.16'; # in B
    $self->{oid_speed64} = '.1.3.6.1.2.1.31.1.1.1.15'; # need multiple by '1000000'
    $self->{oid_in64} = '.1.3.6.1.2.1.31.1.1.1.6'; # in B
    $self->{oid_out64} = '.1.3.6.1.2.1.31.1.1.1.10'; # in B
    $self->{oid_iftype} = '.1.3.6.1.2.1.2.2.1.3';
    $self->{oid_adslAtucCurrAttainableRate} = '.1.3.6.1.2.1.10.94.1.1.2.1.8';
    $self->{oid_adslAturCurrAttainableRate} = '.1.3.6.1.2.1.10.94.1.1.3.1.8';
    $self->{oid_xdsl2LineStatusAttainableRateDs} = '.1.3.6.1.2.1.10.251.1.1.1.1.20';
    $self->{oid_xdsl2LineStatusAttainableRateUs} = '.1.3.6.1.2.1.10.251.1.1.1.1.21';
}

sub set_oids_cast {
    my ($self, %options) = @_;

    # 32bits
    $self->{oid_ifInUcastPkts} = '.1.3.6.1.2.1.2.2.1.11';
    $self->{oid_ifInBroadcastPkts} = '.1.3.6.1.2.1.31.1.1.1.3';
    $self->{oid_ifInMulticastPkts} = '.1.3.6.1.2.1.31.1.1.1.2';
    $self->{oid_ifOutUcastPkts} = '.1.3.6.1.2.1.2.2.1.17';
    $self->{oid_ifOutMulticastPkts} = '.1.3.6.1.2.1.31.1.1.1.4';
    $self->{oid_ifOutBroadcastPkts} = '.1.3.6.1.2.1.31.1.1.1.5';

    # 64 bits
    $self->{oid_ifHCInUcastPkts} = '.1.3.6.1.2.1.31.1.1.1.7';
    $self->{oid_ifHCInMulticastPkts} = '.1.3.6.1.2.1.31.1.1.1.8';
    $self->{oid_ifHCInBroadcastPkts} = '.1.3.6.1.2.1.31.1.1.1.9';
    $self->{oid_ifHCOutUcastPkts} = '.1.3.6.1.2.1.31.1.1.1.11';
    $self->{oid_ifHCOutMulticastPkts} = '.1.3.6.1.2.1.31.1.1.1.12';
    $self->{oid_ifHCOutBroadcastPkts} = '.1.3.6.1.2.1.31.1.1.1.13';
}

sub set_oids_speed {
    my ($self, %options) = @_;

    $self->{oid_speed32} = '.1.3.6.1.2.1.2.2.1.5'; # in b/s
    $self->{oid_speed64} = '.1.3.6.1.2.1.31.1.1.1.15'; # need multiple by '1000000'
}

sub check_oids_label {
    my ($self, %options) = @_;

    foreach (('oid_filter', 'oid_display')) {
        $self->{option_results}->{$_} = lc($self->{option_results}->{$_}) if (defined($self->{option_results}->{$_}));
        if (!defined($self->{oids_label}->{$self->{option_results}->{$_}}->{oid})) {
            my $label = $_;
            $label =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --" . $label . " option.");
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{oid_extra_display})) {
        $self->{option_results}->{oid_extra_display} = lc($self->{option_results}->{oid_extra_display});
        if (!defined($self->{oids_label}->{$self->{option_results}->{oid_extra_display}}->{oid})) {
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --oid-extra-display option.");
            $self->{output}->option_exit();
        }
    }
}

sub default_check_status {
    my ($self, %options) = @_;

    return '%{opstatus} eq "up"';
}

sub default_warning_status {
    my ($self, %options) = @_;

    return '';
}

sub default_critical_status {
    my ($self, %options) = @_;

    return '%{admstatus} eq "up" and %{opstatus} ne "up"';
}

sub default_global_admin_up_rule {
    my ($self, %options) = @_;

    return '%{admstatus} eq "up"';
}

sub default_global_admin_down_rule {
    my ($self, %options) = @_;

    return '%{admstatus} ne "up"';
}

sub default_global_oper_up_rule {
    my ($self, %options) = @_;

    return '%{opstatus} eq "up"';
}

sub default_global_oper_down_rule {
    my ($self, %options) = @_;

    return '%{opstatus} ne "up"';
}

sub default_oid_filter_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub default_oid_display_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{no_oid_options} = defined($options{no_oid_options}) && $options{no_oid_options} =~ /^[01]$/ ? $options{no_oid_options} : 0;
    $self->{no_interfaceid_options} = defined($options{no_interfaceid_options}) && $options{no_interfaceid_options} =~ /^[01]$/ ? 
        $options{no_interfaceid_options} : 0;

    $options{options}->add_options(arguments => {
        'add-global'               => { name => 'add_global' },
        'add-status'               => { name => 'add_status' },
        'add-duplex-status'        => { name => 'add_duplex_status' },
        'warning-status:s'         => { name => 'warning_status', default => $self->default_warning_status() },
        'critical-status:s'        => { name => 'critical_status', default => $self->default_critical_status() },
        'global-admin-up-rule:s'   => { name => 'global_admin_up_rule', default => $self->default_global_admin_up_rule() },
        'global-oper-up-rule:s'    => { name => 'global_oper_up_rule', default => $self->default_global_oper_up_rule() },
        'global-admin-down-rule:s' => { name => 'global_admin_down_rule', default => $self->default_global_admin_down_rule() },
        'global-oper-down-rule:s'  => { name => 'global_oper_down_rule', default => $self->default_global_oper_down_rule() },
        'interface:s'              => { name => 'interface' },
        'units-traffic:s'          => { name => 'units_traffic', default => '%' },
        'units-errors:s'           => { name => 'units_errors', default => '%' },
        'speed:s'                  => { name => 'speed' },
        'speed-in:s'               => { name => 'speed_in' },
        'speed-out:s'              => { name => 'speed_out' },
        'no-skipped-counters'      => { name => 'no_skipped_counters' },
        'display-transform-src:s'  => { name => 'display_transform_src' },
        'display-transform-dst:s'  => { name => 'display_transform_dst' },
        'show-cache'               => { name => 'show_cache' },
        'reload-cache-time:s'      => { name => 'reload_cache_time', default => 180 },
        'nagvis-perfdata'          => { name => 'nagvis_perfdata' },
        'force-counters32'         => { name => 'force_counters32' },
        'force-counters64'         => { name => 'force_counters64' },
        'map-speed-dsl:s@'         => { name => 'map_speed_dsl' }
    });
    if ($self->{no_traffic} == 0) {
        $options{options}->add_options(arguments => { 'add-traffic' => { name => 'add_traffic' } });
    }
    if ($self->{no_errors} == 0) {
        $options{options}->add_options(arguments => { 'add-errors' => { name => 'add_errors' } });
    }
    if ($self->{no_cast} == 0) {
        $options{options}->add_options(arguments => { 'add-cast' => { name => 'add_cast' }, });
    }
    if ($self->{no_speed} == 0) {
        $options{options}->add_options(arguments => { 'add-speed' => { name => 'add_speed' }, });
    }
    if ($self->{no_volume} == 0) {
        $options{options}->add_options(arguments => { 'add-volume' => { name => 'add_volume' }, });
    }
    if ($self->{no_oid_options} == 0) {
        $options{options}->add_options(arguments => {
            'oid-filter:s'        => { name => 'oid_filter', default => $self->default_oid_filter_name() },
            'oid-display:s'       => { name => 'oid_display', default => $self->default_oid_display_name() },
            'oid-extra-display:s' => { name => 'oid_extra_display' }
        });
    }
    if ($self->{no_interfaceid_options} == 0) {
        $options{options}->add_options(arguments => {
            'name'  => { name => 'use_name' }
        });
    }

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->set_oids_label();
    $self->check_oids_label();

    $self->{statefile_cache}->check_options(%options);

    if (defined($self->{option_results}->{add_traffic}) && 
        (!defined($self->{option_results}->{units_traffic}) || $self->{option_results}->{units_traffic} !~ /^(%|b\/s)$/)) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --units-traffic.');
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{add_errors}) && 
        (!defined($self->{option_results}->{units_errors}) || $self->{option_results}->{units_errors} !~ /^(%|absolute|b\/s)$/)) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --units-errors.');
        $self->{output}->option_exit();
    }

    $self->{get_speed} = 0;
    if ((!defined($self->{option_results}->{speed}) || $self->{option_results}->{speed} eq '') &&
        ((!defined($self->{option_results}->{speed_in}) || $self->{option_results}->{speed_in} eq '') ||
        (!defined($self->{option_results}->{speed_out}) || $self->{option_results}->{speed_out} eq ''))) {
        $self->{get_speed} = 1;
    } elsif (defined($self->{option_results}->{add_speed})) {
        $self->{output}->add_option_msg(short_msg => 'Cannot use option --add-speed with --speed, --speed-in or --speed-out options.');
        $self->{output}->option_exit();
    }
    
    # If no options, we set status
    if (!defined($self->{option_results}->{add_global}) &&
        !defined($self->{option_results}->{add_status}) && !defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors}) && !defined($self->{option_results}->{add_cast})) {
        $self->{option_results}->{add_status} = 1;
    }
    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast', 'add_speed', 'add_volume')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    $self->{check_status} = $self->default_check_status();
    $self->{check_status} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
}

sub get_display_value {
    my ($self, %options) = @_;

    my $value = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_display} . "_" . $options{id});
    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

sub check_oids_options_change {
    my ($self, %options) = @_;

    my ($regexp, $regexp_append) = ('', '');
    foreach (('oid_display', 'oid_filter', 'oid_extra_display')) {
        if (my $value = $self->{statefile_cache}->get(name => $_)) {
            $regexp .= $regexp_append . $value;
            $regexp_append = '|';
        }
    }
    foreach (('oid_display', 'oid_filter', 'oid_extra_display')) {
        if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} !~ /^($regexp)$/i) {
            return 1;
        }
    }

    return 0;
}

sub reload_cache_index_value {
    my ($self, %options) = @_;

    my $store_index = defined($options{store_index}) && $options{store_index} == 1 ? 1 : 0;
    foreach (keys %{$options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }}) {
        /^$self->{oids_label}->{$options{name}}->{oid}\.(.*)$/;
        push @{$options{datas}->{all_ids}}, $1 if ($store_index == 1);
        $options{datas}->{$options{name} . '_' . $1} = $self->{output}->decode($options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }->{$_});
    }
}

sub reload_cache_values_index {
    my ($self, %options) = @_;

    my $store_index = defined($options{store_index}) && $options{store_index} == 1 ? 1 : 0;
    foreach (keys %{$options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }}) {
        /^$self->{oids_label}->{$options{name}}->{oid}\.(.*)$/;
        push @{$options{datas}->{all_ids}}, $options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }->{$_} if ($store_index == 1);
        if (defined($options{datas}->{$options{name} . '_' . $options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }->{$_}})) {
            $options{datas}->{$options{name} . '_' . $options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }->{$_}} .= ', ' . $1;
        } else {
            $options{datas}->{$options{name} . '_' . $options{result}->{ $self->{oids_label}->{$options{name}}->{oid} }->{$_}} = $1;
        }
    }
}

sub reload_get_simple {
    my ($self, %options) = @_;

    $options{snmp_get}->{ $options{name} } = { oid => $self->{oids_label}->{ $options{name} }->{oid} };
}

sub reload_cache {
    my ($self) = @_;

    my $datas = {};
    $datas->{oid_filter} = $self->{option_results}->{oid_filter};
    $datas->{oid_display} = $self->{option_results}->{oid_display};
    $datas->{oid_extra_display} = $self->{option_results}->{oid_extra_display};
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];

    my ($snmp_get, $func) = ({});
    if ($func = $self->can($self->{oids_label}->{ $self->{option_results}->{oid_filter} }->{get})) {
        $func->($self, snmp_get => $snmp_get, name => $self->{option_results}->{oid_filter});
    }
    if ($func = $self->can($self->{oids_label}->{ $self->{option_results}->{oid_display} }->{get})) {
        $func->($self, snmp_get => $snmp_get, name => $self->{option_results}->{oid_display});
    }
    if (defined($self->{option_results}->{oid_extra_display}) && 
        ($func = $self->can($self->{oids_label}->{ $self->{option_results}->{oid_extra_display} }->{get}))) {
        $func->($self, snmp_get => $snmp_get, name => $self->{option_results}->{oid_extra_display});
    }

    my $result = $self->{snmp}->get_multiple_table(oids => [values %$snmp_get]);

    $func = $self->can($self->{oids_label}->{ $self->{option_results}->{oid_filter} }->{cache});
    $func->($self, result => $result, datas => $datas, name => $self->{option_results}->{oid_filter}, store_index => 1);

    if (my $custom = $self->can('reload_cache_custom')) {
        $custom->($self, datas => $datas);
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        $func = $self->can($self->{oids_label}->{$self->{option_results}->{oid_display}}->{cache});
        $func->($self, result => $result, datas => $datas, name => $self->{option_results}->{oid_display});
    }
    if (defined($self->{option_results}->{oid_extra_display}) && $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_display} && 
        $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_filter}) {
        $func = $self->can($self->{oids_label}->{$self->{option_results}->{oid_extra_display}}->{cache});
        $func->($self, result => $result, datas => $datas, name => $self->{option_results}->{oid_extra_display});
    }
    
    $self->{statefile_cache}->write(data => $datas);
}

sub add_selected_interface {
    my ($self, %options) = @_;

    $self->{int}->{$options{id}} = { display => $self->get_display_value(id => $options{id}), extra_display => '' };
    if (defined($self->{option_results}->{oid_extra_display})) {
        my $name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_extra_display} . '_' . $options{id});
        $self->{int}->{$options{id}}->{extra_display} = ' [ ' . (defined($name) ? $name : '') . ' ]';
    }
}

sub get_selection {
    my ($self, %options) = @_;

    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{snmp}->get_hostname()  . '_' . $self->{snmp}->get_port() . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    $self->{int} = {};
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');

    if ($has_cache_file == 0 || $self->check_oids_options_change() ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        $self->reload_cache();
        $self->{statefile_cache}->read();
    }

    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface}) 
        && $self->{no_interfaceid_options} == 0) {
        foreach (@{$all_ids}) {
            if ($self->{option_results}->{interface} =~ /(^|\s|,)$_(\s*,|$)/) {
                $self->add_selected_interface(id => $_);
            }
        }
    } else {
        foreach (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . '_' . $_);
            next if (!defined($filter_name));
            if (!defined($self->{option_results}->{interface})) {
                $self->add_selected_interface(id => $_);
                next;
            }
            if ($filter_name =~ /$self->{option_results}->{interface}/) {
                $self->add_selected_interface(id => $_);
            }
        }
    }

    if (defined($self->{option_results}->{map_speed_dsl})) {
        $self->{map_speed_dsl} = [];
        foreach (@{$self->{option_results}->{map_speed_dsl}}) {
            my ($src, $dst) = split /,/;
            next if (!defined($dst) || $dst eq '' || !defined($src) || $src eq '');
            push @{$self->{map_speed_dsl}}, { src => $src, dst => $dst };
        }
        foreach (@{$all_ids}) {
            my $filter_name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . '_' . $_);
            for (my $i = 0; $i < scalar(@{$self->{map_speed_dsl}}); $i++) {
                $self->{map_speed_dsl}->[$i]->{src_index} = $_ if ($filter_name =~ /$self->{map_speed_dsl}->[$i]->{src}/);
                $self->{map_speed_dsl}->[$i]->{dst_index} = $_ if ($filter_name =~ /$self->{map_speed_dsl}->[$i]->{dst}/);
            }
        }
    }

    if (scalar(keys %{$self->{int}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found (maybe you should reload cache file)");
        $self->{output}->option_exit();
    }
}

sub load_status {
    my ($self, %options) = @_;

    $self->set_oids_status();
    my $oids = [$self->{oid_adminstatus}, $self->{oid_opstatus}];
    if (defined($self->{option_results}->{add_duplex_status})) {
        push @$oids, $self->{oid_duplexstatus};
    }

    $self->{snmp}->load(oids => $oids, instances => $self->{array_interface_selected});
}

sub load_traffic {
    my ($self, %options) = @_;

    $self->set_oids_traffic();
    if (!defined($self->{option_results}->{force_counters64})) {
        $self->{snmp}->load(oids => [$self->{oid_in32}, $self->{oid_out32}], instances => $self->{array_interface_selected});
        if ($self->{get_speed} == 1) {
            $self->{snmp}->load(oids => [$self->{oid_speed32}], instances => $self->{array_interface_selected});
        }
    }

    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(oids => [$self->{oid_in64}, $self->{oid_out64}], instances => $self->{array_interface_selected});
        if ($self->{get_speed} == 1) {
            $self->{snmp}->load(oids => [$self->{oid_speed64}], instances => $self->{array_interface_selected});
        }
    }

    return if (!defined($self->{map_speed_dsl}));
    my $dst_indexes = [map { $_->{dst_index} } grep { defined($_->{dst_index}) } @{$self->{map_speed_dsl}}];
    if (scalar(@$dst_indexes) <= 0) {
        $self->{map_speed_dsl} = undef;
        return ;
    }

    $self->{snmp}->load(oids => [$self->{oid_iftype}], instances => $dst_indexes);
}

sub load_errors {
    my ($self, %options) = @_;

    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInDiscards}, $self->{oid_ifInErrors},
            $self->{oid_ifOutDiscards}, $self->{oid_ifOutErrors}
        ],
        instances => $self->{array_interface_selected}
    );
}

sub load_cast {
    my ($self, %options) = @_;

    $self->set_oids_cast();
    if (!defined($self->{option_results}->{force_counters64})) {  
        $self->{snmp}->load(
            oids => [
                $self->{oid_ifInUcastPkts}, $self->{oid_ifInBroadcastPkts}, $self->{oid_ifInMulticastPkts},
                $self->{oid_ifOutUcastPkts}, $self->{oid_ifOutMulticastPkts}, $self->{oid_ifOutBroadcastPkts}
            ],
            instances => $self->{array_interface_selected}
        );
    }

    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(
            oids => [
                $self->{oid_ifHCInUcastPkts}, $self->{oid_ifHCInMulticastPkts}, $self->{oid_ifHCInBroadcastPkts},
                $self->{oid_ifHCOutUcastPkts}, $self->{oid_ifHCOutMulticastPkts}, $self->{oid_ifHCOutBroadcastPkts}
            ],
            instances => $self->{array_interface_selected}
        );
    }
}

sub load_speed {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{add_traffic}) && ($self->{get_speed} == 1));

    $self->set_oids_speed();
    $self->{snmp}->load(oids => [$self->{oid_speed32}], instances => $self->{array_interface_selected});
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(oids => [$self->{oid_speed64}], instances => $self->{array_interface_selected});
    }
}

sub load_volume {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{add_traffic}));

    $self->set_oids_traffic();
    if (!defined($self->{option_results}->{force_counters64})) {
        $self->{snmp}->load(oids => [$self->{oid_in32}, $self->{oid_out32}], instances => $self->{array_interface_selected});
    }
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(oids => [$self->{oid_in64}, $self->{oid_out64}], instances => $self->{array_interface_selected});
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $custom_load_method = $self->can('custom_load');
    my $custom_add_result_method = $self->can('custom_add_result');

    $self->get_selection();
    $self->{array_interface_selected} = [keys %{$self->{int}}];    
    $self->load_status() if (defined($self->{option_results}->{add_status}) || defined($self->{option_results}->{add_global}));
    $self->load_errors() if (defined($self->{option_results}->{add_errors}));
    $self->load_traffic() if (defined($self->{option_results}->{add_traffic}));
    $self->load_cast() if ($self->{no_cast} == 0 && (defined($self->{option_results}->{add_cast}) || defined($self->{option_results}->{add_errors})));
    $self->load_speed() if (defined($self->{option_results}->{add_speed}));
    $self->load_volume() if (defined($self->{option_results}->{add_volume}));
    $self->$custom_load_method() if ($custom_load_method);

    $self->{results} = $self->{snmp}->get_leef();

    $self->pre_result();
    $self->add_result_global() if (defined($self->{option_results}->{add_global}));    
    foreach (@{$self->{array_interface_selected}}) {
        $self->add_result_status(instance => $_) if (defined($self->{option_results}->{add_status}));
        $self->add_result_traffic(instance => $_) if (defined($self->{option_results}->{add_traffic}));
        $self->add_result_errors(instance => $_) if (defined($self->{option_results}->{add_errors}));
        $self->add_result_cast(instance => $_) if ($self->{no_cast} == 0 && (defined($self->{option_results}->{add_cast}) || defined($self->{option_results}->{add_errors})));
        $self->add_result_speed(instance => $_) if (defined($self->{option_results}->{add_speed}));
        $self->add_result_volume(instance => $_) if (defined($self->{option_results}->{add_volume}));
        $self->$custom_add_result_method(instance => $_) if ($custom_add_result_method);
    }

    $self->{cache_name} = 'snmpstandard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all')) . '_' .
        md5_hex($self->{checking});
}

sub add_result_global {
    my ($self, %options) = @_;
    
    foreach (('global_admin_up_rule', 'global_admin_down_rule', 'global_oper_up_rule', 'global_oper_down_rule')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$$1/g;
        }
    }
    
    $self->{global} = {
        total_port => 0, global_admin_up => 0, global_admin_down => 0,
        global_oper_up => 0, global_oper_down => 0
    };
    foreach (@{$self->{array_interface_selected}}) {
        my $opstatus = $self->{oid_opstatus_mapping}->{$self->{results}->{$self->{oid_opstatus} . '.' . $_}};
        my $admstatus = $self->{oid_adminstatus_mapping}->{$self->{results}->{$self->{oid_adminstatus} . '.' . $_}};
        foreach (('global_admin_up', 'global_admin_down', 'global_oper_up', 'global_oper_down')) {
            eval {
                local $SIG{__WARN__} = sub { return ; };
                local $SIG{__DIE__} = sub { return ; };
        
                if (defined($self->{option_results}->{$_ . '_rule'}) && $self->{option_results}->{$_ . '_rule'} ne '' &&
                    eval "$self->{option_results}->{$_ . '_rule'}") {
                    $self->{global}->{$_}++;
                }
            };
        }
        $self->{global}->{total_port}++;
    }
}

sub pre_result {
    my ($self, %options) = @_;

    if (defined($self->{map_speed_dsl})) {
        my $oids = [];

        foreach (@{$self->{map_speed_dsl}}) {
            next if (!defined($_->{dst_index}));
            next if (!defined($self->{results}->{ $self->{oid_iftype} . '.' . $_->{dst_index} }));
            # 94 = adsl, 251 => vdsl2
            if ($self->{results}->{ $self->{oid_iftype} . '.' . $_->{dst_index} } == 94) {
                push @$oids, $self->{oid_adslAtucCurrAttainableRate} . '.' . $_->{dst_index}, $self->{oid_adslAturCurrAttainableRate} . '.' . $_->{dst_index};
            } elsif ($self->{results}->{ $self->{oid_iftype} . '.' . $_->{dst_index} } == 251) {
                push @$oids, $self->{oid_xdsl2LineStatusAttainableRateDs} . '.' . $_->{dst_index}, $self->{oid_xdsl2LineStatusAttainableRateUs} . '.' . $_->{dst_index};
            }
        }

        if (scalar(@$oids) > 0) {
            my $results = $self->{snmp}->get_leef(oids => $oids);
            for (my $i = 0; $i < scalar(@{$self->{map_speed_dsl}}); $i++) {
                next if (!defined($self->{map_speed_dsl}->[$i]->{dst_index}));
                next if (!defined($self->{results}->{ $self->{oid_iftype} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }));
                # 94 = adsl, 251 => vdsl2
                if ($self->{results}->{ $self->{oid_iftype} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} } == 94) {
                    $self->{map_speed_dsl}->[$i]->{speed_in} = $results->{ $self->{oid_adslAturCurrAttainableRate} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }
                        if (defined($results->{ $self->{oid_adslAturCurrAttainableRate} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }));
                    $self->{map_speed_dsl}->[$i]->{speed_out} = $results->{ $self->{oid_adslAtucCurrAttainableRate} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }
                        if (defined($results->{ $self->{oid_adslAtucCurrAttainableRate} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }));                    
                } elsif ($self->{results}->{ $self->{oid_iftype} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} } == 251) {
                    $self->{map_speed_dsl}->[$i]->{speed_in} = $results->{ $self->{oid_xdsl2LineStatusAttainableRateDs} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }
                        if (defined($results->{ $self->{oid_xdsl2LineStatusAttainableRateDs} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }));
                    $self->{map_speed_dsl}->[$i]->{speed_out} = $results->{ $self->{oid_xdsl2LineStatusAttainableRateUs} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }
                        if (defined($results->{ $self->{oid_xdsl2LineStatusAttainableRateUs} . '.' . $self->{map_speed_dsl}->[$i]->{dst_index} }));     
                }
            }
        }
    }
}

sub add_result_status {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{opstatus} = defined($self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}) ? $self->{oid_opstatus_mapping}->{$self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}} : undef;
    $self->{int}->{$options{instance}}->{admstatus} = defined($self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}) ? $self->{oid_adminstatus_mapping}->{$self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}} : undef;
    $self->{int}->{$options{instance}}->{duplexstatus} = defined($self->{results}->{$self->{oid_duplexstatus} . '.' . $options{instance}}) ? $self->{oid_duplexstatus_mapping}->{$self->{results}->{$self->{oid_duplexstatus} . '.' . $options{instance}}} : 'n/a';
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
}

sub add_result_traffic {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{mode_traffic} = 32;
    $self->{int}->{$options{instance}}->{in} = $self->{results}->{$self->{oid_in32} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{out} = $self->{results}->{$self->{oid_out32} . '.' . $options{instance}};
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        if (defined($self->{results}->{$self->{oid_in64} . '.' . $options{instance}}) && $self->{results}->{$self->{oid_in64} . '.' . $options{instance}} ne '' &&
            ($self->{results}->{$self->{oid_in64} . '.' . $options{instance}} != 0 || defined($self->{option_results}->{force_counters64}))) {
            $self->{int}->{$options{instance}}->{mode_traffic} = 64;
            $self->{int}->{$options{instance}}->{in} = $self->{results}->{$self->{oid_in64} . '.' . $options{instance}};
            $self->{int}->{$options{instance}}->{out} = $self->{results}->{$self->{oid_out64} . '.' . $options{instance}};
        }
    }
    $self->{int}->{$options{instance}}->{in} *= 8 if (defined($self->{int}->{$options{instance}}->{in}));
    $self->{int}->{$options{instance}}->{out} *= 8 if (defined($self->{int}->{$options{instance}}->{out}));

    $self->{int}->{$options{instance}}->{speed_in} = 0;
    $self->{int}->{$options{instance}}->{speed_out} = 0;
    if ($self->{get_speed} == 0) {
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed} * 1000000;
            $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed} * 1000000;
        }
        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    } else {
        my $interface_speed = 0;
        if (defined($self->{results}->{$self->{oid_speed64} . '.' . $options{instance}}) && $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} ne '') {
            $interface_speed = $self->{results}->{$self->{oid_speed64} . '.' . $options{instance}} * 1000000;
            # If 0, we put the 32 bits
            if ($interface_speed == 0 && !defined($self->{option_results}->{force_counters64})) {
                $interface_speed = $self->{results}->{$self->{oid_speed32} . '.' . $options{instance}};
            }
        } else {
            $interface_speed = $self->{results}->{$self->{oid_speed32} . '.' . $options{instance}};
        }
        
        $self->{int}->{$options{instance}}->{speed_in} = $interface_speed;
        $self->{int}->{$options{instance}}->{speed_out} = $interface_speed;

        if (defined($self->{map_speed_dsl})) {
            foreach (@{$self->{map_speed_dsl}}) {
                next if (!defined($_->{src_index}) || $_->{src_index} != $options{instance});
                $self->{int}->{$options{instance}}->{speed_in} = $_->{speed_in} if (defined($_->{speed_in}));
                $self->{int}->{$options{instance}}->{speed_out} = $_->{speed_out} if (defined($_->{speed_out}));
            }
        }

        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    }
}
    
sub add_result_cast {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{mode_cast} = 32;
    $self->{int}->{$options{instance}}->{iucast} = $self->{results}->{$self->{oid_ifInUcastPkts} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{ibcast} = defined($self->{results}->{$self->{oid_ifInBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifInBroadcastPkts} . '.' . $options{instance}} : 0;
    $self->{int}->{$options{instance}}->{imcast} = defined($self->{results}->{$self->{oid_ifInMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifInMulticastPkts} . '.' . $options{instance}} : 0;
    $self->{int}->{$options{instance}}->{oucast} = $self->{results}->{$self->{oid_ifOutUcastPkts} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{omcast} = defined($self->{results}->{$self->{oid_ifOutMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifOutMulticastPkts} . '.' . $options{instance}} : 0;
    $self->{int}->{$options{instance}}->{obcast} = defined($self->{results}->{$self->{oid_ifOutBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifOutBroadcastPkts} . '.' . $options{instance}} : 0;
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        my $iucast = $self->{results}->{$self->{oid_ifHCInUcastPkts} . '.' . $options{instance}};

        if (defined($iucast) && $iucast ne '' &&
            ($iucast != 0 || defined($self->{option_results}->{force_counters64}))) {
            $self->{int}->{$options{instance}}->{iucast} = $iucast;
            $self->{int}->{$options{instance}}->{imcast} = defined($self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}} : 0;
            $self->{int}->{$options{instance}}->{ibcast} = defined($self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}} : 0;
            $self->{int}->{$options{instance}}->{oucast} = $self->{results}->{$self->{oid_ifHCOutUcastPkts} . '.' . $options{instance}};
            $self->{int}->{$options{instance}}->{omcast} = defined($self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}} : 0;
            $self->{int}->{$options{instance}}->{obcast} = defined($self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}} : 0;
            $self->{int}->{$options{instance}}->{mode_cast} = 64;
        }
    }
    
    foreach (('iucast', 'imcast', 'ibcast', 'oucast', 'omcast', 'obcast')) {
        $self->{int}->{$options{instance}}->{$_} = 0 if (!defined($self->{int}->{$options{instance}}->{$_}));
    }
    
    # https://tools.ietf.org/html/rfc3635 : The IF-MIB octet counters
    # count the number of octets sent to or received from the layer below
    # this interface, whereas the packet counters count the number of
    # packets sent to or received from the layer above.  Therefore,
    # received MAC Control frames, ifInDiscards, and ifInUnknownProtos are
    # counted by ifInOctets, but not ifInXcastPkts.  Transmitted MAC
    # Control frames are counted by ifOutOctets, but not ifOutXcastPkts.
    # ifOutDiscards and ifOutErrors are counted by ifOutXcastPkts, but not
    # ifOutOctets.
    $self->{int}->{$options{instance}}->{total_in_packets} = $self->{int}->{$options{instance}}->{iucast} + $self->{int}->{$options{instance}}->{imcast} + $self->{int}->{$options{instance}}->{ibcast};
    if (defined($self->{int}->{$options{instance}}->{indiscard})) {
        $self->{int}->{$options{instance}}->{total_in_packets} += $self->{int}->{$options{instance}}->{indiscard};
    }
    $self->{int}->{$options{instance}}->{total_out_packets} = $self->{int}->{$options{instance}}->{oucast} + $self->{int}->{$options{instance}}->{omcast} + $self->{int}->{$options{instance}}->{obcast};
}

sub add_result_speed {
    my ($self, %options) = @_;

    my $interface_speed = 0;
    if (defined($self->{results}->{$self->{oid_speed64} . "." . $options{instance}}) && $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} ne '') {
        $interface_speed = $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} * 1000000;
        # If 0, we put the 32 bits
        if ($interface_speed == 0 && !defined($self->{option_results}->{force_counters64})) {
            $interface_speed = $self->{results}->{$self->{oid_speed32} . "." . $options{instance}};
        }
    } else {
        $interface_speed = $self->{results}->{$self->{oid_speed32} . "." . $options{instance}};
    }
    
    $self->{int}->{$options{instance}}->{speed} = $interface_speed;
}

sub add_result_volume {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{mode_traffic} = 32;
    $self->{int}->{$options{instance}}->{in_volume} = $self->{results}->{$self->{oid_in32} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{out_volume} = $self->{results}->{$self->{oid_out32} . '.' . $options{instance}};
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        if (defined($self->{results}->{$self->{oid_in64} . '.' . $options{instance}}) && $self->{results}->{$self->{oid_in64} . '.' . $options{instance}} ne '' &&
            ($self->{results}->{$self->{oid_in64} . '.' . $options{instance}} != 0 || defined($self->{option_results}->{force_counters64}))) {
            $self->{int}->{$options{instance}}->{mode_traffic} = 64;
            $self->{int}->{$options{instance}}->{in_volume} = $self->{results}->{$self->{oid_in64} . '.' . $options{instance}};
            $self->{int}->{$options{instance}}->{out_volume} = $self->{results}->{$self->{oid_out64} . '.' . $options{instance}};
        }
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (By default if no --add-* option is set).

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--units-errors>

Units of thresholds for errors/discards (Default: '%') ('%', 'absolute').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with nagvis widget.

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--map-speed-dsl>

Get interface speed configuration for interface type 'adsl' and 'vdsl2'.

Syntax: --map-speed-dsl=interface-src-name,interface-dsl-name

E.g: --map-speed-dsl=Et0.835,Et0-vdsl2

=item B<--no-skipped-counters>

Don't skip counters when no change.

=item B<--force-counters64>

Force to use 64 bits counters only. Can be used to improve performance.

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src>

Regexp src to transform display value.

=item B<--display-transform-dst>

Regexp dst to transform display value.

=item B<--show-cache>

Display cache interface datas.

=back

=cut
