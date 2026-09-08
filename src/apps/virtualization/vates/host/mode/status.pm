#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::virtualization::vates::host::mode::status;
use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::misc qw/is_empty is_not_empty/;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);

    $options{options}->add_options(
        arguments => {
            'host-uuid:s' => { name => 'host_uuid', default => '' },
            'host-name:s' => { name => 'host_name', default => '' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (is_empty($options{option_results}->{host_uuid}) and is_empty($options{option_results}->{host_name})) {
        $self->{output}->option_exit(short_msg => "you must fill either --host-uuid or --host-name.");
    }
    $self->SUPER::check_options(%options);
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{host} = [
        {
            label            => 'status',
            type             => COUNTER_TYPE_GROUP,
            critical_default => '%{enabled} !~ /^true/i || %{power_state} !~ /^Running/i',
            set              => {
                key_values => [
                    { name => 'display' }, { name => 'enabled' }, { name => 'power_state' },
                    { name => 'address' }, { name => 'manufacturer' }, { name => 'product_name' },
                    { name => 'uuid' }
                ],
                output_template                => "host '%{display}' is %{power_state} (enabled: %{enabled}), address: %{address} [%{manufacturer} %{product_name}]",
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $host = $options{custom}->get_host_info(fields => "name_label,enabled,power_state,address,uuid,bios_strings");

    my $manufacturer = "unknown";
    my $product_name = "unknown";
    if (is_not_empty($host->{bios_strings}) and ref($host->{bios_strings}) eq "HASH") {
        $manufacturer = $host->{bios_strings}->{'system-manufacturer'} if is_not_empty($host->{bios_strings}->{'system-manufacturer'});
        $product_name = $host->{bios_strings}->{'system-product-name'} if is_not_empty($host->{bios_strings}->{'system-product-name'});
    }

    $self->{host} = {
        display      => $host->{name_label},
        enabled      => $host->{enabled},
        power_state  => $host->{power_state},
        address      => $host->{address} // '',
        manufacturer => $manufacturer,
        product_name => $product_name,
        uuid         => $host->{uuid}
    };
}

1;

__END__

=head1 MODE

Check the status of a Vates XCP-ng host: enabled state and power state.

Since a XCP-ng host is not meaningfully reachable via a plain network ping, this mode is meant to
be used as the Centreon host check command for the host template (no dedicated service needed).

=over 8

=item B<--host-uuid>

Identify the host by its exact uuid.

=item B<--host-name>

Identify the host by its name (only one host is expected).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. You can use the following variables:
C<%{display}>, C<%{enabled}>, C<%{power_state}>, C<%{address}>, C<%{manufacturer}>, C<%{product_name}>, C<%{uuid}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. You can use the following variables:
C<%{display}>, C<%{enabled}>, C<%{power_state}>, C<%{address}>, C<%{manufacturer}>, C<%{product_name}>, C<%{uuid}>.
Default: C<%{enabled} !~ /^true/i || %{power_state} !~ /^Running/i>

=back

=cut
