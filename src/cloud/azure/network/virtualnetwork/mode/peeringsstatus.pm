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

package cloud::azure::network::virtualnetwork::mode::peeringsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("State '%s', Provisioning State '%s' [Peer: %s]",
        $self->{result_values}->{peering_state},
        $self->{result_values}->{provisioning_state},
        $self->{result_values}->{peer});
    return $msg;
}

sub prefix_peering_output {
    my ($self, %options) = @_;
    
    return "Peering '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peerings', type => 1, cb_prefix_output => 'prefix_peering_output', message_multiple => 'All peerings are ok' },
    ];

    $self->{maps_counters}->{peerings} = [
        { 
            label => 'status', 
            type => 2,
            critical_default => '%{peering_state} ne "Connected" || %{provisioning_state} ne "Succeeded"',
            set => {
                key_values => [ { name => 'peering_state' }, { name => 'provisioning_state' }, { name => 'peer' },
                                { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "resource-group:s"      => { name => 'resource_group' },
        "resource:s"            => { name => 'resource' },
        "filter-name:s"         => { name => 'filter_name' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }
    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Network\/virtualNetworks\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;

}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peerings} = {};
    my $peerings = $options{custom}->azure_list_vnet_peerings(
        resource_group => $self->{az_resource_group},
        resource => $self->{az_resource}
    );
    foreach my $peering (@{$peerings}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $peering->{name} !~ /$self->{option_results}->{filter_name}/);

        my $peer;
        $peer = $1 if (defined($peering->{remoteVirtualNetwork}->{id}) && $peering->{remoteVirtualNetwork}->{id} =~ /providers\/Microsoft\.Network\/virtualNetworks\/(.*)$/);
        $peer = $1 if (defined($peering->{properties}->{remoteVirtualNetwork}->{id}) && $peering->{properties}->{remoteVirtualNetwork}->{id} =~ /providers\/Microsoft\.Network\/virtualNetworks\/(.*)$/);
        
        $self->{peerings}->{$peering->{id}} = {
            display => $peering->{name},
            peering_state => ($peering->{peeringState}) ? $peering->{peeringState} : $peering->{properties}->{peeringState},
            provisioning_state => ($peering->{provisioningState}) ? $peering->{provisioningState} : $peering->{properties}->{provisioningState},
            peer => $peer,
        };
    }
    
    if (scalar(keys %{$self->{peerings}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual network peerings found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual network peerings status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::network::virtualnetwork::plugin --custommode=awscli --mode=peerings-status
--resource-group='MYRESOURCEGROUP' --resource='MyVNetName' --verbose

=over 8

=item B<--resource-group>

Set resource group (required).

=item B<--resource>

Set virtual network name (required).

=item B<--filter-name>

Filter peering name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{peering_state}, %{provisioning_state}, %{peer}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{peering_state} ne "Connected" || %{provisioning_state} ne "Succeeded"').
You can use the following variables: %{peering_state}, %{provisioning_state}, %{peer}, %{display}

=back

=cut
