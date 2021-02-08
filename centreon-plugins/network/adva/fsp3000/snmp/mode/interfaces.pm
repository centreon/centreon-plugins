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

package network::adva::fsp3000::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_traffic {
    my ($self, %options) = @_;
    
    $self->{currentEthRx15minBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.52.1.5'; # in B
    $self->{currentEthRx1dayBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.53.1.5'; # in B
    $self->{currentEthTx15minBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.56.1.3'; # in B
    $self->{currentEthTx1dayBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.57.1.3'; # in B
    $self->{currentEthRxHighSpeed15minBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.88.1.4'; # in B
    $self->{currentEthRxHighSpeed1dayBytes} = '.1.3.6.1.4.1.2544.1.11.2.6.2.89.1.4'; # in B
}

sub set_counters_traffic {
    my ($self, %options) = @_;

    push @{$self->{maps_counters}->{int}}, 
        { label => 'traffic-in', filter => 'add_traffic', nlabel => 'interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in_15min', diff => 1 }, { name => 'traffic_in_1day', diff => 1 }, { name => 'speed_in'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', filter => 'add_traffic', nlabel => 'interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out_15min', diff => 1 }, { name => 'traffic_out_1day', diff => 1 }, { name => 'speed_out'}, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->SUPER::set_counters(%options);

    push @{$self->{maps_counters}->{int}}, 
        { label => 'laser-temp', filter => 'add_optical', nlabel => 'interface.laser.temperature.celsius', set => {
                key_values => [ { name => 'laser_temp' }, { name => 'display' } ],
                output_template => 'Laser Temperature : %.2f C', output_error_template => 'Laser Temperature : %.2f',
                perfdatas => [
                    { label => 'laser_temp', template => '%.2f',
                      unit => 'C', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'input-power', filter => 'add_optical', nlabel => 'interface.input.power.dbm', set => {
                key_values => [ { name => 'input_power' }, { name => 'display' } ],
                output_template => 'Input Power : %s dBm', output_error_template => 'Input Power : %s',
                perfdatas => [
                    { label => 'input_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'output_power' }, { name => 'display' } ],
                output_template => 'Output Power : %s dBm', output_error_template => 'Output Power : %s',
                perfdatas => [
                    { label => 'output_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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
        label => 'traffic_' . $self->{result_values}->{label}, unit => 'b/s',
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

    # we choose the performance value (1day is updated every 15 minutes. 15min is updated all the time but reset every 15min
    my $counter = 'traffic_' . $options{extra_options}->{label_ref} . '_15min';
    if ($options{delta_time} >= 600) {
        $counter = 'traffic_' . $options{extra_options}->{label_ref} . '_1day';
    }

    my $diff_traffic = ($options{new_datas}->{$self->{instance} . '_' . $counter} - $options{old_datas}->{$self->{instance} . '_' . $counter});
    
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_set_traffic => 1, no_errors => 1, no_cast => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
            'add-optical'   => { name => 'add_optical' },
        }
    );
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_traffic', 'add_speed', 'add_volume', 'add_optical')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

my $oid_opticalIfDiagLaserTemp = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.2';
my $oid_opticalIfDiagInputPower = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.3';
my $oid_opticalIfDiagOutputPower = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.4';

sub custom_load {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{add_optical}));
    
    $self->{snmp}->load(oids => [$oid_opticalIfDiagLaserTemp, $oid_opticalIfDiagInputPower, $oid_opticalIfDiagOutputPower], 
        instances => $self->{array_interface_selected});
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));
    $self->{int}->{$options{instance}}->{laser_temp} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}} != -2147483648) {
        $self->{int}->{$options{instance}}->{laser_temp} = $self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}} * 0.1;
    }
    
    $self->{int}->{$options{instance}}->{input_power} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}} != -65535) {
        $self->{int}->{$options{instance}}->{input_power} = $self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}} / 10;
    }
    
    $self->{int}->{$options{instance}}->{output_power} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}} != -65535) {
        $self->{int}->{$options{instance}}->{output_power} = $self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}} / 10;
    }
}

sub load_traffic {
    my ($self, %options) = @_;
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    
    $self->set_oids_traffic();
    $self->{snmp}->load(oids => [$self->{currentEthRx15minBytes}, $self->{currentEthRx1dayBytes}, 
                                 $self->{currentEthTx15minBytes}, $self->{currentEthTx1dayBytes},
                                 $self->{currentEthRxHighSpeed15minBytes}, $self->{currentEthRxHighSpeed1dayBytes}], instances => $self->{array_interface_selected});
}

sub add_result_traffic {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{traffic_in_15min} = 
        defined($self->{results}->{$self->{currentEthRxHighSpeed15minBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthRxHighSpeed15minBytes} . '.' . $options{instance}} * 8 :
            (defined($self->{results}->{$self->{currentEthRx15minBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthRx15minBytes} . '.' . $options{instance}} * 8 : undef);
    $self->{int}->{$options{instance}}->{traffic_in_1day} = 
        defined($self->{results}->{$self->{currentEthRxHighSpeed1dayBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthRxHighSpeed1dayBytes} . '.' . $options{instance}} * 8 :
            (defined($self->{results}->{$self->{currentEthRx1dayBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthRx1dayBytes} . '.' . $options{instance}} * 8 : undef);
    $self->{int}->{$options{instance}}->{traffic_out_15min} = 
        defined($self->{results}->{$self->{currentEthTx15minBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthTx15minBytes} . '.' . $options{instance}} * 8 : undef;
    $self->{int}->{$options{instance}}->{traffic_out_1day} = 
        defined($self->{results}->{$self->{currentEthTx1dayBytes} . '.' . $options{instance}}) ? $self->{results}->{$self->{currentEthTx1dayBytes} . '.' . $options{instance}} * 8 : undef;
    
    $self->{int}->{$options{instance}}->{speed_in} = 0;
    $self->{int}->{$options{instance}}->{speed_out} = 0;
    if ($self->{get_speed} == 0) {
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed} * 1000000;
            $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed} * 1000000;
        }
        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    }
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

=item B<--add-optical>

Check interface optical.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'laser-temp', 'input-power', 'output-power', 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'laser-temp', 'input-power', 'output-power', 'traffic-in', 'traffic-out'.

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

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
