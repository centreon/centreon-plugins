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

package centreon::common::fortinet::fortigate::snmp::mode::vpn;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state is '%s'", $self->{result_values}->{state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
         { name => 'vd', type => 3, cb_prefix_output => 'prefix_vd_output', cb_long_output => 'vd_long_output', indent_long_output => '    ', message_multiple => 'All virtual domains are OK',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vpn', display_long => 1, cb_prefix_output => 'prefix_vpn_output',  message_multiple => 'All vpn are ok', type => 1, skipped_code => { -10 => 1 } }
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
        }
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
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
        'filter-vpn:s'      => { name => 'filter_vpn' },
        'filter-vdomain:s'  => { name => 'filter_vdomain' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} eq "down"' }
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
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_vpn}) ? md5_hex($self->{option_results}->{filter_vpn}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_vdomain}) ? md5_hex($self->{option_results}->{filter_vdomain}) : md5_hex('all'));

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fgVdEntName },
            { oid => $oid_fgVpnSslStatsTable }
        ],
        nothing_quit => 1
    );
    my $snmp_result2 = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{fgVpnTunEntPhase2Name}->{oid} },
            { oid => $oid_fgVpnTunTable, start => $mapping->{fgVpnTunEntInOctets}->{oid} }
        ],
        return_type => 1
    );

    $self->{vd} = {};
    my $duplicated = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_fgVdEntName }}) {
        $oid =~ /^$oid_fgVdEntName\.(.*)$/;
        my $vdom_instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_fgVpnSslStatsTable}, instance => $vdom_instance);
        my $vdomain_name = $snmp_result->{$oid_fgVdEntName}->{$oid_fgVdEntName . '.' . $vdom_instance};
        
        if (defined($self->{option_results}->{filter_vdomain}) && $self->{option_results}->{filter_vdomain} ne '' &&
            $vdomain_name !~ /$self->{option_results}->{filter_vdomain}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $vdomain_name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vd}->{$vdomain_name} = {
            display => $vdomain_name,
            global => {
                users => $result->{fgVpnSslStatsLoginUsers},
                tunnels => $result->{fgVpnSslStatsActiveTunnels},
                sessions => $result->{fgVpnSslStatsActiveWebSessions}
            },
            vpn => {},
        };

        foreach (keys %$snmp_result2) {
            next if (! /^$mapping->{fgVpnTunEntVdom}->{oid}\.(.*)$/ ||
                $snmp_result2->{$_} != $vdom_instance
            );
            my $instance = $1;
            $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result2, instance => $instance);

            if (defined($self->{option_results}->{filter_vpn}) && $self->{option_results}->{filter_vpn} ne '' &&
                $result->{fgVpnTunEntPhase2Name} !~ /$self->{option_results}->{filter_vpn}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $result->{fgVpnTunEntPhase2Name} . "': no matching filter.", debug => 1);
                next;
            }

            my $name = $result->{fgVpnTunEntPhase2Name};
            $name .= '.' . $instance if (defined($duplicated->{$name}));
            if (defined($self->{vd}->{$vdomain_name}->{vpn}->{$name})) {
                $duplicated->{$name} = 1;
                $self->{vd}->{$vdomain_name}->{vpn}->{$name . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$name}->{instance}} = $self->{vd}->{$vdomain_name}->{vpn}->{$name};
                $self->{vd}->{$vdomain_name}->{vpn}->{$name . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$name}->{instance}}->{display} = $name . '.' . $self->{vd}->{$vdomain_name}->{vpn}->{$name}->{instance};
                delete $self->{vd}->{$vdomain_name}->{vpn}->{$name};
                $name = $result->{fgVpnTunEntPhase2Name} . '.' . $instance;
            }

            $self->{vd}->{$vdomain_name}->{vpn}->{$name} = {
                display => $name,
                instance => $instance,
                state => $result->{fgVpnTunEntStatus},
                traffic_in => $result->{fgVpnTunEntInOctets} * 8,
                traffic_out => $result->{fgVpnTunEntOutOctets} * 8
            };
        }
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
