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

package network::cisco::meraki::cloudcontroller::restapi::mode::listvpntunnels;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my @labels = (
    'organization_id',
    'organization_name',
    'network_id',
    'network_name',
    'device_serial',
    'device_mode',
    'device_status',
    'vpn_type',
    'vpn_name',
    'vpn_status'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-network-id:s'        => { name => 'filter_network_id' },
        'filter-organization-name:s' => { name => 'filter_organization_name' },
        'filter-organization-id:s'   => { name => 'filter_organization_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $organizations = $options{custom}->get_organizations();
    my $devices = $options{custom}->get_organization_vpn_tunnels_statuses(
        orgs => [keys %$organizations]
    );

    my $results = [];
    foreach my $id (keys %$devices) {
        next if (defined($self->{option_results}->{filter_network_id}) && $self->{option_results}->{filter_network_id} ne '' &&
            $devices->{$id}->{networkId} !~ /$self->{option_results}->{filter_network_id}/);
        next if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $devices->{$id}->{organizationId} !~ /$self->{option_results}->{filter_organization_id}/);

        my $organization_name = $organizations->{ $devices->{$id}->{organizationId} }->{name};
        next if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $organization_name !~ /$self->{option_results}->{filter_organization_name}/);

        foreach (@{$devices->{$id}->{merakiVpnPeers}}) {
            push @$results, {
                network_id   => $devices->{$id}->{networkId},
                network_name => $devices->{$id}->{networkName},
                device_serial => $devices->{$id}->{deviceSerial},
                organization_id => $devices->{$id}->{organizationId},
                organization_name => $organization_name,
                device_mode => $devices->{$id}->{vpnMode},
                device_status => $devices->{$id}->{deviceStatus},
                vpn_type => 'meraki',
                vpn_name =>  $_->{networkName},
                vpn_status => $_->{reachability}
            };
        }

        foreach (@{$devices->{$id}->{thirdPartyVpnPeers}}) {
            push @$results, {
                network_id   => $devices->{$id}->{networkId},
                network_name => $devices->{$id}->{networkName},
                device_serial => $devices->{$id}->{deviceSerial},
                organization_id => $devices->{$id}->{organizationId},
                organization_name => $organization_name,
                device_mode => $devices->{$id}->{vpnMode},
                device_status => $devices->{$id}->{deviceStatus},
                vpn_type => 'thirdParty',
                vpn_name =>  $_->{name},
                vpn_status => $_->{reachability}
            };
        }
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $item (@$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $item->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List VPN tunnels:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [@labels]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $item (@$results) {
        $self->{output}->add_disco_entry(
            %$item
        );
    }
}

1;

__END__

=head1 MODE

List VPN tunnels.

=over 8

=item B<--filter-network-id>

Filter VPN tunnels by network ID (can be a regexp).

=item B<--filter-organization-id>

Filter VPN tunnels by organization ID (can be a regexp).

=item B<--filter-organization-name>

Filter VPN tunnels by organization name (can be a regexp).

=back

=cut
