#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package network::extreme::cloudiq::restapi::device::mode::wifiinterfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use POSIX qw(strftime);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'wifi_interfaces',
            type             => 1,
            cb_prefix_output => 'prefix_wifi_interface_output',
            message_multiple => 'All WiFi interfaces are ok'
        }
    ];

    $self->{maps_counters}->{wifi_interfaces} = [
        {
            label      => 'tx-bytes',
            nlabel     => 'tx.bytes',
            display_ok => 0,
            set        => {
                key_values            => [ { name => 'tx_byte_count' }, { name => 'interface_name' } ],
                closure_custom_output => $self->can('custom_usage_tx_output'),
                perfdatas             => [
                    {
                        template             => '%d',
                        min                  => 0,
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'rx-bytes',
            nlabel     => 'rx.bytes',
            display_ok => 0,
            set        => {
                key_values            => [ { name => 'rx_byte_count' }, { name => 'interface_name' } ],
                closure_custom_output => $self->can('custom_usage_rx_output'),
                perfdatas             => [
                    {
                        template             => '%d',
                        min                  => 0,
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'tx-utilization',
            nlabel     => 'tx.utilization.percent',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'tx_utilization' }, { name => 'interface_name' } ],
                output_template => 'TX utilization %d%%',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'rx-utilization',
            nlabel     => 'rx.utilization.percent',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'rx_utilization' }, { name => 'interface_name' } ],
                output_template => 'RX utilization %d%%',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'ssid-count',
            nlabel     => 'ssid.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'ssid_count' }, { name => 'interface_name' } ],
                output_template => 'SSID count %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'client-count',
            nlabel     => 'client.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'client_count' }, { name => 'interface_name' } ],
                output_template => 'Clients %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'neighbor-client-count',
            nlabel     => 'neighbor.client.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'neighbor_clients' }, { name => 'interface_name' } ],
                output_template => 'Neighbor clients %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'channel-count',
            nlabel     => 'channel.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'channel' }, { name => 'interface_name' } ],
                output_template => 'Channels %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'channel-utilization',
            nlabel     => 'channel.utilization.percent',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'channel_util' }, { name => 'interface_name' } ],
                output_template => 'Channel utilization %d%%',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
        {
            label      => 'crc-error-frame-count',
            nlabel     => 'crc.error.frame.count',
            display_ok => 0,
            set        => {
                key_values      => [ { name => 'crc_error_frame' }, { name => 'interface_name' } ],
                output_template => 'CRC error frames %d',
                perfdatas       => [
                    {
                        template             => '%d',
                        min                  => 0,
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'interface_name'
                    }
                ]
            }
        },
    ];
}

sub custom_usage_tx_output {
    my ($self, %options) = @_;

    my ($usage_value, $usage_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{tx_byte_count});

    return sprintf('TX: %s', $usage_value . " " . $usage_unit);
}

sub custom_usage_rx_output {
    my ($self, %options) = @_;

    my ($usage_value, $usage_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{rx_byte_count});

    return sprintf('RX: %s', $usage_value . " " . $usage_unit);
}

sub prefix_wifi_interface_output {
    my ($self, %options) = @_;

    return "WiFi Interface $options{instance_value}->{interface_name} $options{instance} ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'device-id:s'     => { name => 'device_id' },
            'device-serial:s' => { name => 'device_serial' },
            'time-interval:s' => { name => 'time_interval', default => 30 }
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

    my $time = time();
    my $min = strftime("%M", localtime($time));
    my $hour = strftime("%H", localtime($time));
    my $sec = 0;

    $min = int($min / 30) * 30;
    my $end_time = POSIX::mktime($sec, $min, $hour, (localtime($time))[3, 4, 5]);
    my $start_time = $end_time - ($self->{option_results}->{time_interval} * 60);

    my $end = $end_time * 1000;
    my $start = $start_time * 1000;

    $endpoint = sprintf(
        "/devices/%s/interfaces/wifi?startTime=%s&endTime=%s",
        $device_id,
        $start,
        $end
    );

    my $interfaces = $options{custom}->request_api(
        endpoint => $endpoint
    );

    foreach my $int (@{$interfaces}) {
        $self->{wifi_interfaces}->{ $int->{frequency} } = {
            interface_name   => $int->{interface_name},
            tx_byte_count    => $int->{tx_byte_count},
            rx_byte_count    => $int->{rx_byte_count},
            tx_utilization   => $int->{tx_utilization},
            rx_utilization   => $int->{rx_utilization},
            ssid_count       => $int->{ssid_count},
            client_count     => $int->{client_count},
            neighbor_clients => $int->{neighbor_clients},
            channel          => $int->{channel},
            channel_util     => $int->{channel_util},
            crc_error_frame  => $int->{crc_error_frame}
        };
    }
};

1;

__END__

=head1 MODE

Check Extreme Cloud IQ device WiFi interfaces

=over 8

=item B<--device-id>

Set the Extreme Cloud IQ device ID. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--device-serial>

Set the Extreme Cloud IQ device serial. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--time-interval>
Set the time interval in minutes.

=item B<--warning-tx-bytes>

Warning threshold for the total tx byte count. (B)

=item B<--critical-tx-bytes>

Critical threshold for the total tx byte count. (B)

=item B<--warning-rx-bytes>

Warning threshold for the total rx byte count. (B)

=item B<--critical-rx-bytes>

Critical threshold for the total rx byte count. (B)

=item B<--warning-tx-utilization>

Warning threshold for the total tx utilization. (%)

=item B<--critical-tx-utilization>

Critical threshold for the total tx utilization. (%)

=item B<--warning-rx-utilization>

Warning threshold for the total rx utilization. (%)

=item B<--critical-rx-utilization>

Critical threshold for the total rx utilization. (%)

=item B<--warning-ssid-count>

Warning threshold for the ssid count.

=item B<--critical-ssid-count>

Critical threshold for the ssid count.

=item B<--warning-client-count>

Warning threshold for the client count.

=item B<--critical-client-count>

Critical threshold for the client count.

=item B<--warning-neighbor-client-count>

Warning threshold for the neighbor client count.

=item B<--critical-neighbor-client-count>

Critical threshold for the neighbor client count.

=item B<--warning-channel-count>

Warning threshold for the channel count.

=item B<--critical-channel-count>

Critical threshold for the channel count.

=item B<--warning-channel-utilization>

Warning threshold for the total channel utilization. (%)

=item B<--critical-channel-utilization>

Critical threshold for the total channel utilization. (%)

=item B<--warning-crc-error-frame-count>

Warning threshold for the crc error frame count.

=item B<--critical-crc-error-frame-count>

Critical threshold for the crc error frame count.

=back

=cut
