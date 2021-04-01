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

package cloud::azure::network::expressroute::mode::circuitstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Status '%s', Provider Status '%s' [Name: %s] [Location: %s]",
        $self->{result_values}->{circuit_status},
        $self->{result_values}->{provider_status},
        $self->{result_values}->{provider_name},
        $self->{result_values}->{provider_location});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{circuit_status} = $options{new_datas}->{$self->{instance} . '_circuit_status'};
    $self->{result_values}->{provider_status} = $options{new_datas}->{$self->{instance} . '_provider_status'};
    $self->{result_values}->{provider_name} = $options{new_datas}->{$self->{instance} . '_provider_name'};
    $self->{result_values}->{provider_location} = $options{new_datas}->{$self->{instance} . '_provider_location'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_circuit_output {
    my ($self, %options) = @_;
    
    return "Circuit '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'circuits', type => 1, cb_prefix_output => 'prefix_circuit_output', message_multiple => 'All circuits are ok' },
    ];

    $self->{maps_counters}->{circuits} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'circuit_status' }, { name => 'provider_status' }, { name => 'provider_name' },
                                { name => 'provider_location' }, { name => 'display' } ],
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
                                    "location:s"            => { name => 'location' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{circuit_status} ne "Enabled" || %{provider_status} ne "Provisioned"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{circuits} = {};
    my $circuits = $options{custom}->azure_list_expressroute_circuits(resource_group => $self->{option_results}->{resource_group});
    foreach my $circuit (@{$circuits}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $circuit->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{location}) && $self->{option_results}->{location} ne ''
            && $circuit->{location} !~ /$self->{option_results}->{location}/);
        
        $self->{circuits}->{$circuit->{id}} = {
            display => $circuit->{name},
            circuit_status => ($circuit->{circuitProvisioningState}) ? $circuit->{circuitProvisioningState} : $circuit->{properties}->{circuitProvisioningState},
            provider_status => ($circuit->{serviceProviderProvisioningState}) ? $circuit->{serviceProviderProvisioningState} : $circuit->{properties}->{serviceProviderProvisioningState},
            provider_name => ($circuit->{serviceProviderProperties}->{serviceProviderName}) ? $circuit->{serviceProviderProperties}->{serviceProviderName} : $circuit->{properties}->{serviceProviderProperties}->{serviceProviderName},
            provider_location => ($circuit->{serviceProviderProperties}->{peeringLocation}) ? $circuit->{serviceProviderProperties}->{peeringLocation} : $circuit->{properties}->{serviceProviderProperties}->{peeringLocation},
        };
    }
    
    if (scalar(keys %{$self->{circuits}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No ExpressRoute circuits found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check ExpressRoute circuits status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::network::expressroute::plugin --custommode=azcli --mode=circuit-status
--resource-group='MYRESOURCEGROUP' --verbose

=over 8

=item B<--resource-group>

Set resource group.

=item B<--location>

Set resource location.

=item B<--filter-name>

Filter circuit name (Can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{circuit_status}, %{provider_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{circuit_status} ne "Enabled" || %{provider_status} ne "Provisioned"').
Can used special variables like: %{circuit_status}, %{provider_status}, %{display}

=back

=cut
