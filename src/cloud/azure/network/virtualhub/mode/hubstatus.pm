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

package cloud::azure::network::virtualhub::mode::hubstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Provisioning State '%s' [Routing state: %s]",
        $self->{result_values}->{provisioning_state},
        $self->{result_values}->{routing_state});
    return $msg;
}

sub prefix_hub_output {
    my ($self, %options) = @_;

    my $output = sprintf("Virtual Hub '%s' (%s) ",
        $options{instance_value}->{name},
        $options{instance_value}->{address_prefix});

    if (defined($options{instance_value}->{virtual_wan})) {
        $output .= "Virtual WAN '" . $options{instance_value}->{virtual_wan} . "' ";
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'hubs',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_hub_output',
            message_multiple => 'All Virtual Hubs are ok'
        },
    ];

    $self->{maps_counters}->{hubs} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{provisioning_state} ne "Succeeded" || %{routing_state} ne "Provisioned"',
            set              => {
                key_values                     =>
                    [
                        { name => 'provisioning_state' },
                        { name => 'routing_state' },
                        { name => 'address_prefix' },
                        { name => 'name' },
                        { name => 'virtual_wan' }
                    ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
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
        'api-version:s'    => { name => 'api_version', default => '2025-05-01' },
        "resource-group:s" => { name => 'resource_group' },
        "include-name:s"   => { name => 'include_name' },
        "exclude-name:s"   => { name => 'exclude_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->option_exit(short_msg => "Need to specify --resource-group option");
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{hubs} = {};
    my $hubs = $options{custom}->azure_list_virtualhubs(resource_group => $self->{option_results}->{resource_group});
    foreach my $hub (@{$hubs}) {
        next if is_excluded($hub->{name},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name});

        $self->{hubs}->{$hub->{id}} = {
            name               => $hub->{name},
            provisioning_state => ($hub->{provisioningState}) ?
                $hub->{provisioningState} : $hub->{properties}->{provisioningState},
            routing_state      => ($hub->{routingState}) ? $hub->{routingState} : $hub->{properties}->{routingState},
            address_prefix     => ($hub->{addressPrefix}) ? $hub->{addressPrefix} : $hub->{properties}->{addressPrefix},
        };

        my $virtual_wan = ($hub->{virtualWan}) ? $hub->{virtualWan} : $hub->{properties}->{virtualWan};
        if (exists($virtual_wan->{id})) {
            my ($name) = $virtual_wan->{id} =~ m{/virtualWans/([^/]+)};
            $self->{hubs}->{$hub->{id}}->{virtual_wan} = $name;
        }
    }

    if (scalar(keys %{$self->{hubs}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No Virtual Hub found.");
    }
}

1;

__END__

=head1 MODE

Check Virtual Hub status.

Example:
C<perl centreon_plugins.pl --plugin=cloud::azure::network::virtualhub::plugin --custommode=azcli --mode=hub-status --resource-group='MYRESOURCEGROUP' --verbose>

=over 8

=item B<--resource-group>

Set resource group (required).

=item B<--include-name>

Filter Virtual Hub by name (can be a regexp).

=item B<--exclude-name>

Exclude Virtual Hub by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
You can use the following variables: %{provisioning_state}, %{routing_state}>, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{provisioning_state}, %{routing_state}>, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{provisioning_state} ne "Succeeded" || %{routing_state} ne "Provisioned"'>).
You can use the following variables: %{provisioning_state}, %{routing_state}, %{display}

=back

=cut
