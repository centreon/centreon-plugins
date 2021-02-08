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

package network::atrica::snmp::mode::connections;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'atrconncepgendescr' => { oid => '.1.3.6.1.4.1.6110.2.7.5.1.1', get => 'reload_get_simple', cache => 'reload_cache_index_value' },
        'atrconningdescr'    => { oid => '.1.3.6.1.4.1.6110.2.2.1.1.2', get => 'reload_get_simple', cache => 'reload_cache_index_value' }
    };
}

sub set_oids_status {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{oid_filter} eq 'atrconncepgendescr') {
        $self->{oid_adminstatus} = '.1.3.6.1.4.1.6110.2.7.5.1.7';
        $self->{oid_adminstatus_mapping} = {
            1 => 'up', 2 => 'down',
        };
        $self->{oid_opstatus} = '.1.3.6.1.4.1.6110.2.7.5.1.8';
        $self->{oid_opstatus_mapping} = {
            1 => 'up', 2 => 'down', 3 => 'oneWay', 4 => 'twoWay', 5 => 'fastProtected',
        };
        if (!defined($self->{option_results}->{critical_status})) {
            $self->{option_results}->{critical_status} = '%{admstatus} eq "up" and %{opstatus} ne "up"';
        }
    } else {
        $self->{oid_adminstatus} = '.1.3.6.1.4.1.6110.2.2.1.1.3';
        $self->{oid_adminstatus_mapping} = {
            2 => 'off', 3 => 'on',
        };
        $self->{oid_opstatus} = '.1.3.6.1.4.1.6110.2.2.1.1.4';
        $self->{oid_opstatus_mapping} = {
            2 => 'off', 3 => 'systemBusy', 4 => 'dependencyBusy', 5 => 'inService', 6 => 'alterInService', 7 => 'failed',
            8 => 'mainInServiceViaCoreLinkProtec', 9 => 'alterInServiceViaCoreLinkProtec',
            10 => 'mainAndAltDownConnUpSendingToMain', 11 => 'mainAndAltDownConnUpSendingToAlt',
        };
        if (!defined($self->{option_results}->{critical_status})) {
            $self->{option_results}->{critical_status} = '%{admstatus} eq "on" and %{opstatus} ne "inService"';
        }
    }
}

sub set_speed {
    my ($self, %options) = @_;
    
    $self->{oid_speed} = '.1.3.6.1.4.1.6110.2.9.1.1.14'; # in Kb/s
}

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oid_ing_eir_discard} = '.1.3.6.1.4.1.6110.2.2.4.1.1.7'; # in B
    $self->{oid_eg_eir_discard} = '.1.3.6.1.4.1.6110.2.3.2.1.1.6'; # in B
}

sub set_oids_traffic {
    my ($self, %options) = @_;
    
    $self->{oid_ing_cir} = '.1.3.6.1.4.1.6110.2.2.4.1.1.4'; # in B
    $self->{oid_ing_eir} = '.1.3.6.1.4.1.6110.2.2.4.1.1.5'; # in B
    $self->{oid_eg_cir} = '.1.3.6.1.4.1.6110.2.3.2.1.1.4'; # in B
    $self->{oid_eg_eir} = '.1.3.6.1.4.1.6110.2.3.2.1.1.5'; # in B
}

sub default_warning_status {
    my ($self, %options) = @_;
    
    return undef;
}

sub default_critical_status {
    my ($self, %options) = @_;
    
    return undef;
}

sub default_check_status {
    my ($self, %options) = @_;
    
    return '%{opstatus} eq "up" or %{opstatus} eq "inService"';
}

sub default_global_admin_up_rule {
    my ($self, %options) = @_;
    
    return '%{admstatus} eq "up" or %{admstatus} eq "on"';
}

sub default_global_admin_down_rule {
    my ($self, %options) = @_;
    
    return '%{admstatus} ne "up" and %{admstatus} ne "on"';
}

sub default_global_oper_up_rule {
    my ($self, %options) = @_;
    
    return '%{opstatus} eq "up" or %{opstatus} eq "inService"';
}

sub default_global_oper_down_rule {
    my ($self, %options) = @_;
    
    return '%{opstatus} ne "up" and %{opstatus} ne "inService"';
}

sub default_oid_filter_name {
    my ($self, %options) = @_;
    
    return 'atrConnCepGenDescr';
}

sub default_oid_display_name {
    my ($self, %options) = @_;
    
    return 'atrConnCepGenDescr';
}

sub set_counters_traffic {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-cir', filter => 'add_traffic', nlabel => 'interface.traffic.in.cir.bitspersecond', set => {
                key_values => [ { name => 'in_cir', diff => 1 }, { name => 'speed_in'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in_cir' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In CIR : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'in-eir', filter => 'add_traffic', nlabel => 'interface.traffic.in.eir.bitspersecond', set => {
                key_values => [ { name => 'in_eir', diff => 1 }, { name => 'speed_in'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in_eir' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In EIR : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'out-cir', filter => 'add_traffic', nlabel => 'interface.traffic.out.cir.bitspersecond', set => {
                key_values => [ { name => 'out_cir', diff => 1 }, { name => 'speed_out'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out_cir' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out CIR : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'out-eir', filter => 'add_traffic', nlabel => 'interface.traffic.out.eir.bitspersecond', set => {
                key_values => [ { name => 'out_eir', diff => 1 }, { name => 'speed_out'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out_eir' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out EIR : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        }
    ;
}

sub set_counters_errors {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-eir-discard', filter => 'add_errors', nlabel => 'interface.packets.in.eir.discard.count', set => {
                key_values => [ { name => 'in_eir_discard', diff => 1 }, { name => 'speed_in'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in_eir_discard' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In EIR Discard : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        },
        { label => 'out-eir-discard', filter => 'add_errors', nlabel => 'interface.packets.out.eir.discard.count', set => {
                key_values => [ { name => 'out_eir_discard', diff => 1 }, { name => 'speed_out'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out_eir_discard' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out EIR Discard : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold'),
            }
        }
    ;
}

sub custom_traffic_perfdata {
    my ($self, %options) = @_;
    
    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{units_traffic} eq '%' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{units_traffic} eq 'b/s') {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label});
    }
    
    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'b/s',
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{traffic_per_seconds}),
        warning => $warning,
        critical => $critical,
        min => 0, max => $self->{result_values}->{speed}
    );
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
    
    my $label = $self->{result_values}->{label};
    $label =~ s/_/ /g;
    $label =~ s/(\w+)/\u$1/g;
    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);    
    my $msg = sprintf("Traffic %s : %s/s (%s)",
                      $label, $traffic_value . $traffic_unit,
                      defined($self->{result_values}->{traffic_prct}) ? sprintf("%.2f%%", $self->{result_values}->{traffic_prct}) : '-');
    return $msg;
}

sub custom_traffic_calc {
    my ($self, %options) = @_;
    
    return -10 if (defined($self->{instance_mode}->{last_status}) && $self->{instance_mode}->{last_status} == 0);

    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}});
    if ($diff_traffic == 0 && !defined($self->{instance_mode}->{option_results}->{no_skipped_counters})) {
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, 
                                  no_set_traffic => 1, no_set_errors => 1, no_cast => 1);
    bless $self, $class;
    
    return $self;
}

sub load_speed {
    my ($self, %options) = @_;
    
    $self->{speed_loaded} = 1;
    $self->{snmp}->load(oids => [$self->{oid_speed}], instances => $self->{array_interface_selected});
}

sub load_traffic {
    my ($self, %options) = @_;
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{speed_loaded})) {
        $self->set_speed();
        $self->load_speed(%options);
    }
    $self->set_oids_traffic();
    $self->{snmp}->load(oids => [$self->{oid_ing_cir}, $self->{oid_ing_eir}, 
                                 $self->{oid_eg_cir}, $self->{oid_eg_eir}], instances => $self->{array_interface_selected});
}

sub load_errors {
    my ($self, %options) = @_;
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{speed_loaded})) {
        $self->set_speed();
        $self->load_speed(%options);
    }
    $self->set_oids_errors();    
    $self->{snmp}->load(oids => [$self->{oid_ing_eir_discard}, $self->{oid_eg_eir_discard}], instances => $self->{array_interface_selected});
}

sub add_result_speed {
    my ($self, %options) = @_;
    
    return if (defined($self->{int}->{$options{instance}}->{speed_in}));
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
        my $interface_speed = defined($self->{results}->{$self->{oid_speed} . "." . $options{instance}}) ? $self->{results}->{$self->{oid_speed} . "." . $options{instance}} : 0;
        $interface_speed *= 1000;
        $self->{int}->{$options{instance}}->{speed_in} = $interface_speed;
        $self->{int}->{$options{instance}}->{speed_out} = $interface_speed;
        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    }
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{in_eir_discard} = $self->{results}->{$self->{oid_ing_eir_discard} . '.' . $options{instance}} * 8;
    $self->{int}->{$options{instance}}->{out_eir_discard} = $self->{results}->{$self->{oid_eg_eir_discard} . '.' . $options{instance}} * 8;
    $self->add_result_speed(%options);
}

sub add_result_traffic {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{in_cir} = $self->{results}->{$self->{oid_ing_cir} . '.' . $options{instance}} * 8;
    $self->{int}->{$options{instance}}->{in_eir} = $self->{results}->{$self->{oid_ing_eir} . '.' . $options{instance}} * 8;
    $self->{int}->{$options{instance}}->{out_cir} = $self->{results}->{$self->{oid_eg_cir} . '.' . $options{instance}} * 8;
    $self->{int}->{$options{instance}}->{out_eir} = $self->{results}->{$self->{oid_eg_eir} . '.' . $options{instance}} * 8;
    $self->add_result_speed(%options);
}

1;

__END__

=head1 MODE

Check connections (A-Series.mib).

=over 8

=item B<--add-status>

Check interface status (By default if no --add-* option is set).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status.
Default (depends of the atrica release):
'%{admstatus} eq "on" and %{opstatus} ne "inService"'
'%{admstatus} eq "up" and %{opstatus} ne "up"'
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'in-cir', 'in-eir', 'out-cir', 'out-eir', 'in-eir-discard', 'out-eir-discard'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-cir', 'in-eir', 'out-cir', 'out-eir', 'in-eir-discard', 'out-eir-discard'.

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--units-errors>

Units of thresholds for discards (Default: '%') ('%', 'b/s').

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

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: atrConnCepGenDescr) (values: atrConnIngDescr, atrConnCepGenDescr).

=item B<--oid-display>

Choose OID used to display interface (default: atrConnCepGenDescr) (values: atrConnIngDescr, atrConnCepGenDescr).

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
