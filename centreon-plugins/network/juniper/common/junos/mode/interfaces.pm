#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::mode::interfaces;

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
                    { value => 'input_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'bias-current', filter => 'add_optical', nlabel => 'interface.bias.current.milliampere', set => {
                key_values => [ { name => 'bias_current' }, { name => 'display' } ],
                output_template => 'Bias Current : %s mA',
                perfdatas => [
                    { value => 'bias_current', template => '%s',
                      unit => 'mA', label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'output_power' }, { name => 'display' } ],
                output_template => 'Output Power : %s dBm',
                perfdatas => [
                    { value => 'output_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'module-temperature', filter => 'add_optical', nlabel => 'interface.module.temperature.celsius', set => {
                key_values => [ { name => 'module_temperature' }, { name => 'display' } ],
                output_template => 'Module Temperature : %.2f C',
                perfdatas => [
                    { value => 'module_temperature', template => '%.2f',
                      unit => 'C', label_extra_instance => 1, instance_use => 'display' }
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
            'add-optical'   => { name => 'add_optical' },
        }
    );
    
    return $self;
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

my $oid_jnxDomCurrentRxLaserPower = '.1.3.6.1.4.1.2636.3.60.1.1.1.1.5';
my $oid_jnxDomCurrentTxLaserBiasCurrent = '.1.3.6.1.4.1.2636.3.60.1.1.1.1.6';
my $oid_jnxDomCurrentTxLaserOutputPower = '.1.3.6.1.4.1.2636.3.60.1.1.1.1.7';
my $oid_jnxDomCurrentModuleTemperature = '.1.3.6.1.4.1.2636.3.60.1.1.1.1.8';

sub custom_load {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{add_optical}));
    
    $self->{snmp}->load(
        oids => [ 
            $oid_jnxDomCurrentRxLaserPower,
            $oid_jnxDomCurrentTxLaserBiasCurrent,
            $oid_jnxDomCurrentTxLaserOutputPower,
            $oid_jnxDomCurrentModuleTemperature
        ], 
        instances => $self->{array_interface_selected}
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));
    
    $self->{int}->{$options{instance}}->{input_power} = undef;
    if (defined($self->{results}->{$oid_jnxDomCurrentRxLaserPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_jnxDomCurrentRxLaserPower . '.' . $options{instance}} != 0) {
        $self->{int}->{$options{instance}}->{input_power} = $self->{results}->{$oid_jnxDomCurrentRxLaserPower . '.' . $options{instance}} / 100;
    }    
    $self->{int}->{$options{instance}}->{bias_current} = undef;
    if (defined($self->{results}->{$oid_jnxDomCurrentTxLaserBiasCurrent . '.' . $options{instance}}) &&
        $self->{results}->{$oid_jnxDomCurrentTxLaserBiasCurrent . '.' . $options{instance}} != 0) {
        $self->{int}->{$options{instance}}->{bias_current} = $self->{results}->{$oid_jnxDomCurrentTxLaserBiasCurrent . '.' . $options{instance}} / 100;
    }    
    $self->{int}->{$options{instance}}->{output_power} = undef;
    if (defined($self->{results}->{$oid_jnxDomCurrentTxLaserOutputPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_jnxDomCurrentTxLaserOutputPower . '.' . $options{instance}} != 0) {
        $self->{int}->{$options{instance}}->{output_power} = $self->{results}->{$oid_jnxDomCurrentTxLaserOutputPower . '.' . $options{instance}} / 100;
    }
    $self->{int}->{$options{instance}}->{module_temperature} = undef;
    if (defined($self->{results}->{$oid_jnxDomCurrentModuleTemperature . '.' . $options{instance}}) &&
        $self->{results}->{$oid_jnxDomCurrentModuleTemperature . '.' . $options{instance}} != 0) {
        $self->{int}->{$options{instance}}->{module_temperature} = $self->{results}->{$oid_jnxDomCurrentModuleTemperature . '.' . $options{instance}};
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

=item B<--add-optical>

Check interface optical metrics.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-errors>

Set warning threshold for all error counters.

=item B<--critical-errors>

Set critical threshold for all error counters.

=item B<--warning-*>

Threshold warning (will superseed --warning-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'fcs-errors (%)', 'input-power' (dBm), 'bias-current' (mA), 'output-power' (dBm), 'module-temperature' (C).

=item B<--critical-*>

Threshold critical (will superseed --warning-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'in-fcserror' (%), 'input-power' (dBm), 'bias-current' (mA), 'output-power' (dBm), 'module-temperature' (C).

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
