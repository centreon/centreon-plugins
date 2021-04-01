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

package cloud::azure::network::virtualnetwork::mode::peeringsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("State '%s', Provisioning State '%s' [Peer: %s]",
        $self->{result_values}->{peering_state},
        $self->{result_values}->{provisioning_state},
        $self->{result_values}->{peer});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{peering_state} = $options{new_datas}->{$self->{instance} . '_peering_state'};
    $self->{result_values}->{provisioning_state} = $options{new_datas}->{$self->{instance} . '_provisioning_state'};
    $self->{result_values}->{peer} = $options{new_datas}->{$self->{instance} . '_peer'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
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
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'peering_state' }, { name => 'provisioning_state' }, { name => 'peer' },
                                { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "vnet-name:s"           => { name => 'vnet_name' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{peering_state} ne "Connected" || %{provisioning_state} ne "Succeeded"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{vnet_name}) || $self->{option_results}->{vnet_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --vnet-name option");
        $self->{output}->option_exit();
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peerings} = {};
    my $peerings = $options{custom}->azure_list_vnet_peerings(
        resource_group => $self->{option_results}->{resource_group},
        vnet_name => $self->{option_results}->{vnet_name}
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
perl centreon_plugins.pl --plugin=cloud::azure::network::virtualnetwork::plugin --custommode=azcli --mode=peerings-status
--resource-group='MYRESOURCEGROUP' --vnet-name='MyVNetName' --verbose

=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--vnet-name>

Set virtual network name (Required).

=item B<--filter-name>

Filter peering name (Can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{peering_state}, %{provisioning_state}, %{peer}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{peering_state} ne "Connected" || %{provisioning_state} ne "Succeeded"').
Can used special variables like: %{peering_state}, %{provisioning_state}, %{peer}, %{display}

=back

=cut
