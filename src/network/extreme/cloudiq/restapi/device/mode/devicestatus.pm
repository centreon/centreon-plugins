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

package network::extreme::cloudiq::restapi::device::mode::devicestatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;
use JSON::PP;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "admin state: %s, connected: %s, config mismatch: %s",
        $self->{result_values}->{admin_state},
        $self->{result_values}->{connected},
        $self->{result_values}->{config_mismatch}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name         => 'global',
            type         => 0,
            skipped_code => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{admin_state} ne "MANAGED" || %{connected} eq "false"',
            warning_default  => '%{config_mismatch} eq "true"',
            set              =>
                {
                    key_values                     => [
                        { name => 'connected' },
                        { name => 'admin_state' },
                        { name => 'config_mismatch' },
                        { name => 'active_clients' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        {
            label  => 'active-clients',
            nlabel => 'active.clients.count',
            set    => {
                key_values      => [ { name => 'active_clients' } ],
                output_template => 'Active clients: %d',
                perfdatas       => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'device-id:s'     => { name => 'device_id' },
            'device-serial:s' => { name => 'device_serial' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{device_id}) && length($self->{option_results}->{device_id}) == 0) {
        $self->{option_results}->{device_id} = undef;
    }

    if (defined($self->{option_results}->{device_serial}) && length($self->{option_results}->{device_serial}) == 0) {
        $self->{option_results}->{device_serial} = undef;
    }

    if ((defined($self->{option_results}->{device_id}) && defined($self->{option_results}->{device_serial}))
        || (!defined($self->{option_results}->{device_id}) && !defined($self->{option_results}->{device_serial}))) {
        $self->{output}->add_option_msg(
            short_msg =>
                "Please use --device-id OR --device-serial. One of two parameters must be set, but not both"
        );
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my ($endpoint, $device_id);

    # options only allows --device-id or --device-serial. One of two parameters must be set, but not both
    if (defined($self->{option_results}->{device_serial}) && length($self->{option_results}->{device_serial})) {
        $endpoint = sprintf(
            "/devices?page=1&limit=1&sns=%s&views=STATUS",
            $self->{option_results}->{device_serial},
        );

        my $devices = $options{custom}->request_api(
            endpoint => $endpoint
        );

        # the serial should be unique
        if ($devices->{total_count} <= 0) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "No data found. Please check if the device with serial $self->{option_results}->{device_serial} exists."
            );
            $self->{output}->option_exit();
        } elsif ($devices->{total_count} > 1) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "$devices->{total_count} devices with serial $self->{option_results}->{device_serial} exists. Please use the --device-id instead of --device-serial"
            );
            $self->{output}->option_exit();
        }

        # the serial should be unique
        $device_id = $devices->{data}[0]->{id};

    } else {
        $device_id = $self->{option_results}->{device_id}
    }

    $endpoint = sprintf(
        "/devices/%s?views=STATUS&views=BASIC&fields=IP_ADDRESS&fields=ACTIVE_CLIENTS&fields=SYSTEM_UP_TIME",
        $device_id
    );

    my $device = $options{custom}->request_api(
        endpoint => $endpoint
    );

    $self->{global} = {
        connected       => ($device->{connected} == JSON::PP::true) ? "true" : "false",
        admin_state     => $device->{device_admin_state},
        config_mismatch => ($device->{config_mismatch} == JSON::PP::true) ? "true" : "false",
        active_clients  => defined($device->{active_clients}) ? $device->{active_clients} : 0
    };
}

1;

__END__

=head1 MODE

Check Extreme Cloud IQ device status

=over 8

=item B<--device-id>

Set the Extreme Cloud IQ device ID. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--device-serial>

Set the Extreme Cloud IQ device serial. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
You can use the following variables: %{admin_state}, %{config_mismatch}, %{connected}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{config_mismatch} eq "true"').
You can use the following variables: %{admin_state}, %{config_mismatch}, %{connected}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admin_state} ne "MANAGED" || %{connected} eq "false"').
You can use the following variables: %{admin_state}, %{config_mismatch}, %{connected}

=item B<--warning-active-clients>

Warning threshold for number of active clients.

=item B<--critical-active-clients>

Critical threshold for number of active clients.

=back

=cut
