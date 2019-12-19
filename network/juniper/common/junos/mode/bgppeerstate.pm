#
# Copyright 2019 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("[Local IP '%s:%s', Type '%s', AS '%s'][Remote IP '%s:%s', Type '%s', AS '%s'] State is '%s', Status is '%s'",
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
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{peer_state} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerState'};
    $self->{result_values}->{peer_status} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerStatus'};
    $self->{result_values}->{local_type} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerLocalAddrType'};
    $self->{result_values}->{local_ip} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerLocalAddr'};
    $self->{result_values}->{local_port} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerLocalPort'};
    $self->{result_values}->{local_as} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerLocalAs'};
    $self->{result_values}->{remote_type} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerRemoteAddrType'};
    $self->{result_values}->{remote_ip} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerRemoteAddr'};
    $self->{result_values}->{remote_port} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerRemotePort'};
    $self->{result_values}->{remote_as} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerRemoteAs'};
    $self->{result_values}->{peer_identifier} = $options{new_datas}->{$self->{instance} . '_jnxBgpM2PeerIdentifier'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peers_output',
          message_multiple => 'All BGP peers are ok' },
    ];
    $self->{maps_counters}->{peers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'jnxBgpM2PeerState' }, { name => 'jnxBgpM2PeerStatus' },
                    { name => 'jnxBgpM2PeerLocalAddrType' }, { name => 'jnxBgpM2PeerLocalAddr' },
                    { name => 'jnxBgpM2PeerLocalPort' }, { name => 'jnxBgpM2PeerLocalAs' },
                    { name => 'jnxBgpM2PeerRemoteAddrType' }, { name => 'jnxBgpM2PeerRemoteAddr' },
                    { name => 'jnxBgpM2PeerRemotePort' }, { name => 'jnxBgpM2PeerRemoteAs' },
                    { name => 'jnxBgpM2PeerIdentifier' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{jnxBgpM2PeerIdentifier} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-peer:s"         => { name => 'filter_peer' },
        "filter-as:s"           => { name => 'filter_as' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status',
            default => '%{peer_status} =~ /running/ && %{peer_state} !~ /established/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_peer_state = (
    1 => 'idle',
    2 => 'connect',
    3 => 'active',
    4 => 'opensent',
    5 => 'openconfirm',
    6 => 'established',
);

my %map_peer_status = (
    1 => 'halted',
    2 => 'running',
);

my %map_type = (
    0 => 'unknown',
    1 => 'ipv4',
    2 => 'ipv6',
    3 => 'ipv4z',
    4 => 'ipv6z',
    16 => 'dns',
);

my $oid_jnxBgpM2PeerTable = '.1.3.6.1.4.1.2636.5.1.1.2.1.1';

my $mapping = {
    jnxBgpM2PeerIdentifier      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.1' },
    jnxBgpM2PeerState           => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.2', map => \%map_peer_state },
    jnxBgpM2PeerStatus          => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.3', map => \%map_peer_status },
    jnxBgpM2PeerLocalAddrType   => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.6', map => \%map_type },
    jnxBgpM2PeerLocalAddr       => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.7' },
    jnxBgpM2PeerLocalPort       => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.8' },
    jnxBgpM2PeerLocalAs         => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.9' },
    jnxBgpM2PeerRemoteAddrType  => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.10', map => \%map_type },
    jnxBgpM2PeerRemoteAddr      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.11' },
    jnxBgpM2PeerRemotePort      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.12' },
    jnxBgpM2PeerRemoteAs        => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.13' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peers} = {};

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_jnxBgpM2PeerTable,
        start => $mapping->{jnxBgpM2PeerIdentifier}->{oid},
        end => $mapping->{jnxBgpM2PeerRemoteAs}->{oid},
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{jnxBgpM2PeerIdentifier}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        $result->{jnxBgpM2PeerIdentifier} = join('.', map { hex($_) } unpack('(H2)*', $result->{jnxBgpM2PeerIdentifier}));
        $result->{jnxBgpM2PeerLocalAddr} = join('.', map { hex($_) } unpack('(H2)*', $result->{jnxBgpM2PeerLocalAddr}));
        $result->{jnxBgpM2PeerRemoteAddr} = join('.', map { hex($_) } unpack('(H2)*', $result->{jnxBgpM2PeerRemoteAddr}));

        if (defined($self->{option_results}->{filter_peer}) && $self->{option_results}->{filter_peer} ne '' &&
            $result->{jnxBgpM2PeerIdentifier} !~ /$self->{option_results}->{filter_peer}/) {
            $self->{output}->output_add(
                long_msg => "skipping peer '" . $result->{jnxBgpM2PeerIdentifier} . "': no matching filter.",
                debug => 1
            );
            next;
        }

        $self->{peers}->{$instance} = { %{$result} };
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

=item B<--warning-status>

Specify warning threshold.
Can use special variables like %{peer_identifier}, %{peer_state}, %{peer_status},
%{local_type}, %{local_ip}, %{local_port}, %{local_as},
%{remote_type}, %{remote_ip}, %{remote_port}, %{remote_as}
(Default: '')

=item B<--critical-status>

Specify critical threshold.
Can use special variables like %{peer_identifier}, %{peer_state}, %{peer_status},
%{local_type}, %{local_ip}, %{local_port}, %{local_as},
%{remote_type}, %{remote_ip}, %{remote_port}, %{remote_as}
(Default: '%{peer_status} =~ /running/ && %{peer_state} !~ /established/')

=back

=cut
