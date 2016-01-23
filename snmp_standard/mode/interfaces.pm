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

package snmp_standard::mode::interfaces;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

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
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
        
        $instance_mode->{last_status} = 0;
        if (eval "$instance_mode->{check_status}") {
            $instance_mode->{last_status} = 1;
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
    
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    return 0;
}

sub custom_cast_calc {
    my ($self, %options) = @_;

    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_cast'} ne $options{old_datas}->{$self->{instance} . '_mode_cast'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    my $diff_cast = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    my $total = $diff_cast
                + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref1}}) 
                + ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref2}});

    if ($total == 0 && !defined($instance_mode->{option_results}->{no_skipped_counters})) {
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
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    if (defined($instance_mode->{option_results}->{nagvis_perfdata})) {
        $self->{result_values}->{traffic_per_seconds} /= 8;
        $self->{result_values}->{speed} /= 8;
    }
    
    my ($warning, $critical);
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }
    
    if (defined($instance_mode->{option_results}->{nagvis_perfdata})) {
        $self->{output}->perfdata_add(label => $self->{result_values}->{label} . $extra_label,
                                      value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
                                      warning => $warning,
                                      critical => $critical,
                                      min => 0, max => $self->{result_values}->{speed});
    } else {
        $self->{output}->perfdata_add(label => 'traffic_' . $self->{result_values}->{label} . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
                                      warning => $warning,
                                      critical => $critical,
                                      min => 0, max => $self->{result_values}->{speed});
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($instance_mode->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } elsif ($instance_mode->{option_results}->{units_traffic} eq 'b/s') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;
    
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    my $msg = sprintf("Traffic %s : %s/s (%s)",
                      ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-');
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_traffic'} ne $options{old_datas}->{$self->{instance} . '_mode_traffic'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
  
    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    if ($diff_traffic == 0 && !defined($instance_mode->{option_results}->{no_skipped_counters})) {
        $self->{error_msg} = "skipped";
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
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    if ($instance_mode->{option_results}->{units_errors} eq '%') {
        $self->{output}->perfdata_add(label => 'packets_' . $self->{result_values}->{label2} . '_' . $self->{result_values}->{label1} . $extra_label, unit => '%',
                                  value => sprintf("%.2f", $self->{result_values}->{prct}),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                  min => 0, max => 100);
    } else {
        $self->{output}->perfdata_add(label => 'packets_' . $self->{result_values}->{label2} . '_' . $self->{result_values}->{label1} . $extra_label,
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                  min => 0, max => $self->{result_values}->{total});
    }
}

sub custom_errors_threshold {
    my ($self, %options) = @_;
    
    my $exit = 'ok';
    if ($instance_mode->{option_results}->{units_errors} eq '%') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    } else {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_errors_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Packets %s %s : %.2f%% (%s)",
                      ucfirst($self->{result_values}->{label1}), ucfirst($self->{result_values}->{label2}),
                      $self->{result_values}->{prct}, $self->{result_values}->{used});
    return $msg;
}

sub custom_errors_calc {
    my ($self, %options) = @_;

    return -10 if (defined($instance_mode->{last_status}) && $instance_mode->{last_status} == 0);
    if ($options{new_datas}->{$self->{instance} . '_mode_cast'} ne $options{old_datas}->{$self->{instance} . '_mode_cast'}) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }
    
    my $diff = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2}} - 
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref1} . $options{extra_options}->{label_ref2}});
    my $total = ($options{new_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'} - 
        $options{old_datas}->{$self->{instance} . '_total_' . $options{extra_options}->{label_ref1} . '_packets'});
    if ($total == 0 && !defined($instance_mode->{option_results}->{no_skipped_counters})) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{prct} = $total == 0 ? 0 : $diff * 100 / $total;
    $self->{result_values}->{used} = $diff;
    $self->{result_values}->{total} = $total;
    $self->{result_values}->{label1} = $options{extra_options}->{label_ref1};
    $self->{result_values}->{label2} = $options{extra_options}->{label_ref2};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

#########################
# OIDs mapping functions
#########################
sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters} = { int => {}, global => {} } if (!defined($self->{maps_counters}));
    
    $self->{maps_counters}->{global}->{'000_total-port'} = { filter => 'add_global',
        set => {
            key_values => [ { name => 'total_port' } ],
            output_template => 'Total port : %s', output_error_template => 'Total port : %s',
            output_use => 'total_port_absolute',  threshold_use => 'total_port_absolute',
            perfdatas => [
                { label => 'total_port', value => 'total_port_absolute', template => '%s',
                  min => 0, max => 'total_port_absolute' },
           ],
        }
    };
    $self->{maps_counters}->{global}->{'001_global-admin-up'} = { filter => 'add_global',
        set => {
            key_values => [ { name => 'global_admin_up' }, { name => 'total_port' } ],
            output_template => 'AdminStatus Up : %s', output_error_template => 'AdminStatus Up : %s',
            output_use => 'global_admin_up_absolute',  threshold_use => 'global_admin_up_absolute',
            perfdatas => [
                { label => 'total_admin_up', value => 'global_admin_up_absolute', template => '%s',
                  min => 0, max => 'total_port_absolute' },
           ],
        }
    };
    $self->{maps_counters}->{global}->{'002_total-admin-down'} = { filter => 'add_global',
        set => {
            key_values => [ { name => 'global_admin_down' }, { name => 'total_port' } ],
            output_template => 'AdminStatus Down : %s', output_error_template => 'AdminStatus Down : %s',
            output_use => 'global_admin_down_absolute',  threshold_use => 'global_admin_down_absolute',
            perfdatas => [
                { label => 'total_admin_down', value => 'global_admin_down_absolute', template => '%s',
                  min => 0, max => 'total_port_absolute' },
           ],
        }
    };
    $self->{maps_counters}->{global}->{'003_total-oper-up'} = { filter => 'add_global',
        set => {
            key_values => [ { name => 'global_oper_up' }, { name => 'total_port' } ],
            output_template => 'OperStatus Up : %s', output_error_template => 'OperStatus Up : %s',
            output_use => 'global_oper_up_absolute',  threshold_use => 'global_oper_up_absolute',
            perfdatas => [
                { label => 'total_oper_up', value => 'global_oper_up_absolute', template => '%s',
                  min => 0, max => 'total_port_absolute' },
           ],
        }
    };
    $self->{maps_counters}->{global}->{'004_total-oper-down'} = { filter => 'add_global',
        set => {
            key_values => [ { name => 'global_oper_down' }, { name => 'total_port' } ],
            output_template => 'OperStatus Down : %s', output_error_template => 'OperStatus Down : %s',
            output_use => 'global_oper_down_absolute',  threshold_use => 'global_oper_down_absolute',
            perfdatas => [
                { label => 'global_oper_down', value => 'global_oper_down_absolute', template => '%s',
                  min => 0, max => 'total_port_absolute' },
           ],
        }
    };
    
    $self->{maps_counters}->{int}->{'000_status'} = { filter => 'add_status', threshold => 0,
        set => {
            key_values => $self->set_key_values_status(),
            closure_custom_calc => $self->can('custom_status_calc'),
            closure_custom_output => $self->can('custom_status_output'),
            closure_custom_perfdata => sub { return 0; },
            closure_custom_threshold_check => $self->can('custom_threshold_output'),
        }
    };
    if ($self->{no_traffic} == 0 && $self->{no_set_traffic} == 0) {
        $self->{maps_counters}->{int}->{'020_in-traffic'} = { filter => 'add_traffic',
            set => {
                key_values => $self->set_key_values_in_traffic(),
                per_second => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        };
        $self->{maps_counters}->{int}->{'021_out-traffic'} = {  filter => 'add_traffic',
            set => {
                key_values => $self->set_key_values_out_traffic(),
                per_second => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        };
    }
    if ($self->{no_errors} == 0 && $self->{no_set_errors} == 0) {
        $self->{maps_counters}->{int}->{'040_in-discard'} = { filter => 'add_errors',
            set => {
                key_values => [ { name => 'indiscard', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Discard : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold'),
            }
        };
        $self->{maps_counters}->{int}->{'041_in-error'} = { filter => 'add_errors',
            set => {
                key_values => [ { name => 'inerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold'),
            }
        };
        $self->{maps_counters}->{int}->{'042_out-discard'} = { filter => 'add_errors',
            set => {
                key_values => [ { name => 'outdiscard', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'discard' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Discard : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold'),
            }
        };
        $self->{maps_counters}->{int}->{'043_out-error'} = { filter => 'add_errors',
            set => {
                key_values => [ { name => 'outerror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'error' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold'),
            }
        };
    }
    if ($self->{no_cast} == 0 && $self->{no_set_cast} == 0) {
        $self->{maps_counters}->{int}->{'060_in-ucast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'iucast', total_ref1 => 'ibcast', total_ref2 => 'imcast' },
                output_template => 'In Ucast : %.2f %%', output_error_template => 'In Ucast : %s',
                output_use => 'iucast_prct',  threshold_use => 'iucast_prct',
                perfdatas => [
                    { value => 'iucast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
        $self->{maps_counters}->{int}->{'061_in-bcast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'ibcast', total_ref1 => 'iucast', total_ref2 => 'imcast' },
                output_template => 'In Bcast : %.2f %%', output_error_template => 'In Bcast : %s',
                output_use => 'ibcast_prct',  threshold_use => 'ibcast_prct',
                perfdatas => [
                    { value => 'ibcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
        $self->{maps_counters}->{int}->{'062_in-mcast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'imcast', total_ref1 => 'iucast', total_ref2 => 'ibcast' },
                output_template => 'In Mcast : %.2f %%', output_error_template => 'In Mcast : %s',
                output_use => 'imcast_prct',  threshold_use => 'imcast_prct',
                perfdatas => [
                    { value => 'imcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
        $self->{maps_counters}->{int}->{'063_out-ucast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'oucast', total_ref1 => 'omcast', total_ref2 => 'obcast' },
                output_template => 'Out Ucast : %.2f %%', output_error_template => 'Out Ucast : %s',
                output_use => 'oucast_prct',  threshold_use => 'oucast_prct',
                perfdatas => [
                    { value => 'oucast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
        $self->{maps_counters}->{int}->{'064_out-bcast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'oucast', diff => 1 }, { name => 'omcast', diff => 1 }, { name => 'obcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'obcast', total_ref1 => 'omcast', total_ref2 => 'oucast' },
                output_template => 'Out Bcast : %.2f %%', output_error_template => 'Out Bcast : %s',
                output_use => 'obcast_prct',  threshold_use => 'obcast_prct',
                perfdatas => [
                    { value => 'obcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
        $self->{maps_counters}->{int}->{'065_out-mcast'} = { filter => 'add_cast',
            set => {
                key_values => [ { name => 'iucast', diff => 1 }, { name => 'imcast', diff => 1 }, { name => 'ibcast', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => \&custom_cast_calc, closure_custom_calc_extra_options => { label_ref => 'ibcast', total_ref1 => 'iucast', total_ref2 => 'imcast' },
                output_template => 'In Bcast : %.2f %%', output_error_template => 'In Bcast : %s',
                output_use => 'ibcast_prct',  threshold_use => 'ibcast_prct',
                perfdatas => [
                    { value => 'ibcast_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        };
    }
}

sub set_key_values_status {
    my ($self, %options) = @_;

    return [ { name => 'opstatus' }, { name => 'admstatus' } ];
}

sub set_key_values_in_traffic {
    my ($self, %options) = @_;
    
    return [ { name => 'in', diff => 1 }, { name => 'speed_in'}, { name => 'display' }, { name => 'mode_traffic' } ];
}

sub set_key_values_out_traffic {
     my ($self, %options) = @_;
     
     return [ { name => 'out', diff => 1 }, { name => 'speed_out'}, { name => 'display' }, { name => 'mode_traffic' } ];
}

sub set_instance {
    my ($self, %options) = @_;
    
    $instance_mode = $self;
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'ifdesc' => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
        'ifname' => '.1.3.6.1.2.1.31.1.1.1.1',
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

sub check_oids_label {
    my ($self, %options) = @_;
    
    foreach (('oid_filter', 'oid_display')) {
        $self->{option_results}->{$_} = lc($self->{option_results}->{$_}) if (defined($self->{option_results}->{$_}));
        if (!defined($self->{oids_label}->{$self->{option_results}->{$_}})) {
            my $label = $_;
            $label =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --" . $label . " option.");
            $self->{output}->option_exit();
        }
    }
    
    if (defined($self->{option_results}->{oid_extra_display})) {
        $self->{option_results}->{oid_extra_display} = lc($self->{option_results}->{oid_extra_display});
        if (!defined($self->{oids_label}->{$self->{option_results}->{oid_extra_display}})) {
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
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;

    $self->{no_oid_options} = defined($options{no_oid_options}) && $options{no_oid_options} =~ /^[01]$/ ? $options{no_oid_options} : 0;
    $self->{no_interfaceid_options} = defined($options{no_interfaceid_options}) && $options{no_interfaceid_options} =~ /^[01]$/ ? 
        $options{no_interfaceid_options} : 0;
    foreach (('traffic', 'errors', 'cast')) {
        $self->{'no_' . $_} = defined($options{'no_' . $_}) && $options{'no_' . $_} =~ /^[01]$/ ? $options{'no_' . $_} : 0;
        $self->{'no_set_' . $_} = defined($options{'no_set_' . $_}) && $options{'no_set_' . $_} =~ /^[01]$/ ? $options{'no_set_' . $_} : 0;
    }
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "add-global"              => { name => 'add_global' },
                                "add-status"              => { name => 'add_status' },
                                "warning-status:s"        => { name => 'warning_status', default => $self->default_warning_status() },
                                "critical-status:s"       => { name => 'critical_status', default => $self->default_critical_status() },
                                "global-admin-up-rule:s"    => { name => 'global_admin_up_rule', default => $self->default_global_admin_up_rule() },
                                "global-oper-up-rule:s"     => { name => 'global_oper_up_rule', default => $self->default_global_oper_up_rule() },
                                "global-admin-down-rule:s"  => { name => 'global_admin_down_rule', default => $self->default_global_admin_down_rule() },
                                "global-oper-down-rule:s"   => { name => 'global_oper_down_rule', default => $self->default_global_oper_down_rule() },
                                "interface:s"             => { name => 'interface' },
                                "units-traffic:s"         => { name => 'units_traffic', default => '%' },
                                "units-errors:s"          => { name => 'units_errors', default => '%' },
                                "speed:s"                 => { name => 'speed' },
                                "speed-in:s"              => { name => 'speed_in' },
                                "speed-out:s"             => { name => 'speed_out' },
                                "no-skipped-counters"     => { name => 'no_skipped_counters' },
                                "display-transform-src:s" => { name => 'display_transform_src' },
                                "display-transform-dst:s" => { name => 'display_transform_dst' },
                                "show-cache"              => { name => 'show_cache' },
                                "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                "nagvis-perfdata"         => { name => 'nagvis_perfdata' },
                                "force-counters32"        => { name => 'force_counters32' },
                                });
    if ($self->{no_traffic} == 0) {
        $options{options}->add_options(arguments => { "add-traffic" => { name => 'add_traffic' } });
    }
    if ($self->{no_errors} == 0) {
        $options{options}->add_options(arguments => { "add-errors" => { name => 'add_errors' } });
    }
    if ($self->{no_cast} == 0) {
        $options{options}->add_options(arguments => { "add-cast" => { name => 'add_cast' }, });
    }
    if ($self->{no_oid_options} == 0) {
        $options{options}->add_options(arguments =>
                                {
                                "oid-filter:s"            => { name => 'oid_filter', default => $self->default_oid_filter_name() },
                                "oid-display:s"           => { name => 'oid_display', default => $self->default_oid_display_name() },
                                "oid-extra-display:s"     => { name => 'oid_extra_display' },
                                }
                                );
    }
    if ($self->{no_interfaceid_options} == 0) {
        $options{options}->add_options(arguments =>
                                {
                                "name"                    => { name => 'use_name' },
                                }
                                );
    }
    
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->set_counters();

    foreach my $key (('int', 'global')) {
        foreach (keys %{$self->{maps_counters}->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($self->{maps_counters}->{$key}->{$_}->{threshold}) || $self->{maps_counters}->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $self->{maps_counters}->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $self->{maps_counters}->{$key}->{$_}->{obj}->set(%{$self->{maps_counters}->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('int', 'global')) {
        foreach (keys %{$self->{maps_counters}->{$key}}) {
            $self->{maps_counters}->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $self->set_oids_label();
    $self->check_oids_label();
    
    $self->set_instance();
    $self->{statefile_cache}->check_options(%options);
    $self->{statefile_value}->check_options(%options);
    
    if (defined($self->{option_results}->{add_traffic}) && 
        (!defined($self->{option_results}->{units_traffic}) || $self->{option_results}->{units_traffic} !~ /^(%|b\/s)$/)) {
        $self->{output}->add_option_msg(short_msg => "Wrong option --units-traffic.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{add_errors}) && 
        (!defined($self->{option_results}->{units_errors}) || $self->{option_results}->{units_errors} !~ /^(%|absolute|b\/s)$/)) {
        $self->{output}->add_option_msg(short_msg => "Wrong option --units-errors.");
        $self->{output}->option_exit();
    }
    
    $self->{get_speed} = 0;
    if ((!defined($self->{option_results}->{speed}) || $self->{option_results}->{speed} eq '') &&
        ((!defined($self->{option_results}->{speed_in}) || $self->{option_results}->{speed_in} eq '') ||
        (!defined($self->{option_results}->{speed_out}) || $self->{option_results}->{speed_out} eq ''))) {
        $self->{get_speed} = 1;
    }
    
    # If no options, we set status
    if (!defined($self->{option_results}->{add_global}) &&
        !defined($self->{option_results}->{add_status}) && !defined($self->{option_results}->{add_traffic}) &&
        !defined($self->{option_results}->{add_errors}) && !defined($self->{option_results}->{add_cast})) {
        $self->{option_results}->{add_status} = 1;
    }
    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
    
    $self->change_macros();
}

sub run_global {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$self->{maps_counters}->{global}}) {
        my $obj = $self->{maps_counters}->{global}->{$_}->{obj};
                
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "$long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    $self->get_informations();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{interface_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1 && defined($self->{option_results}->{add_global})) {
        $self->run_global();
    }
    
    if ($multiple == 1 && $self->{checking} =~ /cast|errors|traffic|status/) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All interfaces are ok');
    }
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . 
            (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all')) . '_' .
             md5_hex($self->{checking}));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{interface_selected}}) {
        next if ($self->{checking} !~ /cast|errors|traffic|status/);
    
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$self->{maps_counters}->{int}}) {
            my $obj = $self->{maps_counters}->{int}->{$_}->{obj};
            next if (!defined($self->{option_results}->{$self->{maps_counters}->{int}->{$_}->{filter}}));
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{interface_selected}->{$id},
                                              new_datas => $self->{new_datas});
            next if ($value_check == -10); # not running
            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $obj->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "'$self->{interface_selected}->{$id}->{extra_display} $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "'$self->{interface_selected}->{$id}->{extra_display} $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Interface '" . $self->{interface_selected}->{$id}->{display} . "'$self->{interface_selected}->{$id}->{extra_display} $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
    
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

sub reload_cache {
    my ($self) = @_;
    my $datas = {};

    $datas->{oid_filter} = $self->{option_results}->{oid_filter};
    $datas->{oid_display} = $self->{option_results}->{oid_display};
    $datas->{oid_extra_display} = $self->{option_results}->{oid_extra_display};
    $datas->{last_timestamp} = time();
    $datas->{all_ids} = [];
    
    my $snmp_get = [
        { oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} },
    ];
    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        push @{$snmp_get}, { oid => $self->{oids_label}->{$self->{option_results}->{oid_display}} };
    }
    if (defined($self->{option_results}->{oid_extra_display}) && $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_display} && 
        $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_filter}) {
        push @{$snmp_get}, { oid => $self->{oids_label}->{$self->{option_results}->{oid_extra_display}} };
    }    
    
    my $result = $self->{snmp}->get_multiple_table(oids => $snmp_get);
    foreach ($self->{snmp}->oid_lex_sort(keys %{$result->{$self->{oids_label}->{$self->{option_results}->{oid_filter}}}})) {
        /^$self->{oids_label}->{$self->{option_results}->{oid_filter}}\.(.*)$/;
        push @{$datas->{all_ids}}, $1;
        $datas->{$self->{option_results}->{oid_filter} . "_" . $1} = $self->{output}->to_utf8($result->{$self->{oids_label}->{$self->{option_results}->{oid_filter}}}->{$_});
    }

    if (scalar(@{$datas->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't construct cache...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
       foreach ($self->{snmp}->oid_lex_sort(keys %{$result->{$self->{oids_label}->{$self->{option_results}->{oid_display}}}})) {
            /^$self->{oids_label}->{$self->{option_results}->{oid_display}}\.(.*)$/;
            $datas->{$self->{option_results}->{oid_display} . "_" . $1} = $self->{output}->to_utf8($result->{$self->{oids_label}->{$self->{option_results}->{oid_display}}}->{$_});
       }
    }
    if (defined($self->{option_results}->{oid_extra_display}) && $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_display} && 
        $self->{option_results}->{oid_extra_display} ne $self->{option_results}->{oid_filter}) {
        foreach ($self->{snmp}->oid_lex_sort(keys %{$result->{$self->{oids_label}->{$self->{option_results}->{oid_extra_display}}}})) {
            /^$self->{oids_label}->{$self->{option_results}->{oid_extra_display}}\.(.*)$/;
            $datas->{$self->{option_results}->{oid_extra_display} . "_" . $1} = $self->{output}->to_utf8($result->{$self->{oids_label}->{$self->{option_results}->{oid_extra_display}}}->{$_});
       }
    }
    
    $self->{statefile_cache}->write(data => $datas);
}

sub add_selected_interface {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{id}} = { display => $self->get_display_value(id => $options{id}), extra_display => '' };
    if (defined($self->{option_results}->{oid_extra_display})) {
         $self->{interface_selected}->{$options{id}}->{extra_display} = ' [ ' . $self->{statefile_cache}->get(name => $self->{option_results}->{oid_extra_display} . "_" . $options{id}) . ' ]';
    }
}

sub get_selection {
    my ($self, %options) = @_;
    
    # init cache file
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    if (defined($self->{option_results}->{show_cache})) {
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit();
    }

    $self->{interface_selected} = {};
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
            my $filter_name = $self->{statefile_cache}->get(name => $self->{option_results}->{oid_filter} . "_" . $_);
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
    
    if (scalar(keys %{$self->{interface_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found (maybe you should reload cache file)");
        $self->{output}->option_exit();
    }
}

sub load_status {
    my ($self, %options) = @_;
    
    $self->set_oids_status();
    $self->{snmp}->load(oids => [$self->{oid_adminstatus}, $self->{oid_opstatus}], instances => $self->{array_interface_selected});
}

sub load_traffic {
    my ($self, %options) = @_;
    
    $self->set_oids_traffic();
    $self->{snmp}->load(oids => [$self->{oid_in32}, $self->{oid_out32}], instances => $self->{array_interface_selected});
    if ($self->{get_speed} == 1) {
        $self->{snmp}->load(oids => [$self->{oid_speed32}], instances => $self->{array_interface_selected});
    }
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(oids => [$self->{oid_in64}, $self->{oid_out64}], instances => $self->{array_interface_selected});
        if ($self->{get_speed} == 1) {
            $self->{snmp}->load(oids => [$self->{oid_speed64}], instances => $self->{array_interface_selected});
        }
    }
}

sub load_errors {
    my ($self, %options) = @_;
    
    $self->set_oids_errors();
    $self->{snmp}->load(oids => [$self->{oid_ifInDiscards}, $self->{oid_ifInErrors},
                                 $self->{oid_ifOutDiscards}, $self->{oid_ifOutErrors}], instances => $self->{array_interface_selected});
}

sub load_cast {
    my ($self, %options) = @_;

    $self->set_oids_cast();    
    $self->{snmp}->load(oids => [$self->{oid_ifInUcastPkts}, $self->{oid_ifInBroadcastPkts}, $self->{oid_ifInMulticastPkts},
                                 $self->{oid_ifOutUcastPkts}, $self->{oid_ifOutMulticastPkts}, $self->{oid_ifOutBroadcastPkts}],
                        instances => $self->{array_interface_selected});
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        $self->{snmp}->load(oids => [$self->{oid_ifHCInUcastPkts}, $self->{oid_ifHCInMulticastPkts}, $self->{oid_ifHCInBroadcastPkts},
                                     $self->{oid_ifHCOutUcastPkts}, $self->{oid_ifHCOutMulticastPkts}, $self->{oid_ifHCOutBroadcastPkts}],
                            instances => $self->{array_interface_selected});
    }
}

sub get_informations {
    my ($self, %options) = @_;

    $self->get_selection();
    $self->{array_interface_selected} = [keys %{$self->{interface_selected}}];    
    $self->load_status() if (defined($self->{option_results}->{add_status}) || defined($self->{option_results}->{add_global}));
    $self->load_errors() if (defined($self->{option_results}->{add_errors}));
    $self->load_traffic() if (defined($self->{option_results}->{add_traffic}));
    $self->load_cast() if ($self->{no_cast} == 0 && (defined($self->{option_results}->{add_cast}) || defined($self->{option_results}->{add_errors})));

    $self->{results} = $self->{snmp}->get_leef();
    
    $self->add_result_global() if (defined($self->{option_results}->{add_global}));    
    foreach (@{$self->{array_interface_selected}}) {
        $self->add_result_status(instance => $_) if (defined($self->{option_results}->{add_status}));
        $self->add_result_traffic(instance => $_) if (defined($self->{option_results}->{add_traffic}));
        $self->add_result_cast(instance => $_) if ($self->{no_cast} == 0 && (defined($self->{option_results}->{add_cast}) || defined($self->{option_results}->{add_errors})));
        $self->add_result_errors(instance => $_) if (defined($self->{option_results}->{add_errors}));
    }
}

sub add_result_global {
    my ($self, %options) = @_;
    
    foreach (('global_admin_up_rule', 'global_admin_down_rule', 'global_oper_up_rule', 'global_oper_down_rule')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$$1/g;
        }
    }
    
    $self->{global} = { total_port => 0, global_admin_up => 0, global_admin_down => 0,
                        global_oper_up => 0, global_oper_down => 0};
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

sub add_result_status {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}}->{opstatus} = defined($self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}) ? $self->{oid_opstatus_mapping}->{$self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}} : undef;
    $self->{interface_selected}->{$options{instance}}->{admstatus} = defined($self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}) ? $self->{oid_adminstatus_mapping}->{$self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}} : undef;
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
}

sub add_result_traffic {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}}->{mode_traffic} = 32;
    $self->{interface_selected}->{$options{instance}}->{in} = $self->{results}->{$self->{oid_in32} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{out} = $self->{results}->{$self->{oid_out32} . '.' . $options{instance}};
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        if (defined($self->{results}->{$self->{oid_in64} . '.' . $options{instance}}) && $self->{results}->{$self->{oid_in64} . '.' . $options{instance}} ne '' &&
            $self->{results}->{$self->{oid_in64} . '.' . $options{instance}} != 0) {
            $self->{interface_selected}->{$options{instance}}->{mode_traffic} = 64;
            $self->{interface_selected}->{$options{instance}}->{in} = $self->{results}->{$self->{oid_in64} . '.' . $options{instance}};
            $self->{interface_selected}->{$options{instance}}->{out} = $self->{results}->{$self->{oid_out64} . '.' . $options{instance}};
        }
    }
    $self->{interface_selected}->{$options{instance}}->{in} *= 8 if (defined($self->{interface_selected}->{$options{instance}}->{in}));
    $self->{interface_selected}->{$options{instance}}->{out} *= 8 if (defined($self->{interface_selected}->{$options{instance}}->{out}));
    
    $self->{interface_selected}->{$options{instance}}->{speed_in} = 0;
    $self->{interface_selected}->{$options{instance}}->{speed_out} = 0;
    if ($self->{get_speed} == 0) {
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $self->{interface_selected}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed} * 1000000;
            $self->{interface_selected}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed} * 1000000;
        }
        $self->{interface_selected}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{interface_selected}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    } else {
        my $interface_speed = 0;
        if (defined($self->{results}->{$self->{oid_speed64} . "." . $options{instance}}) && $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} ne '') {
            $interface_speed = $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} * 1000000;
            # If 0, we put the 32 bits
            if ($interface_speed == 0) {
                $interface_speed = $self->{results}->{$self->{oid_speed32} . "." . $options{instance}};
            }
        } else {
            $interface_speed = $self->{results}->{$self->{oid_speed32} . "." . $options{instance}};
        }
        
        $self->{interface_selected}->{$options{instance}}->{speed_in} = $interface_speed;
        $self->{interface_selected}->{$options{instance}}->{speed_out} = $interface_speed;
        $self->{interface_selected}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{interface_selected}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    }
}
    
sub add_result_cast {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}}->{mode_cast} = 32;
    $self->{interface_selected}->{$options{instance}}->{iucast} = $self->{results}->{$self->{oid_ifInUcastPkts} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{ibcast} = defined($self->{results}->{$self->{oid_ifInBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifInBroadcastPkts} . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{imcast} = defined($self->{results}->{$self->{oid_ifInMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifInMulticastPkts} . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{oucast} = $self->{results}->{$self->{oid_ifOutUcastPkts} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{omcast} = defined($self->{results}->{$self->{oid_ifOutMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifOutMulticastPkts} . '.' . $options{instance}} : 0;
    $self->{interface_selected}->{$options{instance}}->{obcast} = defined($self->{results}->{$self->{oid_ifOutBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifOutBroadcastPkts} . '.' . $options{instance}} : 0;
    if (!$self->{snmp}->is_snmpv1() && !defined($self->{option_results}->{force_counters32})) {
        my $iucast = $self->{results}->{$self->{oid_ifHCInUcastPkts} . '.' . $options{instance}};
        if (defined($iucast) && $iucast =~ /[1-9]/) {
            $self->{interface_selected}->{$options{instance}}->{iucast} = $iucast;
            $self->{interface_selected}->{$options{instance}}->{imcast} = defined($self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{ibcast} = defined($self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{oucast} = $self->{results}->{$self->{oid_ifHCOutUcastPkts} . '.' . $options{instance}};
            $self->{interface_selected}->{$options{instance}}->{omcast} = defined($self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{obcast} = defined($self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}} : 0;
            $self->{interface_selected}->{$options{instance}}->{mode_cast} = 64;
        }
    }
    
    foreach (('iucast', 'imcast', 'ibcast', 'oucast', 'omcast', 'omcast')) {
        $self->{interface_selected}->{$options{instance}}->{$_} = 0 if (!defined($self->{interface_selected}->{$options{instance}}->{$_}));
    }
    
    $self->{interface_selected}->{$options{instance}}->{total_in_packets} = $self->{interface_selected}->{$options{instance}}->{iucast} + $self->{interface_selected}->{$options{instance}}->{imcast} + $self->{interface_selected}->{$options{instance}}->{ibcast};
    $self->{interface_selected}->{$options{instance}}->{total_out_packets} = $self->{interface_selected}->{$options{instance}}->{oucast} + $self->{interface_selected}->{$options{instance}}->{omcast} + $self->{interface_selected}->{$options{instance}}->{obcast};
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

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%).

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

=item B<--no-skipped-counters>

Don't skip counters when no change.

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

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
