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

package network::juniper::common::junos::mode::bgppeerstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "[local IP '%s:%s', type '%s', AS '%s'][remote IP '%s:%s', type '%s', AS '%s'] state is '%s', status is '%s'",
        $self->{result_values}->{local_ip},
        $self->{result_values}->{local_port},
        $self->{result_values}->{local_type},
        $self->{result_values}->{local_as},
        $self->{result_values}->{remote_ip},
        $self->{result_values}->{remote_port},
        $self->{result_values}->{remote_type},
        $self->{result_values}->{remote_as},
        $self->{result_values}->{peer_state},
        $self->{result_values}->{peer_status}        
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peers_output', message_multiple => 'All BGP peers are ok' }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', type => 2, critical_default => '%{peer_status} =~ /running/ && %{peer_state} !~ /established/', set => {
                key_values => [
                    { name => 'local_ip' }, { name => 'local_port' },
                    { name => 'local_type' }, { name => 'local_as' },
                    { name => 'remote_ip' }, { name => 'remote_port' },
                    { name => 'remote_type' }, { name => 'remote_as' },
                    { name => 'peer_state' }, { name => 'peer_status' },
                    { name => 'peer_identifier' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{peer_identifier} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-peer:s'      => { name => 'filter_peer' },
        'filter-remote-ip:s' => { name => 'filter_remote_ip' },
        'filter-local-as:s'  => { name => 'filter_local_as' }
    });

    return $self;
}

my $map_peer_state = {
    1 => 'idle', 2 => 'connect', 3 => 'active',
    4 => 'opensent', 5 => 'openconfirm', 6 => 'established'
};

my $map_peer_status = {
    1 => 'halted', 2 => 'running'
};

my $map_type = {
    0 => 'unknown', 1 => 'ipv4', 2 => 'ipv6', 3 => 'ipv4z', 4 => 'ipv6z', 16 => 'dns'
};

my $oid_jnxBgpM2PeerTable = '.1.3.6.1.4.1.2636.5.1.1.2.1.1';

my $mapping = {
    peer_identifier => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.1' }, # jnxBgpM2PeerIdentifier
    peer_state      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.2', map => $map_peer_state }, # jnxBgpM2PeerState
    peer_status     => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.3', map => $map_peer_status }, # jnxBgpM2PeerStatus
    local_type      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.6', map => $map_type }, # jnxBgpM2PeerLocalAddrType
    local_ip        => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.7' }, # jnxBgpM2PeerLocalAddr
    local_port      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.8' }, # jnxBgpM2PeerLocalPort
    local_as        => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.9' }, # jnxBgpM2PeerLocalAs
    remote_type     => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.10', map => $map_type }, # jnxBgpM2PeerRemoteAddrType
    remote_ip       => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.11' }, # jnxBgpM2PeerRemoteAddr
    remote_port     => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.12' }, # jnxBgpM2PeerRemotePort
    remote_as       => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.13' }  # jnxBgpM2PeerRemoteAs
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_jnxBgpM2PeerTable,
        end => $mapping->{remote_as}->{oid},
        nothing_quit => 1
    );

    $self->{peers} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{peer_identifier}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        $result->{peer_identifier} = join('.', map { hex($_) } unpack('(H2)*', $result->{peer_identifier}));
        $result->{local_ip} = join('.', map { hex($_) } unpack('(H2)*', $result->{local_ip}));

        $result->{remote_ip} = defined($result->{remote_ip}) ? join('.', map { hex($_) } unpack('(H2)*', $result->{remote_ip})) : '-';
        $result->{remote_port} = defined($result->{remote_port}) ? $result->{remote_port} : '-';
        $result->{remote_as} = defined($result->{remote_as}) ? $result->{remote_as} : '-';
        $result->{remote_type} = defined($result->{remote_type}) ? $result->{remote_type} : '-';
        $result->{local_as} = defined($result->{local_as}) ? $result->{local_as} : '-';

        my $filtered = 0;
        foreach ((
                ['filter_peer', 'peer_identifier'],
                ['filter_remote_ip', 'remote_ip'],
                ['filter_local_as', 'local_as']
            )) {
            if (defined($self->{option_results}->{ $_->[0] }) && $self->{option_results}->{ $_->[0] } ne '' &&
                $result->{ $_->[1] } !~ /$self->{option_results}->{ $_->[0] }/) {
                $filtered = 1;
                last;
            }
        }
        if ($filtered == 1) {
            $self->{output}->output_add(
                long_msg => "skipping peer '" . $result->{peer_identifier} . "': no matching filter.",
                debug => 1
            );
            next;
        }

        $self->{peers}->{$instance} = $result;
    }

    if (scalar(keys %{$self->{peers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No peers found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check BGP peer state (BGP4-V2-MIB-JUNIPER)

=over 8

=item B<--filter-peer>

Filter by peer identifier (Can be regexp)

=item B<--filter-remote-ip>

Filter by remote ip address (Can be regexp)

=item B<--filter-local-as>

Filter by local AS (Can be regexp)

=item B<--warning-status>

Specify warning threshold.
Can use special variables like %{peer_identifier}, %{peer_state}, %{peer_status},
%{local_type}, %{local_ip}, %{local_port}, %{local_as},
%{remote_type}, %{remote_ip}, %{remote_port}, %{remote_as}

=item B<--critical-status>

Specify critical threshold (Default: '%{peer_status} =~ /running/ && %{peer_state} !~ /established/').
Can use special variables like %{peer_identifier}, %{peer_state}, %{peer_status},
%{local_type}, %{local_ip}, %{local_port}, %{local_as},
%{remote_type}, %{remote_ip}, %{remote_port}, %{remote_as}

=back

=cut
