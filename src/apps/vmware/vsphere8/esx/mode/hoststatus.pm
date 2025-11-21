#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::esx::mode::hoststatus;

use base qw(apps::vmware::vsphere8::esx::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_empty value_of/;

sub custom_power_status_output {
    my ($self, %options) = @_;

    return 'power state is ' . $self->{result_values}->{power_state};
}

sub custom_connection_status_output {
    my ($self, %options) = @_;

    return 'connection state is ' . $self->{result_values}->{connection_state};
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "', id: '" . $options{instance_value}->{id} . "': ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'host',
            type             => 1,
            cb_prefix_output => 'prefix_host_output',
            message_multiple => 'All ESX Hosts are ok'
        }
    ];

    $self->{maps_counters}->{host} = [
        {
            label => 'power-status',
            type => 2,
            critical_default => '%{power_state} !~ /^powered_on$/i',
            set => {
                key_values => [ { name => 'display' }, { name => 'power_state' }, { name => 'id' } ],
                closure_custom_output          => $self->can('custom_power_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'connection-status',
            type => 2,
            critical_default => '%{connection_state} !~ /^connected$/i',
            set => {
                key_values => [{ name => 'display' }, { name => 'connection_state' }],
                closure_custom_output          => $self->can('custom_connection_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $self->request_api(
        %options,
        'endpoint' => '/vcenter/host',
        'method' => 'GET'
    );

    $self->{host} = {};
    foreach my $host (@{$response}) {
        next if (!defined($host->{name}) || !is_empty($self->{option_results}->{esx_name}) && $host->{name} ne $self->{option_results}->{esx_name});
        next if (!defined($host->{host}) || !is_empty($self->{option_results}->{esx_id}) && $host->{host} ne $self->{option_results}->{esx_id});

        $self->{host}->{$host->{host}} = {
            display          => $host->{name},
            power_state      => $host->{power_state},
            connection_state => $host->{connection_state},
            id               => $host->{host},
        };
    }
    if (scalar(keys %{$self->{host}}) == 0) {
        $self->{output}->option_exit(short_msg => "No ESX Host found with name: '" .value_of($self, '->{option_results}->{esx_name}')."' and id: '".value_of($self, '->{option_results}->{esx_id}')."'.");
    }
    return 1;
}

1;

__END__

=head1 MODE

Monitor the status of VMware ESX hosts through vSphere 8 REST API.

=over 8

=item B<--warning-power-status>

Define the warning threshold for the power status of the ESX host.
The value should be a Perl expression using the %{power_state} macro.

=item B<--critical-power-status>

Define the critical threshold for the power status of the ESX host.
The value should be a Perl expression using the %{power_state} macro.
Default: '%{power_state} !~ /^powered_on$/i'

=item B<--warning-connection-status>

Define the warning threshold for the connection status of the ESX host.
The value should be a Perl expression using the %{connection_state} macro.

=item B<--critical-connection-status>

Define the critical threshold for the connection status of the ESX host.
The value should be a Perl expression using the %{connection_state} macro.
Default: '%{connection_state} !~ /^connected$/i'

=back

=cut
