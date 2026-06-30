#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::interfaces_disco;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;

sub generic_interface_output {
    my ($self, %options) = @_;
    return sprintf("Interface %s, Address: %s, Mask: %s, Type: %s, Is Protected: %s",
    $self->{result_values}->{if_name},
    $self->{result_values}->{if_address},
    $self->{result_values}->{if_mask},
    $self->{result_values}->{if_type},
    $self->{result_values}->{if_protected},
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { 
            name => 'interfaces', 
            type => COUNTER_TYPE_INSTANCE,
            message_multiple => 'All interfaces are OK',
            display_long => 1,
            skipped_code => { -10 => 1 } 
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'textual-info',
            type => COUNTER_KIND_TEXT,
            set => {
                key_values => [ 
                    { name => 'if_name' },
                    { name => 'if_address' },
                    { name => 'if_mask' },
                    { name => 'if_type' },
                    { name => 'if_protected' }
                ],
                closure_custom_output => $self->can('generic_interface_output'),
            }
        },
        {
            label => 'throughput-in',
            nlabel => 'interface.throughput.in.bitspersecond',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_throughput_in' },
                    { name => 'if_name' }
                ],
                output_template => 'Throughput In: %s b/s',
                perfdatas => [
                    {
                        label => 'throughput_in',
                        value => 'if_throughput_in',
                        template => '%s',
                        unit => 'b/s',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-throughput-in'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-throughput-in'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'throughput-out',
            nlabel => 'interface.throughput.out.bitspersecond',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_throughput_out' },
                    { name => 'if_name' }
                ],
                output_template => 'Throughput Out: %s b/s',
                perfdatas => [
                    {
                        label => 'throughput_out',
                        value => 'if_throughput_out',
                        template => '%s',
                        unit => 'b/s',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-throughput-out'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-throughput-out'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'current-tcp',
            nlabel => 'interface.connections.tcp.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_current_tcp' },
                    { name => 'if_name' }
                ],
                output_template => 'Current TCP Connections: %s',
                perfdatas => [
                    {
                        label => 'current_tcp_con',
                        value => 'if_current_tcp',
                        template => '%s',
                        unit => 'con',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-current-tcp'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-current-tcp'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'current-udp',
            nlabel => 'interface.connections.udp.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_current_udp' },
                    { name => 'if_name' }
                ],
                output_template => 'Current UDP Connections: %s',
                perfdatas => [
                    {
                        label => 'current_udp_con',
                        value => 'if_current_udp',
                        template => '%s',
                        unit => 'con',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-current-udp'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-current-udp'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'tcp-in',
            nlabel => 'interface.traffic.tcp.in.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_tcp_in' },
                    { name => 'if_name' }
                ],
                output_template => 'TCP In: %s bytes',
                perfdatas => [
                    {
                        label => 'tcp_in',
                        value => 'if_tcp_in',
                        template => '%s',
                        unit => 'bytes',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-tcp-in'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-tcp-in'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'tcp-out',
            nlabel => 'interface.traffic.tcp.out.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_tcp_out' },
                    { name => 'if_name' }
                ],
                output_template => 'TCP Out: %s bytes',
                perfdatas => [
                    {
                        label => 'tcp_out',
                        value => 'if_tcp_out',
                        template => '%s',
                        unit => 'bytes',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-tcp-out'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-tcp-out'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'udp-in',
            nlabel => 'interface.traffic.udp.in.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_udp_in' },
                    { name => 'if_name' }
                ],
                output_template => 'UDP In: %s bytes',
                perfdatas => [
                    {
                        label => 'udp_in',
                        value => 'if_udp_in',
                        template => '%s',
                        unit => 'bytes',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-udp-in'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-udp-in'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'udp-out',
            nlabel => 'interface.traffic.udp.out.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_udp_out' },
                    { name => 'if_name' }
                ],
                output_template => 'UDP Out: %s bytes',
                perfdatas => [
                    {
                        label => 'udp_out',
                        value => 'if_udp_out',
                        template => '%s',
                        unit => 'bytes',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-udp-out'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-udp-out'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'packets-accepted',
            nlabel => 'interface.packets.accepted.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_pack_accepted' },
                    { name => 'if_name' }
                ],
                output_template => 'Packets Accepted: %s',
                perfdatas => [
                    {
                        label => 'pack_accepted',
                        value => 'if_pack_accepted',
                        template => '%s',
                        unit => 'packets',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-packets-accepted'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-packets-accepted'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
        {
            label => 'packets-blocked',
            nlabel => 'interface.packets.blocked.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ 
                    { name => 'if_pack_blocked' },
                    { name => 'if_name' }
                ],
                output_template => 'Packets Blocked: %s',
                perfdatas => [
                    {
                        label => 'pack_blocked',
                        value => 'if_pack_blocked',
                        template => '%s',
                        unit => 'packets',
                        min => 0,
                        label_extra_instance => 1,
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-packets-blocked'),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-packets-blocked'),
                        instance_use => 'if_name'
                    }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

my $mapping = {
    snsifName              => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.2' },
    snsifAddr              => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.4' },
    snsifMask              => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.5' },  
    snsifType              => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.6' },
    snsifProtected         => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.37' },
    snsifPktAccepted       => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.11' },
    snsifPktBlocked        => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.12' },
    snsifTcpConnCount      => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.23' },
    snsifUdpConnCount      => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.24' },
    snsifInCurThroughput   => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.25' },
    snsifOutCurThroughput  => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.26' },
    snsifInTcpBytes        => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.31' },
    snsifOutTcpBytes       => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.32' },
    snsifInUdpBytes        => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.33' },
    snsifOutUdpBytes       => { oid => '.1.3.6.1.4.1.11256.1.4.1.1.34' }
};
my $oid_snsifEntry = '.1.3.6.1.4.1.11256.1.4.1.1';


sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_snsifEntry,
        start => $mapping->{snsifName}->{oid},
        end => $mapping->{snsifProtected}->{oid},
    );


    $self->{interfaces} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{snsifName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if ((defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && $result->{snsifName} ne $self->{option_results}->{filter_name}) || ($result->{snsifName} =~ /^mgmt/)) {
            next;
        }
        
        $self->{interfaces}->{$instance} = {
            if_name => $result->{snsifName} // '-',
            if_address => $result->{snsifAddr} // '-',
            if_mask => $result->{snsifMask} // '-',
            if_type => $result->{snsifType} // '-',
            if_protected => ($result->{snsifProtected} ? 'true' : 'false'),
            if_throughput_in => $result->{snsifInCurThroughput} // 0,
            if_throughput_out => $result->{snsifOutCurThroughput} // 0,
            if_current_tcp => $result->{snsifTcpConnCount} // 0,
            if_current_udp => $result->{snsifUdpConnCount} // 0,
            if_tcp_in => $result->{snsifInTcpBytes} // 0,
            if_tcp_out => $result->{snsifOutTcpBytes} // 0,
            if_udp_in => $result->{snsifInUdpBytes} // 0,
            if_udp_out => $result->{snsifOutUdpBytes} // 0,
            if_pack_accepted => $result->{snsifPktAccepted} // 0,
            if_pack_blocked => $result->{snsifPktBlocked} // 0,
        };
    }

    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(
            short_msg => 'No interface found matching: ' . ($self->{option_results}->{filter_name} // '')
        );
        $self->{output}->option_exit();
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['if_name', 'if_address', 'if_mask', 'if_type', 'if_protected', 'if_throughput_in', 'if_throughput_out', 'if_current_tcp', 'if_current_udp', 'if_tcp_in', 'if_tcp_out', 'if_udp_in', 'if_udp_out', 'if_pack_accepted', 'if_pack_blocked']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{interfaces}}) {
        $self->{output}->add_disco_entry(%{$self->{interfaces}->{$instance}});
    }
}

1;

__END__

=head1 MODE

This mode retrieves and displays the status of interfaces on the Stormshield device, including their name, global in/out traffic, TCP/UDP in/out traffic, and packet acceptance/blocking statistics.

=over 8

=item B<--filter-name>

Filter by name to only display this interface

=item B<--warning-throughput-in>

Set the warning threshold for throughput in (bits per second).

=item B<--critical-throughput-in>

Set the critical threshold for throughput in (bits per second).

=item B<--warning-throughput-out>

Set the warning threshold for throughput out (bits per second).

=item B<--critical-throughput-out>

Set the critical threshold for throughput out (bits per second).

=item B<--warning-current-tcp>

Set the warning threshold for current TCP connections.

=item B<--critical-current-tcp>

Set the critical threshold for current TCP connections.

=item B<--warning-current-udp>

Set the warning threshold for current UDP connections.

=item B<--critical-current-udp>

Set the critical threshold for current UDP connections.

=item B<--warning-tcp-in>

Set the warning threshold for TCP in traffic (bytes).

=item B<--critical-tcp-in>

Set the critical threshold for TCP in traffic (bytes).

=item B<--warning-tcp-out>

Set the warning threshold for TCP out traffic (bytes).

=item B<--critical-tcp-out>

Set the critical threshold for TCP out traffic (bytes).

=item B<--warning-udp-in>

Set the warning threshold for UDP in traffic (bytes).

=item B<--critical-udp-in>

Set the critical threshold for UDP in traffic (bytes).

=item B<--warning-udp-out>

Set the warning threshold for UDP out traffic (bytes).

=item B<--critical-udp-out>

Set the critical threshold for UDP out traffic (bytes).

=item B<--warning-packets-accepted>

Set the warning threshold for packets accepted.

=item B<--critical-packets-accepted>

Set the critical threshold for packets accepted.

=item B<--warning-packets-blocked>

Set the warning threshold for packets blocked.

=item B<--critical-packets-blocked>

Set the critical threshold for packets blocked.

=back

=cut