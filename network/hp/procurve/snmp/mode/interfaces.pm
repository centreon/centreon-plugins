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
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-poe' => { name => 'add_poe' }
    });

    return $self;
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
}

my $oid_poe_status = '.1.3.6.1.4.1.11.2.14.11.1.9.1.1.1.9'; # hpicfPoePethPsePortOperStatus
my $oid_poe_actual_power = '.1.3.6.1.4.1.11.2.14.11.1.9.1.1.1.8'; # hpicfPoePethPsePortActualPower

my $map_poe_status = { 1 => 'deny', 2 => 'off', 3 => 'on' };

sub custom_load {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_poe}));

    my $ports = $self->{statefile_cache}->get(name => 'poe_ports');
    my $instances = [];
    foreach (@{$self->{array_interface_selected}}) {
        push @$instances, $ports->{$_} if (defined($ports->{$_}));
    }

    return if (scalar(@$instances) <= 0);

    $self->{snmp}->load(
        oids => [ $oid_poe_status, $oid_poe_actual_power ],
        instances => $instances,
        instance_regexp => '^(.*)$'
    );
}

sub custom_add_result {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_poe}));

    my $ports = $self->{statefile_cache}->get(name => 'poe_ports');

    return if (!defined($ports->{ $options{instance} }));

    my $index = $ports->{ $options{instance} };
    if (defined($self->{results}->{$oid_poe_actual_power . '.' . $index})) {
        $self->{int}->{ $options{instance} }->{poe_actual_power} = $self->{results}->{$oid_poe_actual_power . '.' . $index};
    }

    if (defined($self->{results}->{$oid_poe_status . '.' . $index})) {
        $self->{int}->{ $options{instance} }->{poestatus} = $map_poe_status->{ $self->{results}->{$oid_poe_status . '.' . $index} };
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

=item B<--add-poe>

Check power over thernet.

=item B<--check-metrics>

If the expression is true, metrics are checked (Default: '%{opstatus} eq "up"').

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-poe-status>

Set warning threshold for poe status.
Can used special variables like: %{admstatus}, %{opstatus}, %{poestatus}, %{display}

=item B<--critical-poe-status>

Set critical threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{poestatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s), 'poe-power-actual'.

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
