#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::aruba::snmp::mode::apusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'essid', type => 1, cb_prefix_output => 'prefix_essid_output', message_multiple => 'All users by ESSID are ok' },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All users by AP are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Users: %s',
                perfdatas => [
                    { label => 'total', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-none', set => {
                key_values => [ { name => 'total_none' } ],
                output_template => 'Total Auth None: %s',
                perfdatas => [
                    { label => 'total_none', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-other', set => {
                key_values => [ { name => 'total_other' } ],
                output_template => 'Total Auth Other: %s',
                perfdatas => [
                    { label => 'total_other', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-web', set => {
                key_values => [ { name => 'total_web' } ],
                output_template => 'Total Auth Web: %s',
                perfdatas => [
                    { label => 'total_web', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-dot1x', set => {
                key_values => [ { name => 'total_dot1x' } ],
                output_template => 'Total Auth Dot1x: %s',
                perfdatas => [
                    { label => 'total_dot1x', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-vpn', set => {
                key_values => [ { name => 'total_vpn' } ],
                output_template => 'Total Auth Vpn: %s',
                perfdatas => [
                    { label => 'total_vpn', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'total-mac', set => {
                key_values => [ { name => 'total_mac' } ],
                output_template => 'Total Auth Mac: %s',
                perfdatas => [
                    { label => 'total_mac', template => '%s', unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'avg-connection-time', set => {
                key_values => [ { name => 'avg_connection_time' } ],
                output_template => 'Users average connection time: %.3f seconds',
                perfdatas => [
                    { label => 'avg_connection_time', template => '%.3f', unit => 's', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{essid} = [
        { label => 'total-essid', set => {
                key_values => [ { name => 'users' }, { name => 'essid' } ],
                output_template => 'users: %s',
                perfdatas => [
                    { label => 'essid', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'essid' }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'total-ap', set => {
                key_values => [ { name => 'users' }, { name => 'ap_id' } ],
                output_template => 'users: %s',
                perfdatas => [
                    { label => 'ap', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'ap_id' }
                ]
            }
        }
    ];
}

sub prefix_essid_output {
    my ($self, %options) = @_;
    
    return "ESSID '" . $options{instance_value}->{essid} . "' ";
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "AP '" . $options{instance_value}->{ap_id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-ip-address:s' => { name => 'filter_ip_address' },
        'filter-bssid:s'      => { name => 'filter_bssid' },
        'filter-essid:s'      => { name => 'filter_essid' }
    });
                                
    return $self;
}

my $map_auth_method = {
    0 => 'none', 1 => 'web',
    2 => 'mac', 3 => 'vpn',
    4 => 'dot1x', 5 => 'kerberos',
    7 => 'secureId',
    15 => 'pubcookie', 16 => 'xSec',
    17 => 'xSecMachine',
    28 => 'via-vpn',
    255 => 'other'
};
my $map_role = {
    1 => 'master',
    2 => 'local',
    3 => 'standbymaster'
};
my $mapping = {
    nUserUpTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.5' },
    nUserAuthenticationMethod => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.6', map => $map_auth_method }
};
my $mapping2 = {
    nUserApBSSID => { oid => '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1.11' }
};

my $oid_wlsxUserEntry = '.1.3.6.1.4.1.14823.2.2.1.4.1.2.1';
my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';
my $oid_apESSID = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.2';
my $oid_apIpAddress = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.5';
#my $oid_wlanAPName = '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        total => 0, total_none => 0, total_web => 0, total_mac => 0, total_vpn => 0,
        total_dot1x => 0, total_kerberos => 0, total_secureId => 0, total_pubcookie => 0,
        total_xSec => 0, xSecMachine => 0, 'total_via-vpn' => 0, total_other => 0
    };
    $self->{ap} = {};
    $self->{essid} = {};

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ 
            { oid => $oid_wlsxSwitchRole },
            { oid => $oid_wlsxUserEntry, start => $mapping->{nUserUpTime}->{oid}, end => $mapping->{nUserAuthenticationMethod}->{oid} },
            { oid => $mapping2->{nUserApBSSID}->{oid} },
            { oid => $oid_apESSID },
            { oid => $oid_apIpAddress }
        ],
        nothing_quit => 1
    );

    my $role = $map_role->{ $snmp_result->{$oid_wlsxSwitchRole}->{$oid_wlsxSwitchRole . '.0'} };
    if ($role =~ /standbymaster/) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => "Cannot get information. Switch role is '" . $role . "'."
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $map_ap = {};
    foreach my $oid (keys %{$snmp_result->{$oid_apESSID}}) {
        $oid =~ /^$oid_apESSID\.(.*)$/;
        $map_ap->{$1} = { essid => $snmp_result->{$oid_apESSID}->{$oid}, ip => $snmp_result->{$oid_apIpAddress}->{$oid_apIpAddress . '.' .  $1} };
    }

    my $total_timeticks = 0;
    foreach my $oid (keys %{$snmp_result->{$oid_wlsxUserEntry}}) {
        next if ($oid !~ /^$mapping->{nUserAuthenticationMethod}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_wlsxUserEntry}, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{ $mapping2->{nUserApBSSID}->{oid} }, instance => $instance);

        # security
        next if (!defined($result2->{nUserApBSSID}));
        my $bssid = join('.', unpack('C*', $result2->{nUserApBSSID}));
        next if (defined($self->{option_results}->{filter_ip_address}) && $self->{option_results}->{filter_ip_address} ne '' &&
            defined($map_ap->{$bssid}) && $map_ap->{$bssid}->{ip} !~ /$self->{option_results}->{filter_ip_address}/);
        next if (defined($self->{option_results}->{filter_essid}) && $self->{option_results}->{filter_essid} ne '' &&
            defined($map_ap->{$bssid}) && $map_ap->{$bssid}->{essid} !~ /$self->{option_results}->{filter_essid}/);
        next if (defined($self->{option_results}->{filter_bssid}) && $self->{option_results}->{filter_bssid} ne '' &&
            $bssid !~ /$self->{option_results}->{filter_bssid}/);

        my $ap_id = $bssid;
        #$ap_id = $self->{results}->{$oid_wlanAPName}->{$oid_wlanAPName . '.' . $bssid} 
        #    if (defined($self->{results}->{$oid_wlanAPName}->{$oid_wlanAPName . '.' . $bssid}) && $self->{results}->{$oid_wlanAPName}->{$oid_wlanAPName . '.' . $bssid} ne '');
        $self->{ap}->{$bssid} = { users => 0, ap_id => $ap_id } if (!defined($self->{ap}->{$bssid}));
        $self->{ap}->{$bssid}->{users}++;

        if (defined($map_ap->{$bssid})) {
            $self->{essid}->{ $map_ap->{$bssid}->{essid} } = { users => 0, essid => $map_ap->{$bssid}->{essid} } if (!defined($self->{essid}->{ $map_ap->{$bssid}->{essid} }));
            $self->{essid}->{ $map_ap->{$bssid}->{essid} }->{users}++;
        }

        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{nUserAuthenticationMethod}}++;
        $total_timeticks += $result->{nUserUpTime};
    }

    if ($self->{global}->{total} > 0) {
        $self->{global}->{avg_connection_time} = $total_timeticks / $self->{global}->{total} * 0.01;
    }
}

1;

__END__

=head1 MODE

Check total users connected (Deprecated).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-none', 'total-other', 'total-web',
'total-dot1x', 'total-vpn', 'total-mac', 'avg-connection-time' (seconds),
'total-ap', 'total-essid'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-none', 'total-other', 'total-web',
'total-dot1x', 'total-vpn', 'total-mac', 'avg-connection-time' (seconds),
'total-ap', 'total-essid'.

=item B<--filter-ip-address>

Filter by ip address (regexp can be used).

=item B<--filter-essid>

Filter by ESSID (regexp can be used).

=item B<--filter-bssid>

Filter by BSSID (regexp can be used).

=back

=cut
