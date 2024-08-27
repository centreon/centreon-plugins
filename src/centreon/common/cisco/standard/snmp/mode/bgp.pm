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

package centreon::common::cisco::standard::snmp::mode::bgp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Socket;
use Digest::MD5;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [admin status: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{adminStatus}
    );
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    return sprintf(
        "Peer [localAddr: %s, remoteAddr: %s, remoteAs: %s] ",
        $options{instance_value}->{localAddr},
        $options{instance_value}->{remoteAddr},
        $options{instance_value}->{remoteAs}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of peers ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All BGP peers are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'peers-detected', nlabel => 'bgp.peers.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', type => 2, critical_default => '%{adminStatus} =~ /start/ && %{state} !~ /established/', set => {
                key_values => [
                    { name => 'adminStatus' }, { name => 'state' },
                    { name => 'localAddr' }, { name => 'remoteAddr' }, { name => 'remoteAs' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'peer-update-last', nlabel => 'bgp.peer.update.last.seconds', set => {
                key_values => [ { name => 'last_update' } ],
                output_template => 'last update: %s s',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'peer-prefixes-accepted', nlabel => 'bgp.peer.prefixes.accepted.count', set => {
                key_values => [ { name => 'acceptedPrefixes', diff => 1 } ],
                output_template => 'prefixes accepted: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'peer-prefixes-denied', nlabel => 'bgp.peer.prefixes.denied.count', set => {
                key_values => [ { name => 'deniedPrefixes', diff => 1 } ],
                output_template => 'prefixes denied: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-remote-addr:s' => { name => 'filter_remote_addr' },
        'filter-remote-as:s'   => { name => 'filter_remote_as' }
    });

    return $self;
}

my %map_peer_state = (
    1 => 'idle',
    2 => 'connect',
    3 => 'active',
    4 => 'opensent',
    5 => 'openconfirm',
    6 => 'established'
);

my %map_admin_state = (
    1 => 'stop',
    2 => 'start'
);

my $mapping = {
    state               => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.3', map => \%map_peer_state }, # cbgpPeer2State
    adminStatus         => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.4', map => \%map_admin_state }, # cbgpPeer2AdminStatus
    localAddr           => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.6' }, # cbgpPeer2LocalAddr
    localPort           => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.7' }, # cbgpPeer2LocalPort
    remoteAs            => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.11' }, # cbgpPeer2RemoteAs
    inUpdateElapsedTime => { oid => '.1.3.6.1.4.1.9.9.187.1.2.5.1.27' }  # cbgpPeer2InUpdateElapsedTime
};

sub get_ipv6 {
    my ($self, %options) = @_;

    my $ipv6 = '';
    foreach my $val (split /\./, $options{value}) {
        $ipv6 .= pack('C', $val);
    }

    return Socket::inet_ntop(Socket::AF_INET6, $ipv6);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'cisco_standard_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        Digest::MD5::md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_remote_addr}) ? $self->{option_results}->{filter_remote_addr} : '') . '_' .
            (defined($self->{option_results}->{filter_remote_as}) ? $self->{option_results}->{filter_remote_ass} : '')
        );

    my $oid_remotePort = '.1.3.6.1.4.1.9.9.187.1.2.5.1.10'; # cbgpPeer2RemotePort
    my $snmp_result = $options{snmp}->get_table(oid => $oid_remotePort, nothing_quit => 1);

    $self->{global} = { detected => 0 };
    $self->{peers} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_remotePort\.(\d+)\.(\d+)\.(.*)$/;
        my ($type, $num, $remote_addr) = ($1, $2, $3);
        my $remote;
        if ($type == 1) {
            $remote = $remote_addr . ':' . $snmp_result->{$oid};
        } elsif ($type == 2) {
            $remote = $self->get_ipv6(value => $remote_addr);
            $remote = '[' . $remote . ']:' . $snmp_result->{$oid};
        } else {
            $self->{output}->add_option_msg(short_msg => 'unsupported address type');
            $self->{output}->option_exit();
        }

        next if (defined($self->{option_results}->{filter_remote_addr}) && $self->{option_results}->{filter_remote_addr} ne '' &&
            $remote !~ /$self->{option_results}->{filter_remote_addr}/);

        $self->{global}->{detected}++;
        $self->{peers}->{$remote} = { remoteAddr => $remote, instance => $type . '.' . $num . '.' . $remote_addr };
    }

    return if (scalar(keys %{$self->{peers}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{peers}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    my $oid_acceptedPrefixes = '.1.3.6.1.4.1.9.9.187.1.2.8.1.1'; # cbgpPeer2AcceptedPrefixes
    my $oid_deniedPrefixes   = '.1.3.6.1.4.1.9.9.187.1.2.8.1.2'; # cbgpPeer2DeniedPrefixes
    my $snmp_family = $options{snmp}->get_table(oid => '.1.3.6.1.4.1.9.9.187.1.2.8.1', end => $oid_deniedPrefixes); # cbgpPeer2AddrFamilyPrefixEntry

    foreach (keys %{$self->{peers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{peers}->{$_}->{instance});

        if (defined($self->{option_results}->{filter_remote_as}) && $self->{option_results}->{filter_remote_as} ne '' &&
            $result->{remoteAs} !~ /$self->{option_results}->{filter_remote_as}/) {
            delete $self->{peers}->{$_};
            $self->{global}->{detected}--;
            next;
        }

        my $local;
        # it can be empty
        if (length($result->{localAddr}) == 0) {
            $local = '-';
        } elsif (length($result->{localAddr}) == 4) {
            $local = Socket::inet_ntop(Socket::AF_INET, $result->{localAddr}) . ':' . $result->{localPort};
        } else {
            $local = '[' . Socket::inet_ntop(Socket::AF_INET6, $result->{localAddr}) . ']:' . $result->{localPort};
        }

        $self->{peers}->{$_}->{state} = $result->{state};
        $self->{peers}->{$_}->{adminStatus} = $result->{adminStatus};
        $self->{peers}->{$_}->{remoteAs} = $result->{remoteAs};
        $self->{peers}->{$_}->{localAddr} = $local;
        $self->{peers}->{$_}->{last_update} = $result->{inUpdateElapsedTime};

        foreach my $oid (keys %$snmp_family) {
            next if ($oid !~ /^$oid_acceptedPrefixes\.$self->{peers}->{$_}->{instance}\.(.*)$/);

            $self->{peers}->{$_}->{acceptedPrefixes} = $snmp_family->{$oid};
            $self->{peers}->{$_}->{deniedPrefixes} = $snmp_family->{$oid_deniedPrefixes . '.' . $self->{peers}->{$_}->{instance} . '.' . $1};
        }
    }
}

1;

__END__

=head1 MODE

Check BGP.

=over 8

=item B<--filter-remote-as>

Filter based on remote AS number (regexp allowed)

=item B<--filter-remote-addr>

Filter based on IP of peers (regexp allowed)

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{remoteAddr}, %{remoteAs}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{remoteAddr}, %{remoteAs}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminStatus} =~ /start/ && %{state} !~ /established/').
You can use the following variables: %{adminStatus}, %{state}, %{localAddr}, %{remoteAddr}, %{remoteAs}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'peers-detected', 'peer-update-last', 'peer-prefixes-accepted', 'peer-prefixes-denied'.

=back

=cut
