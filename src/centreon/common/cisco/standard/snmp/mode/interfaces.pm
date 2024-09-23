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

    $self->SUPER::set_oids_errors(%options);
    $self->{oid_ifInFCSError} = '.1.3.6.1.2.1.10.7.2.1.3'; # dot3StatsFCSErrors
    $self->{oid_ifInCrc} = '.1.3.6.1.4.1.9.2.2.1.1.12';
}

sub set_counters_errors {
    my ($self, %options) = @_;

    $self->SUPER::set_counters_errors(%options);
    
    push @{$self->{maps_counters}->{int}},
        { label => 'in-traffic-limit', filter => 'add_qos_limit', nlabel => 'interface.traffic.in.limit.bitspersecond', set => {
                key_values => [ { name => 'traffic_in_limit' }, { name => 'display' } ],
                output_template => 'Traffic In Limit : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_limit', template => '%s',
                      unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-traffic-limit', filter => 'add_qos_limit', nlabel => 'interface.traffic.out.limit.bitspersecond', set => {
                key_values => [ { name => 'traffic_out_limit' }, { name => 'display' } ],
                output_template => 'Traffic Out Limit : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_limit', template => '%s',
                      unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'in-crc', filter => 'add_errors', nlabel => 'interface.packets.in.crc.count', set => {
                key_values => [ { name => 'incrc', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'crc' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Crc : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'in-fcserror', filter => 'add_errors', nlabel => 'interface.packets.in.fcserror.count', set => {
                key_values => [ { name => 'infcserror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                closure_custom_calc => $self->can('custom_errors_calc'),
                closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'fcserror' },
                closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In FCS Error : %s',
                closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                closure_custom_threshold_check => $self->can('custom_errors_threshold')
            }
        },
        { label => 'out-fc-wait', filter => 'add_fc_fe_errors', nlabel => 'interface.wait.out.count', set => {
                key_values => [ { name => 'fcTxWait', diff => 1 }, { name => 'display' } ],
                output_template => 'Fc Out Wait : %s',
                perfdatas => [
                    { label => 'fcTxWait', template => '%s', label_extra_instance => 1, instance_use => 'display' }
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
        'add-qos-limit'    => { name => 'add_qos_limit' },
        'add-err-disable'  => { name => 'add_err_disable' },
        'add-fc-fe-errors' => { name => 'add_fc_fe_errors' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{checking} = '';
    foreach (('add_global', 'add_status', 'add_errors', 'add_traffic', 'add_cast', 'add_speed', 'add_volume', 'add_qos_limit', 'add_fc_fe_errors')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{checking} .= $_;
        }
    }
}

sub reload_cache_qos_limit {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_qos_limit}));

    my $map_direction = { 1 => 'input', 2 => 'output' };

    my $mapping = {
        policyDirection => { oid => '.1.3.6.1.4.1.9.9.166.1.1.1.1.3', map => $map_direction }, # cbQosPolicyDirection
        ifIndex         => { oid => '.1.3.6.1.4.1.9.9.166.1.1.1.1.4' } # cbQosIfIndex
    };
    my $mapping2 = {
        configIndex => { oid => '.1.3.6.1.4.1.9.9.166.1.5.1.1.2' }, # cbQosConfigIndex
        objectsType => { oid => '.1.3.6.1.4.1.9.9.166.1.5.1.1.3' }  # cbQosObjectsType
    };

    my $oid_cbQosServicePolicyEntry = '.1.3.6.1.4.1.9.9.166.1.1.1.1';
    my $oid_cbQosObjectsEntry = '.1.3.6.1.4.1.9.9.166.1.5.1.1';
    my $snmp_result = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cbQosServicePolicyEntry, start => $mapping->{policyDirection}->{oid}, end => $mapping->{ifIndex}->{oid} },
            { oid => $oid_cbQosObjectsEntry, start => $mapping2->{configIndex}->{oid}, end => $mapping2->{objectsType}->{oid} },
        ]
    );

    $options{datas}->{qos} = {};
    foreach (keys %{$snmp_result->{$oid_cbQosServicePolicyEntry}}) {
        next if ($_ !~ /^$mapping->{ifIndex}->{oid}\.(.*)$/);
        my $policyIndex = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_cbQosServicePolicyEntry}, instance => $policyIndex);

        foreach (keys %{$snmp_result->{$oid_cbQosObjectsEntry}}) {
            # 7 = police
            next if ($_ !~ /^$mapping2->{objectsType}->{oid}\.$policyIndex\.(.*)$/ || $snmp_result->{$oid_cbQosObjectsEntry}->{$_} != 7);
            my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_cbQosObjectsEntry}, instance => $policyIndex . '.' . $1);

            $options{datas}->{qos}->{ $result->{ifIndex} } = {} if (!defined($options{datas}->{qos}->{ $result->{ifIndex} }));
            $options{datas}->{qos}->{ $result->{ifIndex} }->{ $result->{policyDirection} } = $result2->{configIndex};
        }
    }
}

sub reload_cache_fc_fe_errors {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_fc_fe_errors}));

    my $oid_fcIfWwn = '.1.3.6.1.4.1.9.9.289.1.1.2.1.1';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_fcIfWwn);

    $options{datas}->{fc_fe} = {};
    foreach (keys %$snmp_result) {
        next if ($_ !~ /^$oid_fcIfWwn\.(.*)$/);
        $options{datas}->{fc_fe}->{$1} = { wwn => $snmp_result->{$_} };
    }
}

sub reload_cache_custom {
    my ($self, %options) = @_;

    $self->reload_cache_fc_fe_errors(%options);
    $self->reload_cache_qos_limit(%options);
}

sub custom_load_qos_limit {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_qos_limit}));

    my $oid_cbQosPoliceCfgRate64 = '.1.3.6.1.4.1.9.9.166.1.12.1.1.11';

    my $qos = $self->{statefile_cache}->get(name => 'qos');
    my $instances = [];
    foreach (keys %$qos) {
        push @$instances, $qos->{$_}->{input} if (defined($qos->{$_}->{input}));
        push @$instances, $qos->{$_}->{output} if (defined($qos->{$_}->{output}));
    }

    return if (scalar(@$instances) <= 0);

    $self->{snmp}->load(
        oids => [ $oid_cbQosPoliceCfgRate64 ],
        instances => $instances,
        instance_regexp => '^(.*)$'
    );
}

sub custom_load_fc_fe_errors {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_fc_fe_errors}));

    my $oid_fcIfTxWaitCount = '.1.3.6.1.4.1.9.9.289.1.2.1.1.15';

    my $entries = $self->{statefile_cache}->get(name => 'fc_fe');
    my @instances = keys %$entries;

    return if (scalar(@instances) <= 0);

    $self->{snmp}->load(
        oids => [ $oid_fcIfTxWaitCount ],
        instances => [@instances],
        instance_regexp => '^(.*)$'
    );
}

sub custom_load {
    my ($self, %options) = @_;

    $self->custom_load_fc_fe_errors(%options);
    $self->custom_load_qos_limit(%options);
}

sub load_errors {
    my ($self, %options) = @_;

    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInDiscards}, $self->{oid_ifInErrors},
            $self->{oid_ifOutDiscards}, $self->{oid_ifOutErrors},
            $self->{oid_ifInCrc}, $self->{oid_ifInFCSError}
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
    $self->{int}->{$options{instance}}->{infcserror} = $self->{results}->{$self->{oid_ifInFCSError} . '.' . $options{instance}};
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

sub custom_add_result_qos_limit {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_qos_limit}));

    my $qos = $self->{statefile_cache}->get(name => 'qos');

    return if (!defined($qos->{ $options{instance} }));

    my $oid_cbQosPoliceCfgRate64 = '.1.3.6.1.4.1.9.9.166.1.12.1.1.11';

    if (defined($qos->{ $options{instance} }->{input}) &&
        defined($self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{input}}) &&
        $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{input}} =~ /(\d+)/) {
        $self->{int}->{ $options{instance} }->{traffic_in_limit} = $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{input}};

        $self->{int}->{ $options{instance} }->{speed_in} = $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{input}}
            if (!defined($self->{option_results}->{speed_in}) || $self->{option_results}->{speed_in} eq '');
    }

    if (defined($qos->{ $options{instance} }->{output}) &&
        defined($self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{output}}) &&
        $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{output}} =~ /(\d+)/) {
        $self->{int}->{ $options{instance} }->{traffic_out_limit} = $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{output}};

        $self->{int}->{ $options{instance} }->{speed_out} = $self->{results}->{$oid_cbQosPoliceCfgRate64 . '.' . $qos->{ $options{instance} }->{output}}
            if (!defined($self->{option_results}->{speed_out}) || $self->{option_results}->{speed_out} eq '');
    }
}

sub custom_add_result_fc_fe_errors {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_fc_fe_errors}));

    my $entries = $self->{statefile_cache}->get(name => 'fc_fe');

    return if (!defined($entries->{ $options{instance} }));

    my $oid_fcIfTxWaitCount = '.1.3.6.1.4.1.9.9.289.1.2.1.1.15';

    if (defined($self->{results}->{ $oid_fcIfTxWaitCount . '.' . $options{instance} }) &&
        $self->{results}->{ $oid_fcIfTxWaitCount . '.' . $options{instance} } =~ /(\d+)/) {
        $self->{int}->{ $options{instance} }->{fcTxWait} = $self->{results}->{ $oid_fcIfTxWaitCount . '.' . $options{instance} };
    }
}

sub custom_add_result {
    my ($self, %options) = @_;

    $self->custom_add_result_fc_fe_errors(%options);
    $self->custom_add_result_qos_limit(%options);
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

=item B<--add-err-disable>

Check error disable (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-fc-fe-errors>

Check interface fiber channel fiber element errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--add-qos-limit>

Check QoS traffic limit rate.

=item B<--check-metrics>

If the expression is true, metrics are checked (default: '%{opstatus} eq "up"').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{errdisable}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-traffic-limit', 'out-traffic-limit',
'in-crc', 'in-fcserror', 'out-fc-wait', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s).

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--units-cast>

Units of thresholds for communication types (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with NagVis widget.

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

Force to use 32 bits counters (even in SNMP version 2c and version 3). Should be used when 64 bits counters are buggy.

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

Display cache interface data.

=back

=cut