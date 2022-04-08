#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package network::huawei::snmp::mode::interfaces;

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

=item B<--check-metrics>

If the expression is true, metrics are checked (Default: '%{opstatus} eq "up"').

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

=item B<--warning-*> B<--critical-*>

Thresholds (will superseed --[warning-critical]-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s).

And also: 'input-power' (dBm), 'bias-current' (mA), 'output-power' (dBm), 'module-temperature' (C).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (Default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'counter').

=item B<--units-cast>

Units of thresholds for communication types (Default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'counter').

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
