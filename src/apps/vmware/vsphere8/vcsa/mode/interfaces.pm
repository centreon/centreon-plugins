#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcsa::mode::interfaces;

use base qw(apps::vmware::vsphere8::vcsa::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded value_of);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my @_options = qw/
    interface_name
    include_name exclude_name
    include_mac exclude_mac
    include_ipv4_address exclude_ipv4_address
    include_ipv4_mode exclude_ipv4_mode
    include_status exclude_status
/;
my @_service_keys = qw/name mac ipv4_address ipv4_mode status/;

sub custom_interface_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'interface "%s" is %s in "%s" mode with address "%s"',
        $self->{result_values}->{name},
        $self->{result_values}->{status},
        $self->{result_values}->{ipv4_mode},
        $self->{result_values}->{ipv4_address}

    );

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interface', type => 1, message_multiple => 'All interfaces are OK' },
    ];

    $self->{maps_counters}->{interface} = [
        {
            label  => 'status',
            type   => 2,
            warning_default  => '%{status} ne "up"',
            critical_default => '%{status} eq "down"',
            unknown_default  => '%{status} eq ""',
            set    => {
                key_values      => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'ipv4_mode' }, { name => 'ipv4_address' } ],
                closure_custom_output => $self->can('custom_interface_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s' => { name => $_, default => '' } } @_options )
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $name = $self->{option_results}->{interface_name} // '';

    my $response = $options{custom}->request_api(
        'endpoint' => '/appliance/networking/interfaces/' . $name,
        'method' => 'GET');

    # if the exact interface name is provided, only its data will be retrieved
    if ($name ne '') {
        $self->{interface}->{$name} = {
            name         => $name,
            mac          => $response->{mac},
            status       => $response->{status},
            ipv4_address => value_of($response, '->{ipv4}->{address}'),
            ipv4_mode    => value_of($response, '->{ipv4}->{mode}')
        };
    } else { # else we have an array of results
        foreach my $interface (@$response) {
            # apply filters
            next if is_excluded(
                $interface->{name},
                $self->{option_results}->{include_name},
                $self->{option_results}->{exclude_name});
            next if is_excluded(
                $interface->{mac},
                $self->{option_results}->{include_mac},
                $self->{option_results}->{exclude_mac});
            next if is_excluded(
                $interface->{status},
                $self->{option_results}->{include_status},
                $self->{option_results}->{exclude_status});
            next if is_excluded(
                value_of($interface, '->{ipv4}->{address}'),
                $self->{option_results}->{include_ipv4_address},
                $self->{option_results}->{exclude_ipv4_address});
            next if is_excluded(
                value_of($interface, '->{ipv4}->{mode}'),
                $self->{option_results}->{include_ipv4_mode},
                $self->{option_results}->{exclude_ipv4_mode});

            # store result
            $self->{interface}->{$interface->{name}} = {
                name         => $interface->{name},
                mac          => $interface->{mac},
                status       => $interface->{status},
                ipv4_address => value_of($interface, '->{ipv4}->{address}'),
                ipv4_mode    => value_of($interface, '->{ipv4}->{mode}')
            };
        }
    }

    $self->{output}->option_exit(short_msg => 'No service found with current filters.') if (keys(%{$self->{interface}}) == 0);

}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_service_keys ], prettify => 0);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item ( sort { $a->{name} cmp $b->{name} }
                       values %{$self->{interface}}) {
        $self->{output}->add_disco_entry( map { $_ => $item->{$_} } @_service_keys );
    }
}

1;

__END__

=head1 MODE

Discover and monitor the VMware vCenter services VMs through vSphere 8 REST API.

=over 8

=item B<--interface-name>

Define the exact name of the interface to monitor. Using this option is recommended to monitor one interface because it
will only retrieve the data related to the targeted interface.

Interface name examples are: C<nic0>, C<nic1>...

=item B<--include-name>

Regular expression to include interfaces to monitor by their name. Using this option is not recommended to monitor
one interface because it will first retrieve the list of all interfaces and then filter to get the targeted interface.

=item B<--exclude-name>

Regular expression to exclude interfaces to monitor by their name. Using this option is not recommended to monitor
one interface because it will first retrieve the list of all interfaces and then filter to get the targeted interface.

=item B<--include-mac>

Regular expression to include interfaces to monitor by their MAC address.

=item B<--exclude-mac>

Regular expression to exclude interfaces to monitor by their MAC address.

=item B<--include-ipv4-address>

Regular expression to include interfaces to monitor by their IPv4 address.

=item B<--exclude-ipv4-address>

Regular expression to exclude interfaces to monitor by their IPv4 address.

=item B<--include-ipv4-mode>

Regular expression to include interfaces to monitor by their IPv4 mode (example: "STATIC").

=item B<--exclude-ipv4-mode>

Regular expression to exclude interfaces to monitor by their IPv4 mode (example: "STATIC").

=item B<--include-status>

Regular expression to include interfaces to monitor by their status (examples: "up", "down").

=item B<--exclude-status>

Regular expression to exclude interfaces to monitor by their status (examples: "up", "down").

=item B<--warning-status>

Threshold.

=item B<--critical-status>

Threshold.

=back

=cut
