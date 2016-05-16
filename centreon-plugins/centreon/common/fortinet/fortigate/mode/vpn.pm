#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::mode::vpn;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_threshold_output {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s'", $self->{result_values}->{state});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPNs states are OK' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'users', set => {
                key_values => [ { name => 'users' } ],
                output_template => 'Logged users: %s',
                perfdatas => [
                    { label => 'users', value => 'users_absolute', template => '%d',
                      min => 0, unit => 'users' },
                ],
            }
        },
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Active web sessions: %s',
                perfdatas => [
                    { label => 'sessions', value => 'sessions_absolute', template => '%d',
                      min => 0, unit => 'sessions' },
                ],
            }
        },
        { label => 'tunnels', set => {
                key_values => [ { name => 'tunnels' } ],
                output_template => 'Active Tunnels: %s',
                perfdatas => [
                    { label => 'active_tunnels', value => 'tunnels_absolute', template => '%d',
                      min => 0, unit => 'tunnels' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'state', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => \&custom_state_calc,
                closure_custom_output => \&custom_state_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_threshold_output,
            }
        },
    ];
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "Link '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter:s"                => { name => 'filter' },
                                "warning-status:s"        => { name => 'warning_status', default => '' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{state} eq "down"' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros();
    $instance_mode = $self;
}

my %map_status = (
    1 => 'down',
    2 => 'up',
);

my $mapping = {
    fgVpnTunEntPhase2Name               => '.1.3.6.1.4.1.12356.101.12.2.2.1.3',
    fgVpnTunEntStatus                   => '.1.3.6.1.4.1.12356.101.12.2.2.1.20',

    fgVpnSslStatsLoginUsers             => '.1.3.6.1.4.1.12356.101.12.2.3.1.2.1',
    fgVpnSslStatsActiveWebSessions      => '.1.3.6.1.4.1.12356.101.12.2.3.1.4.1',
    fgVpnSslStatsActiveTunnels          => '.1.3.6.1.4.1.12356.101.12.2.3.1.6.1',
};

my $oid_fgVpnTunTable = '.1.3.6.1.4.1.12356.101.12.2.2';
my $oid_fgVpnSslStatsTable = '.1.3.6.1.4.1.12356.101.12.2.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_fgVpnTunTable },
                                                            { oid => $oid_fgVpnSslStatsTable },
                                                         ],
                                                         , nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}->{$oid_fgVpnTunTable}}) {
        next if ($oid !~ /^$mapping->{fgVpnTunEntPhase2Name}\.(.*)$/);
        my $instance = $1;
        my $vpn_name = $self->{results}->{$oid_fgVpnTunTable}->{$mapping->{fgVpnTunEntPhase2Name} . '.' . $instance};
        my $vpn_state = $map_status{$self->{results}->{$oid_fgVpnTunTable}->{$mapping->{fgVpnTunEntStatus} . '.' . $instance}};
        if (defined($self->{option_results}->{filter}) && $self->{option_results}->{filter} ne '' &&
            $vpn_name !~ /$self->{option_results}->{filter}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $vpn_name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{vpn}->{$vpn_name} = { state => $vpn_state, display => $vpn_name };
    }

    $self->{global} = { users => $self->{results}->{$oid_fgVpnSslStatsTable}->{$mapping->{fgVpnSslStatsLoginUsers}},
                        sessions => $self->{results}->{$oid_fgVpnSslStatsTable}->{$mapping->{fgVpnSslStatsActiveWebSessions}},
                        tunnels => $self->{results}->{$oid_fgVpnSslStatsTable}->{$mapping->{fgVpnSslStatsActiveTunnels}}
                        };
}

1;

__END__

=head1 MODE

Check global VPN utilization statistics and VPN link state

=over 8

=item B<--filter-counters>

Warning on statistics. Can be ('users', 'sessions', 'tunnels', 'state')

=item B<--warning-*>

Warning on statistics. Can be ('users', 'sessions', 'tunnels')

=item B<--critical-*>

Warning on statistics. Can be ('users', 'sessions', 'tunnels')

=item B<--warning-status>

Set warning threshold for status. Use "%{state}" as a special variable.
Useful to be notified when tunnel is up "%{state} eq 'up'"

=item B<--critical-status>

Set critical threshold for status. Use "%{state}" as a special variable.
Useful to be notified when tunnel is up "%{state} eq 'up'"

=back

=cut
