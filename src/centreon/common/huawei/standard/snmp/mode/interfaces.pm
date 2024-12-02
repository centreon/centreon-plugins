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

package centreon::common::huawei::standard::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->SUPER::set_counters(%options);

    push @{$self->{maps_counters}->{int}},
        { label => 'input-power', filter => 'add_optical', nlabel => 'interface.input.power.dbm', set => {
                key_values => [ { name => 'input_power' }, { name => 'display' } ],
                output_template => 'Input Power: %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'bias-current', filter => 'add_optical', nlabel => 'interface.bias.current.milliampere', set => {
                key_values => [ { name => 'bias_current' }, { name => 'display' } ],
                output_template => 'Bias Current: %s mA',
                perfdatas => [
                    { template => '%s', unit => 'mA', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'output_power' }, { name => 'display' } ],
                output_template => 'Output Power: %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'module-temperature', filter => 'add_optical', nlabel => 'interface.module.temperature.celsius', set => {
                key_values => [ { name => 'module_temperature' }, { name => 'display' } ],
                output_template => 'Module Temperature: %.2f C',
                perfdatas => [
                    { template => '%.2f', unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
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

my $mapping_optical = {
    module_temperature => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.3.1.5'  }, # hwEntityOpticalTemperature
    bias_current       => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.3.1.7'  }, # hwEntityOpticalBiasCurrent
    input_power        => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.3.1.8'  }, # hwEntityOpticalRxPower
    output_power       => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.3.1.9'  }  # hwEntityOpticalTxPower
};

sub reload_cache_custom {
    my ($self, %options) = @_;

    $options{datas}->{physical_index} = {};
    my $oid_entAliasMappingIdentifier = '.1.3.6.1.2.1.47.1.3.2.1.2';
    my $oid_ifIndex = '.1.3.6.1.2.1.2.2.1.1';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_entAliasMappingIdentifier);
    foreach (keys %$snmp_result) {
        next if ($snmp_result->{$_} !~ /^$oid_ifIndex\.(\d+)/);
        my $ifindex = $1;
        /^$oid_entAliasMappingIdentifier\.(\d+)\./;

        $options{datas}->{physical_index}->{$ifindex} = $1;
    }
}

sub custom_load {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $pindexes = $self->{statefile_cache}->get(name => 'physical_index');
    my $instances = [];
    foreach (@{$self->{array_interface_selected}}) {
        push @$instances, $pindexes->{$_} if (defined($pindexes->{$_}));
    }

    $self->{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping_optical)) ],
        instances => $instances
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $ports = $self->{statefile_cache}->get(name => 'physical_index');
    return if (!defined($ports->{ $options{instance} }));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_optical, results => $self->{results}, instance => $ports->{ $options{instance} });

    if (defined($result->{module_temperature}) && $result->{module_temperature} != -255) {
        $self->{int}->{$options{instance}}->{module_temperature} = $result->{module_temperature};
    }
    if (defined($result->{bias_current}) && $result->{bias_current} != -1) {
        $self->{int}->{$options{instance}}->{bias_current} = $result->{bias_current};
    }
    if (defined($result->{input_power}) && $result->{input_power} != -1) {
        $self->{int}->{$options{instance}}->{input_power} = $result->{input_power} / 100;
    }
    if (defined($result->{output_power}) && $result->{output_power} != -1) {
        $self->{int}->{$options{instance}}->{output_power} = $result->{output_power} / 100;
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item C<--add-global>

Check global port statistics (by default if no --add-* option is set).

=item C<--add-status>

Check interface status.

=item C<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item C<--add-traffic>

Check interface traffic.

=item C<--add-errors>

Check interface errors.

=item C<--add-cast>

Check interface cast.

=item C<--add-speed>

Check interface speed.

=item C<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item C<--add-optical>

Check interfaces' optical metrics.

=item C<--check-metrics>

If the expression is true, metrics are checked (default: '%{opstatus} eq "up"').

=item C<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item C<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item C<--warning-errors>

Set warning threshold for all error counters.

=item C<--critical-errors>

Set critical threshold for all error counters.

=item C<--warning-total-port>

Thresholds.

=item C<--critical-total-port>

Thresholds.

=item C<--warning-total-admin-up>

Thresholds.

=item C<--critical-total-admin-up>

Thresholds.

=item C<--warning-total-admin-down>

Thresholds.

=item C<--critical-total-admin-down>

Thresholds.

=item C<--warning-total-oper-up>

Thresholds.

=item C<--critical-total-oper-up>

Thresholds.

=item C<--warning-total-oper-down>

Thresholds.

=item C<--critical-total-oper-down>

Thresholds.

=item C<--warning-in-traffic>

Thresholds.

=item C<--critical-in-traffic>

Thresholds.

=item C<--warning-out-traffic>

Thresholds.

=item C<--critical-out-traffic>

Thresholds.

=item C<--warning-in-error>

Thresholds.

=item C<--critical-in-error>

Thresholds.

=item C<--warning-in-discard>

Thresholds.

=item C<--critical-in-discard>

Thresholds.

=item C<--warning-out-error>

Thresholds.

=item C<--critical-out-error>

Thresholds.

=item C<--warning-out-discard>

Thresholds.

=item C<--critical-out-discard>

Thresholds.

=item C<--warning-in-ucast>

Thresholds.

=item C<--critical-in-ucast>

Thresholds.

=item C<--warning-in-bcast>

Thresholds.

=item C<--critical-in-bcast>

Thresholds.

=item C<--warning-in-mcast>

Thresholds.

=item C<--critical-in-mcast>

Thresholds.

=item C<--warning-out-ucast>

Thresholds.

=item C<--critical-out-ucast>

Thresholds.

=item C<--warning-out-bcast>

Thresholds.

=item C<--critical-out-bcast>

Thresholds.

=item C<--warning-out-mcast>

Thresholds.

=item C<--critical-out-mcast>

Thresholds.

=item C<--warning-speed>

Thresholds in b/s.

=item C<--critical-speed>

Thresholds in b/s.

=item C<--warning-input-power>

Thresholds in C<dBm>.

=item C<--critical-input-power>

Thresholds in C<dBm>.

=item C<--warning-bias-current>

Thresholds in C<mA>.

=item C<--critical-bias-current>

Thresholds in C<mA>.

=item C<--warning-output-power>

Thresholds in C<dBm>.

=item C<--critical-output-power>

Thresholds in C<dBm>.

=item C<--warning-module-temperature>

Thresholds in °C.

=item C<--critical-module-temperature>

Thresholds in °C.


=item C<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item C<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item C<--units-cast>

Units of thresholds for communication types (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item C<--nagvis-perfdata>

Display traffic perfdata to be compatible with NagVis widget.

=item C<--interface>

Define the interface filter on IDs (OID indexes, e.g.: 1,2,...). If empty, all interfaces will be monitored.
To filter on interface names, see --name.

=item C<--name>

With this option, the interfaces will be filtered by name (given in option --interface) instead of OID index. The name matching mode supports regular expressions.

=item C<--regex-id>

With this option, interface IDs will be filtered using the --interface parameter as a regular expression instead of a list of IDs.

=item C<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item C<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item C<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item C<--force-counters32>

Force to use 32-bits counters (even with SNMP versions 2c and 3). To use when 64 bits counters are buggy.

=item C<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item C<--oid-filter>

Define the OID to be used to filter interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item C<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item C<--oid-extra-display>

Add an OID to display.

=item C<--display-transform-src> C<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding --display-transform-src='eth' --display-transform-dst='ens'  will replace all occurrences of 'eth' with 'ens'

=item C<--show-cache>

Display cache interface data.

=back

=cut
