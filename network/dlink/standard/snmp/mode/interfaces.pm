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

package network::dlink::standard::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{opstatus} . ' (admin: ' . $self->{result_values}->{admstatus} . ')';
    if (defined($self->{instance_mode}->{option_results}->{add_duplex_status})) {
        $msg .= ' (duplex: ' . $self->{result_values}->{duplexstatus} . ')';
    }
    if (defined($self->{instance_mode}->{option_results}->{add_err_disable})) {
        $msg .= ' (error disable: ' . $self->{result_values}->{errdisable} . ')';
    }
    
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->SUPER::custom_status_calc(%options);
    $self->{result_values}->{errdisable} = $options{new_datas}->{$self->{instance} . '_errdisable'};
    return 0;
}

sub set_key_values_status {
    my ($self, %options) = @_;

    return [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'duplexstatus' }, { name => 'errdisable' }, { name => 'display' } ];
}

sub set_oids_status {
    my ($self, %options) = @_;

    $self->SUPER::set_oids_status(%options);
    $self->{oid_dErrDisIfStatusTimeLeft} = '.1.3.6.1.4.1.171.14.45.1.3.1.4';
    $self->{oid_esErrDisIfStatusTimeLeft} = '.1.3.6.1.4.1.171.17.45.1.3.1.4';
    $self->{oid_errDisIfStatusDisReason_mapping} = {
        1 => 'loopbackDetect', 2 => 'l2ptGuard',
        3 => 'psecureViolation', 4 => 'stormControl', 5 => 'bpduProtect',
        6 => 'arpRateLimit', 7 => 'dhcpRateLimit', 8 => 'ddm',
        9 => 'scheduledShutdown', 10 => 'scheduledHibernation', 11 => 'duld'
    };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-err-disable'   => { name => 'add_err_disable' }
    });

    return $self;
}

sub load_status {
    my ($self, %options) = @_;

    $self->SUPER::load_status(%options);
    if (defined($self->{option_results}->{add_err_disable})) {
        $self->{snmp_errdisable_result}->{ $self->{oid_dErrDisIfStatusTimeLeft} } = $self->{snmp}->get_table(oid => $self->{oid_dErrDisIfStatusTimeLeft});
        $self->{snmp_errdisable_result}->{ $self->{oid_esErrDisIfStatusTimeLeft} } = $self->{snmp}->get_table(oid => $self->{oid_esErrDisIfStatusTimeLeft});
    }    
}

sub add_result_status {
    my ($self, %options) = @_;

    $self->SUPER::add_result_status(%options);

    $self->{int}->{ $options{instance} }->{errdisable} = '';
    if (defined($self->{option_results}->{add_err_disable})) {
        my $append = '';
        # ifIndex.vlanIndex (if physical interface, vlanIndex = 0)
        foreach my $branch (($self->{oid_dErrDisIfStatusTimeLeft}, $self->{oid_esErrDisIfStatusTimeLeft})) {
            foreach (keys %{$self->{snmp_errdisable_result}->{$branch}}) {
                next if (! /^$branch\.$options{instance}\.(\d+)\.(\d+)/);
                my ($vlan, $reason) = ($1, $2);
                if ($vlan == 0) {
                    $self->{int}->{ $options{instance} }->{errdisable} = $self->{oid_errDisIfStatusDisReason_mapping}->{$reason};
                    last;
                }

                $self->{int}->{$options{instance}}->{errdisable} .= $append . 'vlan' . $vlan . ':' . $self->{oid_errDisIfStatusDisReason_mapping}->{$reason};
                $append = ',';
            }
        }
    }

    $self->{int}->{$options{instance}}->{errdisable} = '-'
        if ($self->{int}->{$options{instance}}->{errdisable} eq '');
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

=item B<--add-err-disable>

Check error disable (with --warning-status and --critical-status).

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

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

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
