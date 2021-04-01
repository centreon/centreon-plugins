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

package apps::protocols::bgp::4::mode::bgppeerstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "AS:'" . $self->{result_values}->{as} . "'";
    $msg .= " Local: '" . $self->{result_values}->{local} . "'";
    $msg .= " Remote: '" . $self->{result_values}->{remote} . "'";
    $msg .= " Peer State: '" . $self->{result_values}->{peerstate} . "'";
    $msg .= " Admin State: '" . $self->{result_values}->{adminstate} . "'";

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{adminstate} = $options{new_datas}->{$self->{instance} . '_adminstate'};
    $self->{result_values}->{peerstate} = $options{new_datas}->{$self->{instance} . '_peerstate'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{local} = $options{new_datas}->{$self->{instance} . '_local'};
    $self->{result_values}->{remote} = $options{new_datas}->{$self->{instance} . '_remote'};
    $self->{result_values}->{as} = $options{new_datas}->{$self->{instance} . '_as'};

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
                key_values => [ { name => 'adminstate' }, { name => 'peerstate' }, { name => 'display' },
                                { name => 'local' }, { name => 'remote' }, { name => 'as' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'updates', nlabel => 'bgppeer.update.seconds', set => {
                key_values => [ { name => 'seconds' }, { name => 'display' } ],
                output_template => 'Last update : %ss',
                perfdatas => [
                    { label => 'seconds', value => 'seconds', template => '%s',
                      unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{display} . "' ";
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
            default => '%{adminstate} =~ /start/ && %{peerstate} !~ /established/' },
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

my %map_admin_state = (
    1 => 'stop',
    2 => 'start',
);

my $oid_bgpPeerTable = '.1.3.6.1.2.1.15.3';

my $mapping = {
    bgpPeerState                => { oid => '.1.3.6.1.2.1.15.3.1.2', map => \%map_peer_state },
    bgpPeerAdminStatus          => { oid => '.1.3.6.1.2.1.15.3.1.3', map => \%map_admin_state },
    bgpPeerRemoteAs             => { oid => '.1.3.6.1.2.1.15.3.1.9' },
    bgpPeerLocalAddr            => { oid => '.1.3.6.1.2.1.15.3.1.5' },
    bgpPeerLocalPort            => { oid => '.1.3.6.1.2.1.15.3.1.6' },
    bgpPeerRemoteAddr           => { oid => '.1.3.6.1.2.1.15.3.1.7' },
    bgpPeerRemotePort           => { oid => '.1.3.6.1.2.1.15.3.1.8' },
    bgpPeerInUpdateElpasedTime  => { oid => '.1.3.6.1.2.1.15.3.1.24' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peers} = {};

    my $result = $options{snmp}->get_table(oid => $oid_bgpPeerTable, nothing_quit => 1);
    foreach my $oid (keys %{$result}) {
        next if ($oid !~ /^$mapping->{bgpPeerState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $mapped_value = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $result,
            instance => $instance
        );

        my $local_addr = $mapped_value->{bgpPeerLocalAddr} . ':' . $mapped_value->{bgpPeerLocalPort};
        my $remote_addr = $mapped_value->{bgpPeerRemoteAddr} . ':' . $mapped_value->{bgpPeerRemotePort};

        if (defined($self->{option_results}->{filter_peer}) && $self->{option_results}->{filter_peer} ne '' &&
            $instance !~ /$self->{option_results}->{filter_peer}/) {
            $self->{output}->output_add(
                long_msg => "skipping peer '" . $instance . "': no matching filter.",
                debug => 1
            );
            next;
        }
        if (defined($self->{option_results}->{filter_as}) && $self->{option_results}->{filter_as} ne '' &&
            $instance !~ /$self->{option_results}->{filter_as}/) {
            $self->{output}->output_add(
                long_msg => "skipping AS '" . $mapped_value->{bgpPeerRemoteAs} . "': no matching filter.",
                debug => 1
            );
            next;
        }

        $self->{peers}->{$instance} = {
            adminstate => $mapped_value->{bgpPeerAdminStatus},
            local => $local_addr,
            peerstate => $mapped_value->{bgpPeerState},
            remote => $remote_addr,
            seconds => $mapped_value->{bgpPeerInUpdateElpasedTime},
            as => $mapped_value->{bgpPeerRemoteAs},
            display => $instance
        };
    }

    if (scalar(keys %{$self->{peers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No peers found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check BGP peer state (BGP4-MIB.mib and rfc4273)

=over 8

=item B<--filter-as>

Filter based on AS number (regexp allowed)

=item B<--filter-peer>

Filter based on IP of peers (regexp allowed)

=item B<--warning-updates>

Warning threshold on last update (seconds)

=item B<--critical-updates>

Critical threshold on last update (seconds)

=item B<--warning-status>

Specify admin and peer state that trigger a warning.
Can use special variables like %{adminstate}, %{peerstate},
%{local}, %{remote}, %{as}, %{display}
(Default: '')

=item B<--critical-status>

Specify admin and peer state that trigger a critical.
Can use special variables like %{adminstate}, %{peerstate},
%{local}, %{remote}, %{as}, %{display}
(Default: '%{adminstate} =~ /start/ && %{peerstate} !~ /established/')

=back

=cut
