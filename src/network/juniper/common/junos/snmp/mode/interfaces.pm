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

package network::juniper::common::junos::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oid_ifInDiscards} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oid_ifInErrors} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oid_ifOutDiscards} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oid_ifOutErrors} = '.1.3.6.1.2.1.2.2.1.20';
    $self->{oid_ifInFCSError} = '.1.3.6.1.2.1.10.7.2.1.3'; # dot3StatsFCSErrors
}

sub set_counters {
    my ($self, %options) = @_;

    $self->SUPER::set_counters(%options);
    
    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-fcserror', filter => 'add_errors', nlabel => 'interface.packets.in.fcserror.count', set => {
                key_values => [ { name => 'infcserror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'fcserror' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In FCS Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ;

    push @{$self->{maps_counters}->{int}},
        { label => 'input-power', filter => 'add_optical', nlabel => 'interface.input.power.dbm', set => {
                key_values => [ { name => 'input_power' }, { name => 'display' } ],
                output_template => 'Input Power : %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'bias-current', filter => 'add_optical', nlabel => 'interface.bias.current.milliampere', set => {
                key_values => [ { name => 'bias_current' }, { name => 'display' } ],
                output_template => 'Bias Current : %s mA',
                perfdatas => [
                    { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'output_power' }, { name => 'display' } ],
                output_template => 'Output Power : %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'module-temperature', filter => 'add_optical', nlabel => 'interface.module.temperature.celsius', set => {
                key_values => [ { name => 'module_temperature' }, { name => 'display' } ],
                output_template => 'Module Temperature : %.2f C',
                perfdatas => [
                    { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
            'add-optical'   => { name => 'add_optical' }
        }
    );
    
    return $self;
}

sub skip_interface {
    my ($self, %options) = @_;

    return ($self->{checking} =~ /cast|errors|traffic|status|volume|optical/ ? 0 : 1);
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast', 'add_speed', 'add_volume', 'add_optical')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

sub load_errors {
    my ($self, %options) = @_;
    
    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInDiscards},
            $self->{oid_ifInErrors},
            $self->{oid_ifOutDiscards},
            $self->{oid_ifOutErrors},
            $self->{oid_ifInFCSError}
        ],
        instances => $self->{array_interface_selected}
    );
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{infcserror} = $self->{results}->{$self->{oid_ifInFCSError} . '.' . $options{instance}};
}

my $mapping_optical = {
    input_power        => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.5'  }, # jnxDomCurrentRxLaserPower
    bias_current       => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.6'  }, # jnxDomCurrentTxLaserBiasCurrent
    output_power       => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.7'  }, # jnxDomCurrentTxLaserOutputPower
    module_temperature => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.8'  }, # jnxDomCurrentModuleTemperature
    rx_high_critical   => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.9'  }, # jnxDomCurrentRxLaserPowerHighAlarmThreshold
    rx_low_critical    => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.10' }, # jnxDomCurrentRxLaserPowerLowAlarmThreshold
    rx_high_warning    => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.11' }, # jnxDomCurrentRxLaserPowerHighWarningThreshold
    rx_low_warning     => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.12' }, # jnxDomCurrentRxLaserPowerLowWarningThreshold
    tx_high_critical   => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.17' }, # jnxDomCurrentTxLaserOutputPowerHighAlarmThreshold
    tx_low_critical    => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.18' }, # jnxDomCurrentTxLaserOutputPowerLowAlarmThreshold
    tx_high_warning    => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.19' }, # jnxDomCurrentTxLaserOutputPowerHighWarningThreshold
    tx_low_warning     => { oid => '.1.3.6.1.4.1.2636.3.60.1.1.1.1.20' }  # jnxDomCurrentTxLaserOutputPowerLowWarningThreshold
};

sub custom_load {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{add_optical}));
    
    $self->{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_optical)) ],
        instances => $self->{array_interface_selected}
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_optical, results => $self->{results}, instance => $options{instance});

    $self->{int}->{$options{instance}}->{input_power} = undef;
    if (defined($result->{input_power}) && $result->{input_power} != 0) {
        $self->{int}->{$options{instance}}->{input_power} = $result->{input_power} / 100;

        my ($warn_val, $crit_val) = ('', '');
        if ((!defined($self->{option_results}->{'warning-input-power'}) || $self->{option_results}->{'warning-input-power'} eq '') &&
            (!defined($self->{option_results}->{'critical-input-power'}) || $self->{option_results}->{'critical-input-power'} eq '') &&
            (!defined($self->{option_results}->{'warning-instance-interface-input-power-dbm'}) || $self->{option_results}->{'warning-instance-interface-input-power-dbm'} eq '') &&
            (!defined($self->{option_results}->{'critical-instance-interface-input-power-dbm'}) || $self->{option_results}->{'critical-instance-interface-input-power-dbm'} eq '')) {
            $crit_val = ($result->{rx_low_critical} / 100) . ':'
                if (defined($result->{rx_low_critical}) && $result->{rx_low_critical} != 0);
            $crit_val .= ($result->{rx_high_critical} / 100)
                if (defined($result->{rx_high_critical}) && $result->{rx_high_critical} != 0);
            $self->{perfdata}->threshold_validate(label => 'critical-input-power', value => $crit_val);
            $self->{perfdata}->threshold_validate(label => 'critical-instance-interface-input-power-dbm', value => $crit_val);

            $warn_val = ($result->{rx_low_warning} / 100) . ':'
                if (defined($result->{rx_low_warning}) && $result->{rx_low_warning} != 0);
            $warn_val .= ($result->{rx_high_warning} / 100)
                if (defined($result->{rx_high_warning}) && $result->{rx_high_warning} != 0);
            $self->{perfdata}->threshold_validate(label => 'warning-input-power', value => $warn_val);
            $self->{perfdata}->threshold_validate(label => 'warning-instance-interface-input-power-dbm', value => $warn_val);
        }
    }    
    $self->{int}->{$options{instance}}->{bias_current} = undef;
    if (defined($result->{bias_current}) && $result->{bias_current} != 0) {
        $self->{int}->{$options{instance}}->{bias_current} = $result->{bias_current} / 1000;
    }    
    $self->{int}->{$options{instance}}->{output_power} = undef;
    if (defined($result->{output_power}) && $result->{output_power} != 0) {
        $self->{int}->{$options{instance}}->{output_power} = $result->{output_power} / 100;

        my ($warn_val, $crit_val) = ('', '');
        if ((!defined($self->{option_results}->{'warning-output-power'}) || $self->{option_results}->{'warning-output-power'} eq '') &&
            (!defined($self->{option_results}->{'critical-output-power'}) || $self->{option_results}->{'critical-output-power'} eq '') &&
            (!defined($self->{option_results}->{'warning-instance-interface-output-power-dbm'}) || $self->{option_results}->{'warning-instance-interface-output-power-dbm'} eq '') &&
            (!defined($self->{option_results}->{'critical-instance-interface-output-power-dbm'}) || $self->{option_results}->{'critical-instance-interface-output-power-dbm'} eq '')) {
            $crit_val = ($result->{tx_low_critical} / 100) . ':'
                if (defined($result->{tx_low_critical}) && $result->{tx_low_critical} != 0);
            $crit_val .= ($result->{tx_high_critical} / 100)
                if (defined($result->{tx_high_critical}) && $result->{tx_high_critical} != 0);
            $self->{perfdata}->threshold_validate(label => 'critical-output-power', value => $crit_val);
            $self->{perfdata}->threshold_validate(label => 'critical-instance-interface-output-power-dbm', value => $crit_val);

            $warn_val = ($result->{tx_low_warning} / 100) . ':'
                if (defined($result->{tx_low_warning}) && $result->{tx_low_warning} != 0);
            $warn_val .= ($result->{tx_high_warning} / 100)
                if (defined($result->{tx_high_warning}) && $result->{tx_high_warning} != 0);
            $self->{perfdata}->threshold_validate(label => 'warning-output-power', value => $warn_val);
            $self->{perfdata}->threshold_validate(label => 'warning-instance-interface-output-power-dbm', value => $warn_val);
        }
    }
    $self->{int}->{$options{instance}}->{module_temperature} = undef;
    if (defined($result->{module_temperature}) && $result->{module_temperature} != 0) {
        $self->{int}->{$options{instance}}->{module_temperature} = $result->{module_temperature};
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (by default if no C<--add-*> option is set).

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with C<--warning-status> and C<--critical-status>).

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

=item B<--add-optical>

Check interface optical metrics.

=item B<--check-metrics>

If the expression is true, metrics are checked (default: C<'%{opstatus} eq "up"'>).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{admstatus}>, C<%{opstatus}>, C<%{duplexstatus}>, C<%{display}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{admstatus} eq "up" and %{opstatus} ne "up"'>).
You can use the following variables: C<%{admstatus}>, C<%{opstatus}>, C<%{duplexstatus}>, C<%{display}>

=item B<--warning-errors>

Set warning threshold for all error counters.

=item B<--critical-errors>

Set critical threshold for all error counters.

=item B<--warning-total-port>

Threshold.

=item B<--critical-total-port>

Threshold.

=item B--warning-total-admin-up>

Threshold.

=item B<--critical-total-admin-up>

Threshold.

=item B<--warning-total-admin-down>

Threshold.

=item B<--critical-total-admin-down>

Threshold.

=item B<--warning-total-oper-up>

Threshold.

=item B<--critical-total-oper-up>

Threshold.

=item B<--warning-total-oper-down>

Threshold.

=item B<--critical-total-oper-down>

Threshold.

=item B<--warning-in-traffic>

Set warning threshold for in traffic.

=item B<--critical-in-traffic>

Set critical threshold for in traffic.

=item B<--warning-out-traffic>

Set warning threshold for out traffic.

=item B<--critical-out-traffic>

Set critical threshold for out traffic.

=item B<--warning-in-error>

Set warning threshold for in error traffic.

=item B<--critical-in-error>

Set critical threshold for in error traffic.

=item B<--warning-in-discard>

Set warning threshold for in discard traffic.

=item B<--critical-in-discard>

Set critical threshold for in discard traffic.

=item B--warning-out-error>

Set warning threshold for out error traffic.

=item B<--critical-out-error>

Set critical threshold for out error traffic.

=item B<--warning-out-discard>

Set warning threshold for out discard traffic.

=item B<--critical-out-discard>

Set critical threshold for out discard traffic.

=item B<--warning-in-ucast>

Set warning threshold for in unicast traffic.

=item B<--critical-in-ucast>

Set critical threshold for in unicast traffic.

=item B<--warning-in-bcast>

Set warning threshold for in broadcast traffic.

=item B<--critical-in-bcast>

Set critical threshold for in broadcast traffic.

=item B<--warning-in-mcast>

Set warning threshold for in multicast traffic.

=item B<--critical-in-mcast>

Set critical threshold for in multicast traffic.

=item B<--warning-out-ucast>

Set warning threshold for out unicast traffic.

=item B<--critical-out-ucast>

Set critical threshold for out unicast traffic.

=item B<--warning-out-bcast>

Set warning threshold for out broadcast traffic.

=item B<--critical-out-bcast>

Set critical threshold for out broadcast traffic.

=item B<--warning-out-mcast>

Set warning threshold for out multicast traffic.

=item B<--critical-out-mcast>

Set critical threshold for out multicast traffic.

=item B<--warning-speed>

Set warning threshold for speed (in b/s).

=item B<--critical-speed>

Set critical threshold for speed (in b/s).

=item B<--warning-fcs-errors>

Set warning threshold for Frame Check Sum errors (in percent).

=item B<--critical-fcs-errors>

Set critical threshold for Frame Check Sum errors (in percent).

=item B<--warning-input-power>

Set warning threshold for input power (dBm).

=item B<--critical-input-power>

Set critical threshold for input power (dBm).

=item B<--warning-bias-current>

Set warning threshold for bias current (mA).

=item B<--critical-bias-current>

Set critical threshold for bias current (mA).

=item B<--warning-output-power>

Set warning threshold for output power (dBm).

=item B<--critical-output-power>

Set critical threshold for output power (dBm).

=item B<--warning-module-temperature>

Set warning threshold for module temperature (C).

=item B<--critical-module-temperature>

Set critical threshold for module temperature (C).

=item B<--units-traffic>

Units of thresholds for the traffic (default: C<%{percent_delta}>) (C<%{percent_delta}>, C<%{bps}>, C<%{counter}>).

=item B<--units-errors>

Units of thresholds for errors/discards (default: C<%{percent_delta}>) (C<%{percent_delta}>, C<%{percent}>, C<%{delta}>, C<%{deltaps}>, C<%{counter}>).

=item B<--units-cast>

Units of thresholds for communication types (default: C<%{percent_delta}>) (C<%{percent_delta}>, C<%{percent}>, C<%{delta}>, C<%{deltaps}>, C<%{counter}>).

=item B<--nagvis-perfdata>

Display traffic performance data to be compatible with NagVis widget.

=item B<--interface>

Set the interface (number expected) example: 1,2,... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option C<--interface>) by name instead of OID index. The name matching mode supports regular expressions.

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Define the OID to be used to filter interfaces (default: C<ifName>) (values: C<ifDesc>, C<ifAlias>, C<ifName>, C<IpAddr>).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: C<ifName>) (values: C<ifDesc>, C<ifAlias>, C<ifName>, C<IpAddr>).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding C<--display-transform-src='eth' --display-transform-dst='ens'> will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface data.

=back

=cut
