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
use Digest::MD5 qw(md5_hex);

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
        { name => 'vdstats', type => 1,  cb_prefix_output => 'prefix_vd_output', message_multiple => 'All virtual domains are OK' },
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPNs states are OK' },
    ];
    $self->{maps_counters}->{vdstats} = [
        { label => 'users', set => {
                key_values => [ { name => 'users' }, { name => 'display' } ],
                output_template => 'Logged users: %s',
                perfdatas => [
                    { label => 'users', value => 'users_absolute', template => '%d',
                      min => 0, unit => 'users', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'sessions', set => {
                key_values => [ { name => 'sessions' }, { name => 'display' } ],
                output_template => 'Active web sessions: %s',
                perfdatas => [
                    { label => 'sessions', value => 'sessions_absolute', template => '%d',
                      min => 0, unit => 'sessions', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'tunnels', set => {
                key_values => [ { name => 'tunnels' }, { name => 'display' } ],
                output_template => 'Active Tunnels: %s',
                perfdatas => [
                    { label => 'active_tunnels', value => 'tunnels_absolute', template => '%d',
                      min => 0, unit => 'tunnels', label_extra_instance => 1, instance_use => 'display_absolute' },
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
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', diff => 1 }, { name => 'display' } ],
                per_second => 1, output_change_bytes => 1,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', diff => 1 }, { name => 'display' } ],
                per_second => 1, output_change_bytes => 1,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        }
    ];
}

sub prefix_vd_output {
    my ($self, %options) = @_;

    return "Virtual domain '" . $options{instance_value}->{display} . "' ";
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "Link '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-vpn:s"            => { name => 'filter_vpn' },
                                "filter-vdomain:s"        => { name => 'filter_vdomain' },
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
    fgVpnTunEntPhase2Name => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.3' },
    fgVpnTunEntInOctets => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.18' },
    fgVpnTunEntOutOctets => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.19' },
    fgVpnTunEntStatus => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.20', map => \%map_status },
};

my $mapping2 = {
    fgVpnSslStatsLoginUsers => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.2' },
    fgVpnSslStatsActiveWebSessions => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.4' },
    fgVpnSslStatsActiveTunnels => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.6' },
};

my $oid_fgVpnTunTable = '.1.3.6.1.4.1.12356.101.12.2.2.1';
my $oid_fgVpnSslStatsTable = '.1.3.6.1.4.1.12356.101.12.2.3';
my $oid_fgVdEntName = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{cache_name} = "fortigate_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_fgVdEntName },
                                                            { oid => $oid_fgVpnTunTable },
                                                            { oid => $oid_fgVpnSslStatsTable },
                                                         ],
                                                         , nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}->{ $oid_fgVdEntName }}) {
        $oid =~ /^$oid_fgVdEntName\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_fgVpnSslStatsTable}, instance => $instance);
        my $vdomain_name = $self->{results}->{$oid_fgVdEntName}->{$oid_fgVdEntName.'.'.$instance};
        if (defined($self->{option_results}->{filter_vdomain}) && $self->{option_results}->{filter_vdomain} ne '' &&
            $vdomain_name !~ /$self->{option_results}->{filter_vdomain}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $vdomain_name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{vdstats}->{$vdomain_name} = { users => $result->{fgVpnSslStatsLoginUsers},
                                              sessions => $result->{fgVpnSslStatsActiveWebSessions},
                                              tunnels => $result->{fgVpnSslStatsActiveTunnels},
                                              display => $vdomain_name };
    }

    foreach my $oid (sort keys %{$self->{results}->{$oid_fgVpnTunTable}}) {
        next if ($oid !~ /^$mapping->{fgVpnTunEntStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fgVpnTunTable}, instance => $instance);
        if (defined($self->{option_results}->{filter_vpn}) && $self->{option_results}->{filter_vpn} ne '' &&
            $result->{fgVpnTunEntPhase2Name} !~ /$self->{option_results}->{filter_vpn}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{fgVpnTunEntPhase2Name} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{vpn}->{$result->{fgVpnTunEntPhase2Name}} = { state => $result->{fgVpnTunEntStatus},
                                                             traffic_in => $result->{fgVpnTunEntInOctets},
                                                             traffic_out => $result->{fgVpnTunEntOutOctets},
                                                             display => $result->{fgVpnTunEntPhase2Name} };
    }
}

1;

__END__

=head1 MODE

Check Vdomain statistics and VPN state and traffic

=over 8

=item B<--filter-*>

Filter name with regexp. Can be ('vdomain', 'vpn')

=item B<--warning-*>

Warning on counters. Can be ('users', 'sessions', 'tunnels', 'traffic-in', 'traffic-out')

=item B<--critical-*>

Warning on counters. Can be ('users', 'sessions', 'tunnels', 'traffic-in', 'traffic-out')

=item B<--warning-status>

Set warning threshold for status. Use "%{state}" as a special variable.
Useful to be notified when tunnel is up "%{state} eq 'up'"

=item B<--critical-status>

Set critical threshold for status. Use "%{state}" as a special variable.
Useful to be notified when tunnel is up "%{state} eq 'up'"

=back

=cut
