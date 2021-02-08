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

package network::mrv::optiswitch::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{linkstatus} . ' (oper: ' . $self->{result_values}->{opstatus} . ', ' . 'admin: ' . $self->{result_values}->{admstatus} . ')';
    if (defined($self->{instance_mode}->{option_results}->{add_duplex_status})) {
        $msg .= ' (duplex: ' . $self->{result_values}->{duplexstatus} . ')';
    }
    
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{linkstatus} = $options{new_datas}->{$self->{instance} . '_linkstatus'};
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    $self->{result_values}->{duplexstatus} = $options{new_datas}->{$self->{instance} . '_duplexstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters_global {
    my ($self, %options) = @_;

    $self->SUPER::set_counters_global(%options);

    push @{$self->{maps_counters}->{global}}, 
        { label => 'total-link-up', filter => 'add_global', nlabel => 'total.interfaces.link.up.count', set => {
                key_values => [ { name => 'global_link_up' }, { name => 'total_port' } ],
                output_template => 'LinkStatus Up : %s', output_error_template => 'LinkStatus Up : %s',
                output_use => 'global_link_up',  threshold_use => 'global_link_up',
                perfdatas => [
                    { label => 'total_link_up', value => 'global_link_up', template => '%s',
                      min => 0, max => 'total_port' },
                ],
            }
        },
        { label => 'total-link-down', filter => 'add_global', nlabel => 'total.interfaces.link.down.count', set => {
                key_values => [ { name => 'global_link_down' }, { name => 'total_port' } ],
                output_template => 'LinkStatus Down : %s', output_error_template => 'LinkStatus Down : %s',
                output_use => 'global_link_down',  threshold_use => 'global_link_down',
                perfdatas => [
                    { label => 'total_link_down', value => 'global_link_down', template => '%s',
                      min => 0, max => 'total_port' },
               ],
            }
        },
    ;
}

sub set_counters_errors {
    my ($self, %options) = @_;

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

sub set_key_values_status {
    my ($self, %options) = @_;

    return [ { name => 'linkstatus' }, { name => 'opstatus' }, { name => 'admstatus' }, { name => 'duplexstatus' }, { name => 'display' } ];
}

sub set_oids_status {
    my ($self, %options) = @_;
    
    $self->{oid_linkstatus} = '.1.3.6.1.4.1.6926.2.1.2.1.5';
    $self->{oid_linkstatus_mapping} = {
        1 => 'true', 2 => 'false',
    };
    $self->{oid_adminstatus} = '.1.3.6.1.4.1.6926.2.1.2.1.10';
    $self->{oid_adminstatus_mapping} = {
        1 => 'other', 2 => 'enable', 3 => 'disableByMgmt',
    };
    $self->{oid_opstatus} = '.1.3.6.1.4.1.6926.2.1.2.1.11';
    $self->{oid_opstatus_mapping} = {
        1 => 'other', 2 => 'enabled', 3 => 'disabledByMgmt', 4 => 'disabledByReboot', 5 => 'isolatedByLinkFlapGuard',
        6 => 'isolatedByLinkReflection', 7 => 'isolatedByLinkProtection', 8 => 'isolatedByStpLinkReflection',
        9 => 'isolatedByHotSwap', 10 => 'isolatedByHa', 11 => 'isolatedByStpPortLoop', 12 => 'isolatedByStpOverRate',
        13 => 'isolatedByEthoamOverRate', 14 => 'isolatedByEfmOverRate', 15 => 'isolatedByDot1xOverRate',
        16 => 'isolatedByDot1agOverRate', 17 => 'isolatedByLacpOverRate', 18 => 'isolatedByAhOverRate',
        19 => 'isolatedByUdld', 20 => 'isolatedByShdslLinkDown',
    };
    
    $self->{oid_duplexstatus} = '.1.3.6.1.4.1.6926.2.1.2.1.9';
    $self->{oid_duplexstatus_mapping} = {
        1 => 'other', 3 => 'fullDuplex', 4 => 'halfDuplex',
    };
}

sub set_oids_traffic {
    my ($self, %options) = @_;
    
    $self->{oid_speed64} = '.1.3.6.1.4.1.6926.2.1.2.1.7'; # in Mb/s
    $self->{oid_in64} = '.1.3.6.1.4.1.6926.2.1.5.1.3'; # in B
    $self->{oid_out64} = '.1.3.6.1.4.1.6926.2.1.5.1.8'; # in B
}

sub set_oids_speed {
    my ($self, %options) = @_;
    
    $self->{oid_speed64} = '.1.3.6.1.4.1.6926.2.1.2.1.7'; # in Mb/s
}

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oid_ifInCrc} = '.1.3.6.1.4.1.6926.2.1.5.1.13'; # osPortCntRecvCRCorAlignmentErrs
}

sub set_oids_cast {
    my ($self, %options) = @_;
    
    $self->{oid_ifHCInUcastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.5';
    $self->{oid_ifHCInMulticastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.7';
    $self->{oid_ifHCInBroadcastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.6';
    $self->{oid_ifHCOutUcastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.10';
    $self->{oid_ifHCOutMulticastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.12';
    $self->{oid_ifHCOutBroadcastPkts} = '.1.3.6.1.4.1.6926.2.1.5.1.11';
}

sub default_check_status {
    my ($self, %options) = @_;
    
    return '%{opstatus} eq "enabled" and %{linkstatus} eq "true"';
}

sub default_warning_status {
    my ($self, %options) = @_;
    
    return '';
}

sub default_critical_status {
    my ($self, %options) = @_;
    
    return '%{admstatus} eq "enable" and %{opstatus} eq "enabled" and %{linkstatus} ne "true"';
}

sub default_global_link_up_rule {
    my ($self, %options) = @_;
    
    return '%{linkstatus} eq "true"';
}

sub default_global_link_down_rule {
    my ($self, %options) = @_;
    
    return '%{linkstatus} eq "false"';
}

sub default_global_admin_up_rule {
    my ($self, %options) = @_;
    
    return '%{admstatus} eq "enable"';
}

sub default_global_admin_down_rule {
    my ($self, %options) = @_;
    
    return '%{admstatus} ne "enable"';
}

sub default_global_oper_up_rule {
    my ($self, %options) = @_;
    
    return '%{opstatus} eq "enabled"';
}

sub default_global_oper_down_rule {
    my ($self, %options) = @_;
    
    return '%{opstatus} ne "enabled"';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_set_errors => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "global-link-up-rule:s"    => { name => 'global_link_up_rule', default => $self->default_global_link_up_rule() },
        "global-link-down-rule:s"  => { name => 'global_link_down_rule', default => $self->default_global_link_down_rule() },
    });
    
    return $self;
}

sub load_status {
    my ($self, %options) = @_;
    
    $self->set_oids_status();
    my $oids = [$self->{oid_linkstatus}, $self->{oid_adminstatus}, $self->{oid_opstatus}];
    if (defined($self->{option_results}->{add_duplex_status})) {
        push @$oids, $self->{oid_duplexstatus};
    }
    
    $self->{snmp}->load(oids => $oids, instances => $self->{array_interface_selected});    
}

sub load_traffic {
    my ($self, %options) = @_;

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }

    $self->set_oids_traffic();
    
    $self->{snmp}->load(oids => [$self->{oid_in64}, $self->{oid_out64}], instances => $self->{array_interface_selected});
    if ($self->{get_speed} == 1) {
        $self->{snmp}->load(oids => [$self->{oid_speed64}], instances => $self->{array_interface_selected});
    }
}

sub load_cast {
    my ($self, %options) = @_;
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }

    $self->set_oids_cast();

    $self->{snmp}->load(oids => [$self->{oid_ifHCInUcastPkts}, $self->{oid_ifHCInMulticastPkts}, $self->{oid_ifHCInBroadcastPkts},
                                    $self->{oid_ifHCOutUcastPkts}, $self->{oid_ifHCOutMulticastPkts}, $self->{oid_ifHCOutBroadcastPkts}],
                        instances => $self->{array_interface_selected});
}

sub load_errors {
    my ($self, %options) = @_;
    
    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInCrc}
        ],
        instances => $self->{array_interface_selected}
    );
}

sub load_speed {
    my ($self, %options) = @_;

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    
    $self->set_oids_speed();
    
    $self->{snmp}->load(oids => [$self->{oid_speed64}], instances => $self->{array_interface_selected});
}

sub load_volume {
    my ($self, %options) = @_;

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    
    $self->set_oids_traffic();
    
    $self->{snmp}->load(oids => [$self->{oid_in64}, $self->{oid_out64}], instances => $self->{array_interface_selected});
}

sub add_result_global {
    my ($self, %options) = @_;
    
    foreach (('global_link_up_rule', 'global_link_down_rule', 'global_admin_up_rule', 'global_admin_down_rule', 'global_oper_up_rule', 'global_oper_down_rule')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$$1/g;
        }
    }
    
    $self->{global} = { total_port => 0, global_link_up => 0, global_link_down => 0, global_admin_up => 0,
                        global_admin_down => 0, global_oper_up => 0, global_oper_down => 0};
    foreach (@{$self->{array_interface_selected}}) {
        my $linkstatus = $self->{oid_linkstatus_mapping}->{$self->{results}->{$self->{oid_linkstatus} . '.' . $_}};
        my $opstatus = $self->{oid_opstatus_mapping}->{$self->{results}->{$self->{oid_opstatus} . '.' . $_}};
        my $admstatus = $self->{oid_adminstatus_mapping}->{$self->{results}->{$self->{oid_adminstatus} . '.' . $_}};
        foreach (('global_link_up', 'global_link_down', 'global_admin_up', 'global_admin_down', 'global_oper_up', 'global_oper_down')) {
            eval {
                local $SIG{__WARN__} = sub { return ; };
                local $SIG{__DIE__} = sub { return ; };
        
                if (defined($self->{option_results}->{$_ . '_rule'}) && $self->{option_results}->{$_ . '_rule'} ne '' &&
                    eval "$self->{option_results}->{$_ . '_rule'}") {
                    $self->{global}->{$_}++;
                }
            };
        }
        $self->{global}->{total_port}++;
    }
}

sub add_result_status {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{linkstatus} = defined($self->{results}->{$self->{oid_linkstatus} . '.' . $options{instance}}) ? $self->{oid_linkstatus_mapping}->{$self->{results}->{$self->{oid_linkstatus} . '.' . $options{instance}}} : undef;
    $self->{int}->{$options{instance}}->{opstatus} = defined($self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}) ? $self->{oid_opstatus_mapping}->{$self->{results}->{$self->{oid_opstatus} . '.' . $options{instance}}} : undef;
    $self->{int}->{$options{instance}}->{admstatus} = defined($self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}) ? $self->{oid_adminstatus_mapping}->{$self->{results}->{$self->{oid_adminstatus} . '.' . $options{instance}}} : undef;
    $self->{int}->{$options{instance}}->{duplexstatus} = defined($self->{results}->{$self->{oid_duplexstatus} . '.' . $options{instance}}) ? $self->{oid_duplexstatus_mapping}->{$self->{results}->{$self->{oid_duplexstatus} . '.' . $options{instance}}} : 'n/a';
}

sub add_result_traffic {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{mode_traffic} = 64;
    $self->{int}->{$options{instance}}->{in} = $self->{results}->{$self->{oid_in64} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{out} = $self->{results}->{$self->{oid_out64} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{in} *= 8 if (defined($self->{int}->{$options{instance}}->{in}));
    $self->{int}->{$options{instance}}->{out} *= 8 if (defined($self->{int}->{$options{instance}}->{out}));
    $self->{int}->{$options{instance}}->{speed_in} = 0;
    $self->{int}->{$options{instance}}->{speed_out} = 0;
    if ($self->{get_speed} == 0) {
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed} * 1000000;
            $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed} * 1000000;
        }
        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    } else {
        my $interface_speed = 0;
        $interface_speed = $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} * 1000000;        
        $self->{int}->{$options{instance}}->{speed_in} = $interface_speed;
        $self->{int}->{$options{instance}}->{speed_out} = $interface_speed;
        $self->{int}->{$options{instance}}->{speed_in} = $self->{option_results}->{speed_in} * 1000000 if (defined($self->{option_results}->{speed_in}) && $self->{option_results}->{speed_in} ne '');
        $self->{int}->{$options{instance}}->{speed_out} = $self->{option_results}->{speed_out} * 1000000 if (defined($self->{option_results}->{speed_out}) && $self->{option_results}->{speed_out} ne '');
    }
}
    
sub add_result_cast {
    my ($self, %options) = @_;
    
    my $iucast = $self->{results}->{$self->{oid_ifHCInUcastPkts} . '.' . $options{instance}};
    if (defined($iucast) && $iucast =~ /[1-9]/) {
        $self->{int}->{$options{instance}}->{iucast} = $iucast;
        $self->{int}->{$options{instance}}->{imcast} = defined($self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInMulticastPkts} . '.' . $options{instance}} : 0;
        $self->{int}->{$options{instance}}->{ibcast} = defined($self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCInBroadcastPkts} . '.' . $options{instance}} : 0;
        $self->{int}->{$options{instance}}->{oucast} = $self->{results}->{$self->{oid_ifHCOutUcastPkts} . '.' . $options{instance}};
        $self->{int}->{$options{instance}}->{omcast} = defined($self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutMulticastPkts} . '.' . $options{instance}} : 0;
        $self->{int}->{$options{instance}}->{obcast} = defined($self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}}) ? $self->{results}->{$self->{oid_ifHCOutBroadcastPkts} . '.' . $options{instance}} : 0;
        $self->{int}->{$options{instance}}->{mode_cast} = 64;
    }
    
    foreach (('iucast', 'imcast', 'ibcast', 'oucast', 'omcast', 'obcast')) {
        $self->{int}->{$options{instance}}->{$_} = 0 if (!defined($self->{int}->{$options{instance}}->{$_}));
    }
    
    $self->{int}->{$options{instance}}->{total_in_packets} = $self->{int}->{$options{instance}}->{iucast} + $self->{int}->{$options{instance}}->{imcast} + $self->{int}->{$options{instance}}->{ibcast};
    $self->{int}->{$options{instance}}->{total_out_packets} = $self->{int}->{$options{instance}}->{oucast} + $self->{int}->{$options{instance}}->{omcast} + $self->{int}->{$options{instance}}->{obcast};
}

sub add_result_errors {
    my ($self, %options) = @_;

    $self->{int}->{$options{instance}}->{incrc} = $self->{results}->{$self->{oid_ifInCrc} . '.' . $options{instance}};
}

sub add_result_speed {
    my ($self, %options) = @_;
    
    my $interface_speed = 0;
    $interface_speed = $self->{results}->{$self->{oid_speed64} . "." . $options{instance}} * 1000000;
    
    $self->{int}->{$options{instance}}->{speed} = $interface_speed;
}

sub add_result_volume {
    my ($self, %options) = @_;
    
    $self->{int}->{$options{instance}}->{in_volume} = $self->{results}->{$self->{oid_in64} . '.' . $options{instance}};
    $self->{int}->{$options{instance}}->{out_volume} = $self->{results}->{$self->{oid_out64} . '.' . $options{instance}};
}

1;

__END__

=head1 MODE

Check interfaces (OS-PORT-MIB).

=over 8

=item B<--add-global>

Check global port statistics.

=item B<--add-status>

Check interface status (By default if no --add-* option is set).

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

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{linkstatus}, %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "enable" and %{opstatus} eq "enabled" and %{linkstatus} ne "true"').
Can used special variables like: %{linkstatus}, %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down', 'total-link-up', 'total-link-down',
'in-traffic', 'out-traffic', 'in-crc', 'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down', 'total-link-up', 'total-link-down',
'in-traffic', 'out-traffic', 'in-crc', 'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

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

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

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
