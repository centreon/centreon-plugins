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


package network::stormshield::snmp::mode::networkstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw(is_excluded);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'interfaces',
            type => COUNTER_TYPE_INSTANCE,
            message_multiple => 'All interfaces are OK',
            display_long => 1,
            skipped_code => { NO_VALUE() => 1 }
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
                output_template => 'Interface %{if_name}, Address: %{if_address}, Mask: %{if_mask}, Type: %{if_type}, Is Protected: %{if_protected}'
            }
        },
        {
            label => 'throughput-in',
            nlabel => 'interface.throughput.in.bytespersecond',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_throughput_in' }, { name => 'if_name' } ],
                output_template => 'Throughput In: %s B/s',
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'throughput-out',
            nlabel => 'interface.throughput.out.bytespersecond',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_throughput_out' }, { name => 'if_name' } ],
                output_template => 'Throughput Out: %s B/s',
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'current-tcp',
            nlabel => 'interface.connections.tcp.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_current_tcp' }, { name => 'if_name' } ],
                output_template => 'Current TCP Connections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'current-udp',
            nlabel => 'interface.connections.udp.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_current_udp' }, { name => 'if_name' } ],
                output_template => 'Current UDP Connections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'tcp-in',
            nlabel => 'interface.traffic.tcp.in.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_tcp_in' }, { name => 'if_name' } ],
                output_template => 'TCP In: %s bytes',
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'tcp-out',
            nlabel => 'interface.traffic.tcp.out.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_tcp_out' }, { name => 'if_name' } ],
                output_template => 'TCP Out: %s bytes',
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'udp-in',
            nlabel => 'interface.traffic.udp.in.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_udp_in' }, { name => 'if_name' } ],
                output_template => 'UDP In: %s bytes',
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'udp-out',
            nlabel => 'interface.traffic.udp.out.bytes',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_udp_out' }, { name => 'if_name' } ],
                output_template => 'UDP Out: %s bytes',
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'packets-accepted',
            nlabel => 'interface.packets.accepted.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_pack_accepted' }, { name => 'if_name' } ],
                output_template => 'Packets Accepted: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        },
        {
            label => 'packets-blocked',
            nlabel => 'interface.packets.blocked.count',
            type => COUNTER_KIND_METRIC,
            set => {
                key_values => [ { name => 'if_pack_blocked' }, { name => 'if_name' } ],
                output_template => 'Packets Blocked: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'if_name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '^mgmt' }
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
my @disco_elements = ('if_name', 'if_address', 'if_mask', 'if_type', 'if_protected');

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
        next if (is_excluded($result->{snsifName}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output}));

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

    if (scalar(keys %{$self->{interfaces}}) <= 0 && !$options{disco}) {
        $self->{output}->option_exit(short_msg => 'No interface found.');
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @disco_elements ]);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->manage_selection(%options, disco => 1);
    foreach my $instance (sort keys %{$self->{interfaces}}) {
        $self->{output}->add_disco_entry(map { $_ => $self->{interfaces}->{$instance}->{$_} } @disco_elements);
    }
}

1;

__END__

=head1 MODE

Check Stormshield network statistics per interface: global in/out throughput, TCP/UDP connections and traffic, and accepted/blocked packets.

=over 8

=item B<--include-name>

Filter interfaces by name (can be a regexp).

=item B<--exclude-name>

Exclude interfaces by name (can be a regexp) (default: '^mgmt').

=item B<--warning-throughput-in>

Set the warning threshold for throughput in (bytes per second).

=item B<--critical-throughput-in>

Set the critical threshold for throughput in (bytes per second).

=item B<--warning-throughput-out>

Set the warning threshold for throughput out (bytes per second).

=item B<--critical-throughput-out>

Set the critical threshold for throughput out (bytes per second).

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