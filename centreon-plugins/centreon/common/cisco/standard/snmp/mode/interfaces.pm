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

package centreon::common::cisco::standard::snmp::mode::interfaces;

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
    $self->{oid_cErrDisableIfStatusCause} = '.1.3.6.1.4.1.9.9.548.1.3.1.1.2';
    $self->{oid_cErrDisableIfStatusCause_mapping} = {
        1 => 'udld', 2 => 'bpduGuard', 3 => 'channelMisconfig',
        4 => 'pagpFlap', 5 => 'dtpFlap', 6 => 'linkFlap',
        7 => 'l2ptGuard', 8 => 'dot1xSecurityViolation',
        9 => 'portSecurityViolation', 10 => 'gbicInvalid',
        11 => 'dhcpRateLimit', 12 => 'unicastFlood',
        13 => 'vmps', 14 => 'stormControl', 15 => 'inlinePower',
        16 => 'arpInspection', 17 => 'portLoopback',
        18 => 'packetBuffer', 19 => 'macLimit', 20 => 'linkMonitorFailure',
        21 => 'oamRemoteFailure', 22 => 'dot1adIncompEtype', 23 => 'dot1adIncompTunnel',
        24 => 'sfpConfigMismatch', 25 => 'communityLimit', 26 => 'invalidPolicy',
        27 => 'lsGroup', 28 => 'ekey', 29 => 'portModeFailure',
        30 => 'pppoeIaRateLimit', 31 => 'oamRemoteCriticalEvent',
        32 => 'oamRemoteDyingGasp', 33 => 'oamRemoteLinkFault',
        34 => 'mvrp', 35 => 'tranceiverIncomp', 36 => 'other',
        37 => 'portReinitLimitReached', 38 => 'adminRxBBCreditPerfBufIncomp',
        39 => 'ficonNotEnabled', 40 => 'adminModeIncomp', 41 => 'adminSpeedIncomp',
        42 => 'adminRxBBCreditIncomp', 43 => 'adminRxBufSizeIncomp',
        44 => 'eppFailure', 45 => 'osmEPortUp', 46 => 'osmNonEPortUp',
        47 => 'udldUniDir', 48 => 'udldTxRxLoop', 49 => 'udldNeighbourMismatch',
        50 => 'udldEmptyEcho', 51 => 'udldAggrasiveModeLinkFailed',
        52 => 'excessivePortInterrupts', 53 => 'channelErrDisabled',
        54 => 'hwProgFailed', 55 => 'internalHandshakeFailed',
        56 => 'stpInconsistencyOnVpcPeerLink', 57 => 'stpPortStateFailure',
        58 => 'ipConflict', 59 => 'multipleMSapIdsRcvd', 
        60 => 'oneHundredPdusWithoutAck', 61 => 'ipQosCompatCheckFailure',
    };
}

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oid_ifInDiscards} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oid_ifInErrors} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oid_ifOutDiscards} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oid_ifOutErrors} = '.1.3.6.1.2.1.2.2.1.20';
    $self->{oid_ifInCrc} = '.1.3.6.1.4.1.9.2.2.1.1.12';
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
                closure_custom_threshold_check => $self->can('custom_errors_threshold'),
            }
        },
    ;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-err-disable'   => { name => 'add_err_disable' },
    });

    return $self;
}

sub load_errors {
    my ($self, %options) = @_;
    
    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInDiscards}, $self->{oid_ifInErrors},
            $self->{oid_ifOutDiscards}, $self->{oid_ifOutErrors},
            $self->{oid_ifInCrc}
        ],
        instances => $self->{array_interface_selected}
    );
}

sub load_status {
    my ($self, %options) = @_;

    $self->SUPER::load_status(%options);
    if (defined($self->{option_results}->{add_err_disable})) {
        $self->{snmp_errdisable_result} = $self->{snmp}->get_table(oid => $self->{oid_cErrDisableIfStatusCause});
    }    
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{incrc} = $self->{results}->{$self->{oid_ifInCrc} . '.' . $options{instance}};
}

sub add_result_status {
    my ($self, %options) = @_;

    $self->SUPER::add_result_status(%options);

    $self->{int}->{$options{instance}}->{errdisable} = '';
    if (defined($self->{option_results}->{add_err_disable})) {
        my $append = '';
        # ifIndex.vlanIndex (if physical interface, vlanIndex = 0)
        foreach (keys %{$self->{snmp_errdisable_result}}) {
            next if (! /^$self->{oid_cErrDisableIfStatusCause}\.$options{instance}\.(.*)/);
            if ($1 == 0) {
                $self->{int}->{$options{instance}}->{errdisable} = $self->{oid_cErrDisableIfStatusCause_mapping}->{ $self->{snmp_errdisable_result}->{$_} };
                last;
            }
            
            $self->{int}->{$options{instance}}->{errdisable} .= $append . 'vlan' . $1 . ':' . $self->{oid_cErrDisableIfStatusCause_mapping}->{ $self->{snmp_errdisable_result}->{$_} };
            $append = ',';
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
'in-traffic', 'out-traffic', 'in-crc', 'in-error', 'in-discard', 'out-error', 'out-discard',
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
