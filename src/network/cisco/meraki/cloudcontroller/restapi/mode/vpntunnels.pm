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

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ' [mode: ' . $self->{result_values}->{mode} . ']';
}

sub prefix_tunnel_output {
    my ($self, %options) = @_;

    return "vpn tunnel '" . $options{instance_value}->{deviceSerial} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Vpn tunnels ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'tunnels', type => 1, cb_prefix_output => 'prefix_tunnel_output', message_multiple => 'All vpn tunnels are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-online', nlabel => 'vpn.tunnels.online.count', display_ok => 0, set => {
                key_values => [ { name => 'online' }, { name => 'total' } ],
                output_template => 'online: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-offline', nlabel => 'vpn.tunnels.offline.count', display_ok => 0, set => {
                key_values => [ { name => 'offline' }, { name => 'total' } ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-dormant', nlabel => 'vpn.tunnels.dormant.count', display_ok => 0, set => {
                key_values => [ { name => 'dormant' }, { name => 'total' } ],
                output_template => 'dormant: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        {
            label => 'status', type => 2,
            critical_default => '%{status} =~ /offline/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'mode' }, { name => 'deviceSerial' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter-device-serial:s'     => { name => 'filter_device_serial' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datas = $options{custom}->get_datas(skipDevices => 1, skipDevicesStatus => 1, skipNetworks => 1);

    $self->{global} = { total => 0, online => 0, offline => 0, dormant => 0 };
    $self->{tunnels} = {};
    foreach my $id (keys %{$datas->{vpn_tunnels_status}}) {
        next if (defined($self->{option_results}->{filter_network_name}) && $self->{option_results}->{filter_network_name} ne '' &&
            $datas->{vpn_tunnels_status}->{$id}->{networkName} !~ /$self->{option_results}->{filter_network_name}/);

        next if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $datas->{vpn_tunnels_status}->{$id}->{organizationId} !~ /$self->{option_results}->{filter_organization_id}/);
        next if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $datas->{orgs}->{ $datas->{vpn_tunnels_status}->{$id}->{organizationId} }->{name} !~ /$self->{option_results}->{filter_organization_name}/);

        $self->{tunnels}->{$id} = {
            deviceSerial => $id,
            status => $datas->{vpn_tunnels_status}->{$id}->{deviceStatus},
            mode => $datas->{vpn_tunnels_status}->{$id}->{vpnMode}
        };

        $self->{global}->{total}++;
        $self->{global}->{ lc($datas->{vpn_tunnels_status}->{$id}->{deviceStatus}) }++
            if (defined($self->{global}->{ lc($datas->{vpn_tunnels_status}->{$id}->{deviceStatus}) }));
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

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{deviceSerial}, %{mode}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{deviceSerial}, %{mode}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /offline/i').
You can use the following variables: %{status}, %{deviceSerial}, %{mode}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-online', 'total-offline', 'total-dormant'.

=back

=cut
