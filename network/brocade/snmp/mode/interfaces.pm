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

package network::brocade::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_errors {
    my ($self, %options) = @_;

    $self->SUPER::set_oids_errors(%options);
    $self->{oid_in_crc} = '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.22'; # swFCPortRxCrcs
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->SUPER::set_oids_label(%options);
    $self->{oids_label}->{fcportname} =  { oid => '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.36', get => 'reload_get_fcportname', cache => 'reload_cache_fcportname' };
}

sub set_counters_errors {
    my ($self, %options) = @_;

    $self->SUPER::set_counters_errors(%options);
    
    push @{$self->{maps_counters}->{int}}, 
        { label => 'in-crc', filter => 'add_errors', nlabel => 'interface.packets.in.crc.count', set => {
                key_values => [ { name => 'incrc', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'crc' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Crc : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        }
    ;

    push @{$self->{maps_counters}->{int}},
        { label => 'laser-temp', filter => 'add_optical', nlabel => 'interface.laser.temperature.celsius', set => {
                key_values => [ { name => 'laser_temp' }, { name => 'display' } ],
                output_template => 'Laser Temperature : %.2f C', output_error_template => 'Laser Temperature : %.2f',
                perfdatas => [
                    { label => 'laser_temp', template => '%.2f',
                      unit => 'C', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'input-power', filter => 'add_optical', nlabel => 'interface.input.power.dbm', set => {
                key_values => [ { name => 'input_power' }, { name => 'display' } ],
                output_template => 'Input Power : %s dBm', output_error_template => 'Input Power : %s',
                perfdatas => [
                    { label => 'input_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'output-power', filter => 'add_optical', nlabel => 'interface.output.power.dbm', set => {
                key_values => [ { name => 'output_power' }, { name => 'display' } ],
                output_template => 'Output Power : %s dBm', output_error_template => 'Output Power : %s',
                perfdatas => [
                    { label => 'output_power', template => '%s',
                      unit => 'dBm', label_extra_instance => 1, instance_use => 'display' }
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
        'add-optical' => { name => 'add_optical' }
    });

    return $self;
}

sub reload_cache_custom {
    my ($self, %options) = @_;

    $options{datas}->{conn_unit_ports} = {};
    my $oid_connUnitPortPhysicalNumber = '.1.3.6.1.3.94.1.10.1.18';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_connUnitPortPhysicalNumber);
    foreach (keys %$snmp_result) {
        next if (! /^$oid_connUnitPortPhysicalNumber\.(.*)\.(\d+)$/);
        $options{datas}->{conn_unit_ports}->{$2} = $1;
    }
}

sub reload_get_fcportname {
    my ($self, %options) = @_;

    $options{snmp_get}->{fcportname} = { oid => $self->{oids_label}->{fcportname}->{oid} };
    $options{snmp_get}->{ifname} = { oid => $self->{oids_label}->{ifname}->{oid} };
}

sub reload_cache_fcportname {
    my ($self, %options) = @_;

    # I cheat. Yes i can ;) change swFCPortIndex to ifIndex 
    my $store_index = defined($options{store_index}) && $options{store_index} == 1 ? 1 : 0;
    foreach (keys %{$options{result}->{ $self->{oids_label}->{ifname}->{oid} }}) {
        /^$self->{oids_label}->{ifname}->{oid}\.(.*)$/;
        my $if_index = $1;
        push @{$options{datas}->{all_ids}}, $if_index if ($store_index == 1);
        if ($options{result}->{ $self->{oids_label}->{ifname}->{oid} }->{$_} =~ /\d+\/(\d+)$/) {
            $options{datas}->{ $options{name} . '_' . $if_index } = $self->{output}->decode(
                $options{result}->{ $self->{oids_label}->{ $options{name} }->{oid} }->{ $self->{oids_label}->{ $options{name} }->{oid} . '.' . ($1 + 1) }
            );
        } else {
            # we use ifname if there is no fcportname
            $options{datas}->{ $options{name} . '_' . $if_index } = $self->{output}->decode(
                $options{result}->{ $self->{oids_label}->{ifname}->{oid} }->{$_}
            );
        }
    }
}

sub map_brocade {
    my ($self, %options) = @_;

    return if (defined($self->{map_brocade}));

    $self->{map_brocade} = {
        port2if => {},
        if2port => {}
    };
    # swFCPortIndex can be found with ifName ("0/2") or ifDesc ("FC port 0/2")
    foreach (@{$self->{array_interface_selected}}) {
        my $value = $self->{statefile_cache}->get(name => 'ifname_' . $_);
        $value = $self->{statefile_cache}->get(name => 'ifdesc_' . $_) if (!defined($value));
        if (defined($value) && $value =~ /\d+\/(\d+)$/) {
            my $port_index = $1 + 1;
            $self->{map_brocade}->{port2if}->{$port_index} = $_;
            $self->{map_brocade}->{if2port}->{$_} = $port_index;
        }
    }
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

    $self->map_brocade();
    my $indexes = [keys %{$self->{map_brocade}->{port2if}}];
    $self->{snmp}->load(
        oids => [ $self->{oid_in_crc} ],
        instances => $indexes
    ) if (scalar(@$indexes) > 0);
}

my $oid_optical_laser_temp = '.1.3.6.1.4.1.1588.2.1.1.1.28.1.1.1'; # swSfpTemperature
my $oid_optical_input_power = '.1.3.6.1.4.1.1588.2.1.1.1.28.1.1.4'; # swSfpRxPower
my $oid_optical_output_power = '.1.3.6.1.4.1.1588.2.1.1.1.28.1.1.5'; # swSfpTxPower

sub custom_load {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    $self->map_brocade();
    my $ports = $self->{statefile_cache}->get(name => 'conn_unit_ports');
    my $instances = [];
    foreach (keys %{$self->{map_brocade}->{port2if}}) {
        push @$instances, $ports->{$_} . '.' . $_;
    }

    return if (scalar(@$instances) <= 0);

    $self->{snmp}->load(
        oids => [ $oid_optical_laser_temp, $oid_optical_input_power, $oid_optical_output_power ],
        instances => $instances,
        instance_regexp => '^(.*)$'
    );
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{incrc} = defined($self->{map_brocade}->{if2port}->{ $options{instance} }) ?
        $self->{results}->{$self->{oid_in_crc} . '.' . $self->{map_brocade}->{if2port}->{ $options{instance} }} :
        undef;
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_optical}));

    my $ports = $self->{statefile_cache}->get(name => 'conn_unit_ports');
    my $port_index = defined($self->{map_brocade}->{if2port}->{ $options{instance} }) ?
        $self->{map_brocade}->{if2port}->{ $options{instance} } : undef;

    return if (!defined($ports) || !defined($port_index) || !defined($ports->{$port_index}));

    my $index = $ports->{$port_index} . '.' . $port_index;
    if (defined($self->{results}->{$oid_optical_laser_temp . '.' . $index}) &&
        $self->{results}->{$oid_optical_laser_temp . '.' . $index} =~ /(\d+)/) {
        $self->{int}->{ $options{instance} }->{laser_temp} = $1;
    }

    if (defined($self->{results}->{$oid_optical_input_power . '.' . $index}) &&
        $self->{results}->{$oid_optical_input_power . '.' . $index} =~ /(-?\d+(?:\.?\d+)?)/) {
        $self->{int}->{ $options{instance} }->{input_power} = $1;
    }

    if (defined($self->{results}->{$oid_optical_output_power . '.' . $index}) &&
        $self->{results}->{$oid_optical_output_power . '.' . $index} =~ /(-?\d+(?:\.?\d+)?)/) {
        $self->{int}->{ $options{instance} }->{output_power} = $1;
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

Check interface optical.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-crc', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s), 'laser-temp', 'input-power', 'output-power'.

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

Choose OID used to filter interface (default: ifName) (values: fcPortName, ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: fcPortName, ifDesc, ifAlias, ifName, IpAddr).

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
