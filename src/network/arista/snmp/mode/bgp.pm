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

package network::arista::snmp::mode::bgp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw/:values/;
use centreon::plugins::misc qw/flatten_arrays is_excluded format_opt/;
use Socket qw/inet_ntop/;
use Digest::MD5 qw/md5_hex/;

my @_options = ( 'include_remote_addr', 'exclude_remote_addr', 'include_remote_as', 'exclude_remote_as',
                 'include_local_addr', 'exclude_local_addr', 'include_local_as', 'exclude_local_as',
                 'include_description', 'exclude_description' );

my %map_peer_state = (
    1 => 'idle',
    2 => 'connect',
    3 => 'active',
    4 => 'opensent',
    5 => 'openconfirm',
    6 => 'established'
);

my %map_admin_state = (
    1 => 'halted',
    2 => 'running'
);

my $mapping = {
    adminStatus         => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.12', map => \%map_admin_state }, # aristaBgp4V2PeerAdminStatus
    state               => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.13', map => \%map_peer_state }, # aristaBgp4V2PeerState
    localAddr           => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.3' }, # aristaBgp4V2PeerLocalAddr
    localPort           => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.6' }, # aristaBgp4V2PeerLocalPort
    localAs             => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.7' },  # aristaBgp4V2PeerLocalAs
    remoteAddr          => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.5' }, # aristaBgp4V2PeerRemoteAddr
    remotePort          => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.9' }, # aristaBgp4V2PeerRemotePort
    remoteAs            => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.10' }, # aristaBgp4V2PeerRemoteAs
    description         => { oid => '.1.3.6.1.4.1.30065.4.1.1.2.1.14' }  # aristaBgp4V2PeerDescription
};

sub custom_status_output {
    my ($self, %options) = @_;

    sprintf(
        'state: %s [admin status: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{adminStatus}
    )
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    "Peer [". (join ', ', map { "$_: $options{instance_value}->{$_}" }
                          grep { $options{instance_value}->{$_} }
                              qw/description localAddr localAs remoteAddr remoteAs/ ). "] ";
}

sub prefix_global_output {
    'number of peers '
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 0);
    bless $self, $class;

    $options{options}->add_options(arguments => {
                                                    map {
                                                        format_opt($_).':s@' => { name => $_ }
                                                    } @_options
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', askipped_code => { NO_VALUE() => 1 } },
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All BGP peers are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'peers-detected', nlabel => 'bgp.peers.detected.count', unknown_default => '1:', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', type => 2, critical_default => '%{adminStatus} =~ /running/ && %{state} !~ /established/', set => {
                key_values => [ map { { name => $_ } } keys %$mapping ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { 0 },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach @_options;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_State = $mapping->{state}->{oid};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_State, nothing_qeuit => 1);

    $self->{global} = { detected => 0 };
    $self->{peers} = {};

    foreach my $oid (keys %$snmp_result) {
        $self->{output}->option_exit(short_msg => 'unsupported address type')
            unless $oid =~ /^$oid_State\.(([12])\.(\d+)\.(.*))$/;

        my ($ident, $type, $num, $remote_addr) = ($1, $2, $3, $4);

        my $data = $options{snmp}->get_leef(oids => [ map { $_->{oid}.".$ident" } values %$mapping ], dont_quit => 1, default => '');

        $data = $options{snmp}->map_instance(mapping => $mapping, results => $data, instance => $ident);

        next if is_excluded($data->{'localAs'}, $self->{option_results}->{include_local_as}, $self->{option_results}->{exclude_local_as});
        next if is_excluded($data->{'remoteAs'}, $self->{option_results}->{include_remote_as}, $self->{option_results}->{exclude_remote_as});
        next if is_excluded($data->{'description'}, $self->{option_results}->{include_description}, $self->{option_results}->{exclude_description});

        foreach my $addr (qw/local remote/) {
            my $value = $data->{$addr.'Addr'};
            if ($value eq '') {
                $value = '-';
            } elsif (length($value) == 4) {
                $value = inet_ntop(Socket::AF_INET, $value);
            } else {
                $value = '['.inet_ntop(Socket::AF_INET6, $value).']';
            }
            $value .= ':'.$data->{$addr.'Port'} if $data->{$addr.'Port'};
            $data->{$addr.'Addr'} = $value;
        }

        next if is_excluded($data->{'localAddr'}, $self->{option_results}->{include_local_addr}, $self->{option_results}->{exclude_local_addr});
        next if is_excluded($data->{'remoteAddr'}, $self->{option_results}->{include_remote_addr}, $self->{option_results}->{exclude_remote_addr});

        $self->{global}->{detected}++;
        $self->{peers}->{$ident} = { %{$data}, instance => $ident };
    }
}

1;

__END__

=head1 MODE

Check BGP.

=over 8

=item B<--include-local-as>

Filter by peer local AS number (can be a regexp and can be used multiple times or for comma separated values)

=item B<--exclude-local-as>

Exclude by peer local AS number (can be a regexp and can be used multiple times or for comma separated values)

=item B<--include-local-addr>

Filter by peer local IP (can be a regexp and can be used multiple times or for comma separated values)

=item B<--exclude-local-addr>

Exclude by peer local IP (can be a regexp and can be used multiple times or for comma separated values)

=item B<--include-remote-as>

Filter by peer remote AS number (can be a regexp and can be used multiple times or for comma separated values)

=item B<--exclude-remote-as>

Exclude by peer remote AS number (can be a regexp and can be used multiple times or for comma separated values)

=item B<--include-remote-addr>

Filter by peer remote IP (can be a regexp and can be used multiple times or for comma separated values)

=item B<--exclude-remote-addr>

Exclude by peer remote IP (can be a regexp and can be used multiple times or for comma separated values)

=item B<--include-description>

Filter by peer description (can be a regexp and can be used multiple times or for comma separated values)

=item B<--exclude-description>

Exclude by peer description (can be a regexp and can be used multiple times or for comma separated values)

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{localPort}, %{localAs}, %{remoteAddr}, %{remotePort}, %{remoteAs}, %{description}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{localPort}, %{localAs}, %{remoteAddr}, %{remotePort}, %{remoteAs}, %{description}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminStatus} =~ /running/ && %{state} !~ /established/').
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{localPort}, %{localAs}, %{remoteAddr}, %{remotePort}, %{remoteAs}, %{description}

=item B<--unknown-peers-detected>

Thresholds.
Default: --unknown-peers-detected='1:'

=item B<--warning-peers-detected>

Thresholds.

=item B<--critical-peers-datected>

Thresholds.

=back

=cut
