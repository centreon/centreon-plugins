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

package network::cisco::meraki::cloudcontroller::restapi::mode::vpntunnels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_device_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{deviceStatus} . ' [mode: ' . $self->{result_values}->{deviceMode} . ']';
}

sub custom_vpn_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{vpnStatus};
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "vpn tunnel '" . $options{instance_value}->{vpnName} . "' [type: " . $options{instance_value}->{vpnType} . "] ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of VPNS ';
}

sub device_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking device '%s'",
        $options{instance_value}->{serial}
    );
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return sprintf(
        "device '%s' ",
        $options{instance_value}->{serial}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok', 
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vpns', type => 1, display_long => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPNs are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];
 
    $self->{maps_counters}->{global} = [
        { label => 'total-unreachable', nlabel => 'vpn.tunnels.unreachable.count', display_ok => 0, set => {
                key_values => [ { name => 'unreachable' }, { name => 'total' } ],
                output_template => 'unreachable: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'device-status',
            type => 2,
            unknown_default => '%{status} =~ /offline/i',
            set => {
                key_values => [ { name => 'deviceStatus' }, { name => 'deviceMode' }, { name => 'deviceSerial' } ],
                closure_custom_output => $self->can('custom_device_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{vpns} = [
        {
            label => 'vpn-status',
            type => 2,
            critical_default => '%{deviceStatus} =~ /online/i and %{vpnStatus} =~ /unreachable/i',
            set => {
                key_values => [
                    { name => 'vpnStatus' }, { name => 'vpnName' }, { name => 'vpnType' },
                    { name => 'deviceStatus' }, { name => 'deviceSerial' }
                ],
                closure_custom_output => $self->can('custom_vpn_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-network-name:s'      => { name => 'filter_network_name' },
        'filter-organization-name:s' => { name => 'filter_organization_name' },
        'filter-organization-id:s'   => { name => 'filter_organization_id' },
        'filter-device-serial:s'     => { name => 'filter_device_serial' },
        'filter-vpn-type:s'          => { name => 'filter_vpn_type' },
        'filter-vpn-name:s'          => { name => 'filter_vpn_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datas = $options{custom}->get_datas(skipDevices => 1, skipDevicesStatus => 1, skipNetworks => 1);

    $self->{global} = { unreachable => 0 };
    $self->{devices} = {};
    foreach my $id (keys %{$datas->{vpn_tunnels_status}}) {
        next if (defined($self->{option_results}->{filter_network_name}) && $self->{option_results}->{filter_network_name} ne '' &&
            $datas->{vpn_tunnels_status}->{$id}->{networkName} !~ /$self->{option_results}->{filter_network_name}/);
        next if (defined($self->{option_results}->{filter_device_serial}) && $self->{option_results}->{filter_device_serial} ne '' &&
            $id !~ /$self->{option_results}->{filter_device_serial}/);

        next if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $datas->{vpn_tunnels_status}->{$id}->{organizationId} !~ /$self->{option_results}->{filter_organization_id}/);
        next if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $datas->{orgs}->{ $datas->{vpn_tunnels_status}->{$id}->{organizationId} }->{name} !~ /$self->{option_results}->{filter_organization_name}/);

        $self->{devices}->{$id} = {
            serial => $id,
            status => {
                deviceSerial => $id,
                deviceStatus => $datas->{vpn_tunnels_status}->{$id}->{deviceStatus},
                deviceMode => $datas->{vpn_tunnels_status}->{$id}->{vpnMode}
            },
            vpns => {}
        };

        foreach (@{$datas->{vpn_tunnels_status}->{$id}->{merakiVpnPeers}}) {
            my $type = 'meraki';
            next if (defined($self->{option_results}->{filter_vpn_type}) && $self->{option_results}->{filter_vpn_type} ne '' &&
                $type !~ /$self->{option_results}->{filter_vpn_type}/);
            next if (defined($self->{option_results}->{filter_vpn_name}) && $self->{option_results}->{filter_vpn_name} ne '' &&
                $_->{networkName} !~ /$self->{option_results}->{filter_vpn_name}/);

            $self->{devices}->{$id}->{vpns}->{ $_->{networkName} } = {
                deviceSerial => $id,
                deviceStatus => $datas->{vpn_tunnels_status}->{$id}->{deviceStatus},
                vpnType => $type,
                vpnName => $_->{networkName},
                vpnStatus => $_->{reachability}
            };

            $self->{global}->{total}++;
            $self->{global}->{ lc($_->{reachability}) }++
                if (defined($self->{global}->{ lc($_->{reachability}) }));
        }

        foreach (@{$datas->{vpn_tunnels_status}->{$id}->{thirdPartyVpnPeers}}) {
            my $type = 'thirdParty';
            next if (defined($self->{option_results}->{filter_vpn_type}) && $self->{option_results}->{filter_vpn_type} ne '' &&
                $type !~ /$self->{option_results}->{filter_vpn_type}/);
            next if (defined($self->{option_results}->{filter_vpn_name}) && $self->{option_results}->{filter_vpn_name} ne '' &&
                $_->{name} !~ /$self->{option_results}->{filter_vpn_name}/);

            $self->{devices}->{$id}->{vpns}->{ $_->{name} } = {
                deviceSerial => $id,
                deviceStatus => $datas->{vpn_tunnels_status}->{$id}->{deviceStatus},
                vpnType => $type,
                vpnName => $_->{name},
                vpnStatus => $_->{reachability}
            };

            $self->{global}->{total}++;
            $self->{global}->{ lc($_->{reachability}) }++
                if (defined($self->{global}->{ lc($_->{reachability}) }));
        }
    }

    # we remove entries if there is a --filter-vpn-[type|name] and no --filter-device-serial
    if ((!defined($self->{option_results}->{filter_device_serial}) || $self->{option_results}->{filter_device_serial} eq '') &&
        ((defined($self->{option_results}->{filter_vpn_type}) && $self->{option_results}->{filter_vpn_type} ne '') ||
         (defined($self->{option_results}->{filter_vpn_name}) && $self->{option_results}->{filter_vpn_name} ne ''))
        ) {
        foreach my $id (keys %{$self->{devices}}) {
            delete $self->{devices}->{$id} if (scalar(keys %{$self->{devices}->{$id}->{vpns}}) <= 0);
        }
    }
}

1;

__END__

=head1 MODE

Check VPN tunnels.

=over 8

=item B<--filter-network-name>

Filter VPN tunnels by network name (can be a regexp).

=item B<--filter-organization-id>

Filter VPN tunnels by organization ID (can be a regexp).

=item B<--filter-organization-name>

Filter VPN tunnels by organization name (can be a regexp).

=item B<--filter-device-serial>

Filter VPN tunnels by device serial (can be a regexp).

=item B<--filter-vpn-type>

Filter VPN tunnels by VPN type (can be a regexp).

=item B<--filter-vpn-name>

Filter VPN tunnels by VPN name (can be a regexp).

=item B<--unknown-device-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{deviceStatus} =~ /offline/i').
You can use the following variables: %{deviceStatus}, %{deviceSerial}, %{deviceMode}

=item B<--warning-device-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{deviceStatus}, %{deviceSerial}, %{deviceMode}

=item B<--critical-device-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{deviceStatus}, %{deviceSerial}

=item B<--unknown-vpn-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{vpnStatus}, %{vpnName}, %{vpnType}, %{deviceStatus}, %{deviceSerial}

=item B<--warning-vpn-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{vpnStatus}, %{vpnName}, %{vpnType}, %{deviceStatus}, %{deviceSerial}

=item B<--critical-vpn-status>

Define the conditions to match for the status to be CRITICAL (default: '%{deviceStatus} =~ /online/i and %{vpnStatus} =~ /unreachable/i').
You can use the following variables: %{vpnStatus}, %{vpnName}, %{vpnType}, %{deviceStatus}, %{deviceSerial}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-unreachable'.

=back

=cut
