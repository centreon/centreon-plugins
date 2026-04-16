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

package centreon::common::fortinet::fortigate::snmp::mode::vpn;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc qw/is_excluded is_empty/;
use centreon::plugins::constants qw/:values :counters/;

sub custom_state_output {
    my ($self, %options) = @_;
    return sprintf("VPN state is '%s'", $self->{result_values}->{vpn_state})
        if $self->{result_values}->{vpn_state} =~ /(?:up|down)/;

    return sprintf("VPN state is '%s' (phase2 state is '%s')", $self->{result_values}->{vpn_state}, $self->{result_values}->{phase2_state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
         { name => 'vd', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_vd_output', cb_long_output => 'vd_long_output', indent_long_output => '    ', message_multiple => 'All virtual domains are OK',
            group => [
                { name => 'global', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                { name => 'vpn', display_long => 1, cb_prefix_output => 'prefix_vpn_output',  message_multiple => 'All vpn are ok', type => COUNTER_MULTIPLE_SUBINSTANCE, skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'users', nlabel => 'vpn.users.logged.count', set => {
                key_values => [ { name => 'users' } ],
                output_template => 'Logged users: %s',
                perfdatas => [
                    { label => 'users', template => '%d', min => 0, unit => 'users', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sessions', nlabel => 'vpn.websessions.active.count', set => {
                key_values => [ { name => 'sessions' }],
                output_template => 'Active web sessions: %s',
                perfdatas => [
                    { label => 'sessions', template => '%d', min => 0, unit => 'sessions', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tunnels', nlabel => 'vpn.tunnels.active.count', set => {
                key_values => [ { name => 'tunnels' } ],
                output_template => 'Active tunnels: %s',
                perfdatas => [
                    { label => 'active_tunnels', template => '%d', min => 0, unit => 'tunnels', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'ipsec-tunnels-count', nlabel => 'vpn.ipsec.tunnels.state.count', set => {
                key_values => [ { name => 'ipsec_tunnels_count' } ],
                output_template => 'IPSec tunnels state up: %s',
                perfdatas => [
                    { label => 'ipsec-tunnels-count', template => '%d', min => 0, unit => 'tunnels', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'state' }, {name => 'phase2_state' }, { name => 'vpn_state' }, { name => 'display' } ],
                closure_custom_output => \&custom_state_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'traffic-in', nlabel => 'vpn.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'vpn.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_vd_output {
    my ($self, %options) = @_;

    return "Virtual domain '" . $options{instance_value}->{display} . "' ";
}

sub vd_long_output {
    my ($self, %options) = @_;

    return "checking virtual domain '" . $options{instance_value}->{display} . "'";
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "Link '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-vpn:s'         => { name => 'include_vpn_phase1' },
        'filter-vdomain:s'     => { name => 'include_vdomain' },
        'include-vdomain:s'    => { name => 'include_vdomain',    default => '' },
        'exclude-vdomain:s'    => { name => 'exclude_vdomain',    default => '' },
        'include-vpn-phase1:s' => { name => 'include_vpn_phase1', default => '' },
        'exclude-vpn-phase1:s' => { name => 'exclude_vpn_phase1', default => '' },
        'include-vpn-phase2:s' => { name => 'include_vpn_phase2', default => '' },
        'exclude-vpn-phase2:s' => { name => 'exclude_vpn_phase2', default => '' },
        'warning-status:s'     => { name => 'warning_status',     default => '%{vpn_state} eq "degraded"' },
        'critical-status:s'    => { name => 'critical_status',    default => '%{vpn_state} eq "down"' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $map_status = { 1 => 'down', 2 => 'up' };

my $mapping = {
    fgVpnTunEntPhase1Name => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.2' },
    fgVpnTunEntPhase2Name => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.3' },
    fgVpnTunEntInOctets   => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.18' },
    fgVpnTunEntOutOctets  => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.19' },
    fgVpnTunEntStatus     => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.20', map => $map_status },
    fgVpnTunEntVdom       => { oid => '.1.3.6.1.4.1.12356.101.12.2.2.1.21' }
};

my $mapping2 = {
    fgVpnSslStatsLoginUsers        => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.2' },
    fgVpnSslStatsActiveWebSessions => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.4' },
    fgVpnSslStatsActiveTunnels     => { oid => '.1.3.6.1.4.1.12356.101.12.2.3.1.6' }
};

my $oid_fgVpnTunTable = '.1.3.6.1.4.1.12356.101.12.2.2.1';
my $oid_fgVpnSslStatsTable = '.1.3.6.1.4.1.12356.101.12.2.3';
my $oid_fgVdEntName = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'fortigate_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        sha256_hex(join '_', map { is_empty($self->{option_results}->{$_}) ? 'all' : $self->{option_results}->{$_} } qw/filters_counters include_vpn_phase1 exclude_vpn_phase1 include_vpn_phase2 exclude_vpn_phase2 include_vdomain exclude_vdomain/);

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fgVdEntName },
            { oid => $oid_fgVpnSslStatsTable }
        ],
        nothing_quit => 1
    );
    my $snmp_result2 = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{fgVpnTunEntPhase1Name}->{oid} },
            { oid => $mapping->{fgVpnTunEntPhase2Name}->{oid} },
            { oid => $oid_fgVpnTunTable, start => $mapping->{fgVpnTunEntInOctets}->{oid} }
        ],
        return_type => 1
    );

    $self->{vd} = {};
    my $duplicated = {};
    my $ipsec_tunnels_counter = 0;
    foreach my $oid (keys %{$snmp_result->{ $oid_fgVdEntName }}) {
        $oid =~ /^$oid_fgVdEntName\.(.*)$/;
        my $vdom_instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_fgVpnSslStatsTable}, instance => $vdom_instance);
        my $vdomain_name = $snmp_result->{$oid_fgVdEntName}->{$oid_fgVdEntName . '.' . $vdom_instance};
        
        if (is_excluded($vdomain_name, $self->{option_results}->{include_vdomain}, $self->{option_results}->{exclude_vdomain})) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vdomain_name . "': no matching filter.", debug => 1);
            next
        }

        $self->{vd}->{$vdomain_name} = {
            display => $vdomain_name,
            global => {
                users => $result->{fgVpnSslStatsLoginUsers},
                tunnels => $result->{fgVpnSslStatsActiveTunnels},
                sessions => $result->{fgVpnSslStatsActiveWebSessions},
                ipsec_tunnels_count => $ipsec_tunnels_counter
            },
            vpn => {},
        };


        my %global_state_label;
        my %global_state_up;
        my %global_state_down;

        foreach (keys %$snmp_result2) {
            next if (! /^$mapping->{fgVpnTunEntVdom}->{oid}\.(.*)$/ ||
                $snmp_result2->{$_} != $vdom_instance
            );
            my $instance = $1;
            $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result2, instance => $instance);
            my $p1 = $result->{fgVpnTunEntPhase1Name} // '';
            my $p2 = $result->{fgVpnTunEntPhase2Name} // '';
            my $display_name = $p1 ne '' && $p2 ne '' && $p1 ne $p2 ?
                       $p1 . '#' . $p2 :
                       $p2;

            unless (exists $global_state_label{$p1}) {
                $global_state_label{$p1} = 'unknown';
                $global_state_up{$p1} = 0;
                $global_state_down{$p1} = 0;
            }
            if (is_excluded($p1, $self->{option_results}->{include_vpn_phase1}, $self->{option_results}->{exclude_vpn_phase1})) {
                $self->{output}->output_add(long_msg => "skipping  '$p1': no matching filter.", debug => 1);
                next
            }
            if (is_excluded($p2, $self->{option_results}->{include_vpn_phase2}, $self->{option_results}->{exclude_vpn_phase2})) {
                $self->{output}->output_add(long_msg => "skipping  '$p2': no matching filter.", debug => 1);
                next
            }

            my $id = $display_name;
            $id .= '.' . $instance if exists $duplicated->{$display_name};
            if (defined($self->{vd}->{$vdomain_name}->{vpn}->{$id})) {
                $duplicated->{$id} = 1;
                $self->{vd}->{$vdomain_name}->{vpn}->{$id . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$id}->{instance}} = $self->{vd}->{$vdomain_name}->{vpn}->{$id};
                $self->{vd}->{$vdomain_name}->{vpn}->{$id . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$id}->{instance}}->{display} = $id . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$id}->{instance};
                delete $self->{vd}->{$vdomain_name}->{vpn}->{$id};
                $id = $result->{fgVpnTunEntPhase2Name} . '.' . $instance;
            }
            if ($result->{fgVpnTunEntStatus} eq 'up') {
                $global_state_up{$p1}++;
            } else {
                $global_state_down{$p1}++;
            }

            $self->{vd}->{$vdomain_name}->{vpn}->{$id} = {
                display => $display_name,
                phase1 => $p1,
                phase2 => $p2,
                instance => $instance,
                state => $result->{fgVpnTunEntStatus},
                phase2_state => $result->{fgVpnTunEntStatus},
                vpn_state => '',
                traffic_in => $result->{fgVpnTunEntInOctets} * 8,
                traffic_out => $result->{fgVpnTunEntOutOctets} * 8
            };
            # count tunnels in state up
            if ($self->{vd}->{$vdomain_name}->{vpn}->{$id}->{state} eq "up") {
                $ipsec_tunnels_counter++;
            };
        }

        $self->{vd}->{$vdomain_name}->{global}->{ipsec_tunnels_count} = $ipsec_tunnels_counter;

        foreach my $vpn (values %{$self->{vd}->{$vdomain_name}->{vpn}}) {
            my $p1 = $vpn->{phase1};
            my $vpn_state = 'down';
            if ($global_state_up{$p1} && !$global_state_down{$p1}) {
                $vpn_state = 'up';
            } elsif ($global_state_up{$p1} && $global_state_down{$p1}) {
                $vpn_state = 'degraded';
            }
            $vpn->{vpn_state} = $vpn_state;
        }
    }

    $self->{output}->option_exit(short_msg => 'No matching VPN found.') unless keys %{$self->{vd}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'vdom', 'state' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(snmp => $options{snmp});
    foreach my $vd (sort keys %{$self->{vd}}) {
        foreach my $vpn (sort { $a->{display} cmp $b->{display} } values %{$self->{vd}->{$vd}->{vpn}}) {
            $self->{output}->add_disco_entry(
                name => $vpn->{display},
                vdom => $vd,
                state => $vpn->{state}
            );
        }
    }
}

1;

__END__

=head1 MODE

Check Vdomain statistics and VPN state and traffic

=over 8

=item B<--include-vdomain>

Filter by virtual domain names (regexp).

=item B<--exclude-vdomain>

Exclude by virtual domain names (regexp).

=item B<--include-vpn-phase1>

Filter by VPN phase 1 names (regexp).

=item B<--exclude-vpn-phase1>

Exclude by VPN phase 1 names (regexp).

=item B<--include-vpn-phase2>

Filter by VPN phase 2 names (regexp).

=item B<--exclude-vpn-phase2>

Exclude by VPN phase 2 names (regexp).

=item B<--warning-ipsec-tunnels-count>

Threshold in tunnels.

=item B<--critical-ipsec-tunnels-count>

Threshold in tunnels.

=item B<--warning-sessions>

Threshold in sessions.

=item B<--critical-sessions>

Threshold in sessions.

=item B<--warning-traffic-in>

Threshold in b/s.

=item B<--critical-traffic-in>

Threshold in b/s.

=item B<--warning-traffic-out>

Threshold in b/s.

=item B<--critical-traffic-out>

Threshold in b/s.

=item B<--warning-tunnels>

Threshold in tunnels.

=item B<--critical-tunnels>

Threshold in tunnels.

=item B<--warning-ipsec-tunnels-count>

Threshold in tunnels.

=item B<--critical-ipsec-tunnels-count>

Threshold in tunnels.

=item B<--warning-sessions>

Threshold in sessions.

=item B<--critical-sessions>

Threshold in sessions.

=item B<--warning-traffic-in>

Threshold in b/s.

=item B<--critical-traffic-in>

Threshold in b/s.

=item B<--warning-traffic-out>

Threshold in b/s.

=item B<--critical-traffic-out>

Threshold in b/s.

=item B<--warning-tunnels>

Threshold in tunnels.

=item B<--critical-tunnels>

Threshold in tunnels.

=item B<--warning-users>

Threshold in users.

=item B<--critical-users>

Threshold in users.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
Use %{vpn_state} and %{phase2_state} as special variables (default: C<%{vpn_state} eq "degraded">)
%{vpn_state} represents the overall status of the VPN link: it is C<up> when all Phase 2 tunnels are up, C<down> when all Phase 2 tunnels are down,
and C<degraded> when at least one Phase 2 tunnel is up and at least one is down.
%{phase2_state} is the status of specific Phase 2 tunnel either C<up> or C<down>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
Use %{vpn_state} and %{phase2_state} as special variables (default: C<%{vpn_state} eq "down">)
%{vpn_state} represents the overall status of the VPN link: it is C<up> when all Phase 2 tunnels are up, C<down> when all Phase 2 tunnels are down,
and C<degraded> when at least one Phase 2 tunnel is up and at least one is down.
%{phase2_state} is the status of specific Phase 2 tunnel either C<up> or C<down>.

=back

=cut
