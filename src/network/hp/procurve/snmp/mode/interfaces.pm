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

package network::hp::procurve::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_poe_status_output {
    my ($self, %options) = @_;

    return 'poe status: ' . $self->{result_values}->{poestatus};
}

sub set_counters_errors {
    my ($self, %options) = @_;

    $self->SUPER::set_counters_errors(%options);

    push @{$self->{maps_counters}->{int}},
        { label => 'poe-status', filter => 'add_poe', type => 2, set => {
                key_values => [
                    { name => 'poestatus' }, { name => 'opstatus' }, 
                    { name => 'admstatus' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_poe_status_output'),
                closure_custom_perfdata => sub { return 0; },
                 closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'poe-power-actual', filter => 'add_poe', nlabel => 'interface.poe.power.actual.milliwatt', set => {
                key_values => [ { name => 'poe_actual_power' }, { name => 'display' } ],
                output_template => 'poe actual power: %s mW',
                perfdatas => [
                    { label => 'power_actual', template => '%.2f',
                      unit => 'mW', label_extra_instance => 1, instance_use => 'display' }
                ]
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
        { label => 'voltage', filter => 'add_optical', nlabel => 'interface.voltage.volt', set => {
                key_values => [ { name => 'voltage' }, { name => 'display' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { template => '%s', unit => 'V', label_extra_instance => 1, instance_use => 'display' }
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
        'add-poe'     => { name => 'add_poe' },
        'add-optical' => { name => 'add_optical' }
    });

    return $self;
}

sub skip_interface {
    my ($self, %options) = @_;

    return ($self->{checking} =~ /cast|errors|traffic|poe|status|volume|optical/ ? 0 : 1);
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast', 'add_speed', 'add_volume', 'add_poe', 'add_optical')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

sub reload_cache_custom {
    my ($self, %options) = @_;

    $options{datas}->{poe_ports} = {};
    my $oid_hpicfPoePethPsePortOperStatus = '.1.3.6.1.4.1.11.2.14.11.1.9.1.1.1.9';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_hpicfPoePethPsePortOperStatus);
    foreach (keys %$snmp_result) {
        next if (! /^$oid_hpicfPoePethPsePortOperStatus\.(\d+)\.(\d+)$/);
        $options{datas}->{poe_ports}->{$2} = $1 . '.' . $2;
    }

    $options{datas}->{optical_ports} = {};
    my $oid_hpicfXcvrPortDesc = '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.2';
    $snmp_result = $self->{snmp}->get_table(oid => $oid_hpicfXcvrPortDesc);
    foreach (keys %$snmp_result) {
        next if (! /^$oid_hpicfXcvrPortDesc\.(\d+)$/);
        $options{datas}->{optical_ports}->{$1} = $snmp_result->{$_};
    }
}

my $mapping_optical = {
    module_temperature => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.11'  }, # hpicfXcvrTemp (/1000)
    voltage            => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.12'  }, # hpicfXcvrVoltage
    bias_current       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.13'  }, # hpicfXcvrBias (microamp / 1000)
    output_power       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.14'  }, # hpicfXcvrTxPower (/1000)
    input_power        => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.82.1.1.1.1.15'  }  # hpicfXcvrRxPower (/1000)
};

my $oid_poe_status = '.1.3.6.1.4.1.11.2.14.11.1.9.1.1.1.9'; # hpicfPoePethPsePortOperStatus
my $oid_poe_actual_power = '.1.3.6.1.4.1.11.2.14.11.1.9.1.1.1.8'; # hpicfPoePethPsePortActualPower

my $map_poe_status = { 1 => 'deny', 2 => 'off', 3 => 'on' };

sub custom_load {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{add_poe})) {
        my $ports = $self->{statefile_cache}->get(name => 'poe_ports');
        my $instances = [];
        foreach (@{$self->{array_interface_selected}}) {
            push @$instances, $ports->{$_} if (defined($ports->{$_}));
        }

        if (scalar(@$instances) > 0) {
            $self->{snmp}->load(
                oids => [ $oid_poe_status, $oid_poe_actual_power ],
                instances => $instances,
                instance_regexp => '^(.*)$'
            );
        }
    }

    return if (!defined($self->{option_results}->{add_optical}));

    my $optical_ports = $self->{statefile_cache}->get(name => 'optical_ports');
    $self->{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_optical)) ],
        instances => [keys %$optical_ports]
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{add_poe})) {
        my $ports = $self->{statefile_cache}->get(name => 'poe_ports');

        if (defined($ports->{ $options{instance} })) {
            my $index = $ports->{ $options{instance} };
            if (defined($self->{results}->{$oid_poe_actual_power . '.' . $index})) {
                $self->{int}->{ $options{instance} }->{poe_actual_power} = $self->{results}->{$oid_poe_actual_power . '.' . $index};
            }

            if (defined($self->{results}->{$oid_poe_status . '.' . $index})) {
                $self->{int}->{ $options{instance} }->{poestatus} = $map_poe_status->{ $self->{results}->{$oid_poe_status . '.' . $index} };
            }
        }
    }

    return if (!defined($self->{option_results}->{add_optical}));

    my $optical_ports = $self->{statefile_cache}->get(name => 'optical_ports');
    return if (!defined($optical_ports->{ $options{instance} }));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_optical, results => $self->{results}, instance => $options{instance});

    $self->{int}->{ $options{instance} }->{input_power} = undef;
    if (defined($result->{input_power}) && $result->{input_power} != 0 && $result->{input_power} != -99999999) {
        $self->{int}->{ $options{instance} }->{input_power} = $result->{input_power} / 1000;
    }

    $self->{int}->{$options{instance}}->{bias_current} = undef;
    if (defined($result->{bias_current}) && $result->{bias_current} != 0) {
        $self->{int}->{$options{instance}}->{bias_current} = $result->{bias_current} / 1000;
    }

    $self->{int}->{$options{instance}}->{output_power} = undef;
    if (defined($result->{output_power}) && $result->{output_power} != 0 && $result->{output_power} != -99999999) {
        $self->{int}->{$options{instance}}->{output_power} = $result->{output_power} / 1000;
    }

    $self->{int}->{$options{instance}}->{module_temperature} = undef;
    if (defined($result->{module_temperature}) && $result->{module_temperature} != 0) {
        $self->{int}->{$options{instance}}->{module_temperature} = $result->{module_temperature} / 1000;
    }

    $self->{int}->{$options{instance}}->{voltage} = undef;
    if (defined($result->{voltage}) && $result->{voltage} != 0) {
        $self->{int}->{$options{instance}}->{voltage} = $result->{voltage} / 10000;
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (by default if no --add-* option is set).

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

=item B<--add-poe>

Check power over thernet.

=item B<--add-optical>

Check interface optical metrics.

=item B<--check-metrics>

If the expression is true, metrics are checked (default: '%{opstatus} eq "up"').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-poe-status>

Set warning threshold for poe status.
You can use the following variables: %{admstatus}, %{opstatus}, %{poestatus}, %{display}

=item B<--critical-poe-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{admstatus}, %{opstatus}, %{poestatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s).

And also: 'input-power' (dBm), 'bias-current' (mA), 'output-power' (dBm), 'voltage' (mV), 'module-temperature' (C), 'poe-power-actual'.

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--units-cast>

Units of thresholds for communication types (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with nagvis widget.

=item B<--interface>

Set the interface (number expected) example: 1,2,... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option --interface) by name instead of OID index. The name matching mode supports regular expressions.

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

Define the OID to be used to filter interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding --display-transform-src='eth' --display-transform-dst='ens'  will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface datas.

=back

=cut
