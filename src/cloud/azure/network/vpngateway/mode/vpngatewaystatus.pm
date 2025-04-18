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

package cloud::azure::network::vpngateway::mode::vpngatewaystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Provisioning State '%s' [Gateway type: %s] [VPN type: %s]",
        $self->{result_values}->{provisioning_state},
        $self->{result_values}->{gateway_type},
        $self->{result_values}->{vpn_type});
    return $msg;
}

sub prefix_vpn_output {
    my ($self, %options) = @_;
    
    return "VPN Gateway '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vpns', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPN gateways are ok' },
    ];

    $self->{maps_counters}->{vpns} = [
        { 
            label => 'status', 
            type => 2, 
            critical_default => '%{provisioning_state} ne "Succeeded"',
            set => { 
                key_values => [ { name => 'provisioning_state' }, { name => 'gateway_type' }, { name => 'vpn_type' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
            "resource-group:s"      => { name => 'resource_group' },
            "filter-name:s"         => { name => 'filter_name' }
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

}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vpns} = {};
    my $vpns = $options{custom}->azure_list_vpn_gateways(resource_group => $self->{option_results}->{resource_group});
    foreach my $vpn (@{$vpns}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $vpn->{name} !~ /$self->{option_results}->{filter_name}/);
        
        $self->{vpns}->{$vpn->{id}} = {
            name => $vpn->{name},
            provisioning_state => ($vpn->{provisioningState}) ? $vpn->{provisioningState} : $vpn->{properties}->{provisioningState},
            gateway_type => ($vpn->{gatewayType}) ? $vpn->{gatewayType} : $vpn->{properties}->{gatewayType},
            vpn_type => ($vpn->{vpnType}) ? $vpn->{vpnType} : $vpn->{properties}->{vpnType},
        };
    }
    
    if (scalar(keys %{$self->{vpns}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No VPN gateways found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check VPN gateways status.

Example: 
C<perl centreon_plugins.pl --plugin=cloud::azure::network::vpngateway::plugin --custommode=azcli --mode=vpn-gateways-status --resource-group='MYRESOURCEGROUP' --verbose>

=over 8

=item B<--resource-group>

Set resource group (required).

=item B<--filter-name>

Filter VPN Gateways by name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{provisioning_state}, %{gateway_type}>, %{vpn_type}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{provisioning_state} ne "Succeeded"'>).
You can use the following variables: %{provisioning_state}, %{gateway_type}, %{vpn_type}, %{display}

=back

=cut
