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

package network::extreme::cloudiq::restapi::device::mode::uptime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX;
use centreon::plugins::misc;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_output {
    my ($self, %options) = @_;

    return sprintf(
        'uptime is: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel   => 'system.uptime.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit     => $self->{instance_mode}->{option_results}->{unit},
        value    => floor(
            $self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }
        ),
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     => floor(
            $self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }
        ),
        threshold =>
            [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
                { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
            ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'uptime', set => {
            key_values                     => [ { name => 'uptime' } ],
            closure_custom_output          => $self->can('custom_uptime_output'),
            closure_custom_perfdata        => $self->can('custom_uptime_perfdata'),
            closure_custom_threshold_check => $self->can('custom_uptime_threshold')
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'device-id:s'     => { name => 'device_id' },
            'device-serial:s' => { name => 'device_serial' },
            'add-system-info' => { name => 'add_system_info' },
            'unit:s'          => { name => 'unit', default => 's' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

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
        uptime => ((time * 1000) - $device->{system_up_time}) / 1000 + 0
    };

    if (defined($self->{option_results}->{add_system_info})) {
        $self->{output}->output_add(
            short_msg => sprintf(
                '%s %s, type: %s, serial: %s, IP: %s, software version: %s',
                $device->{device_function},
                $device->{hostname},
                $device->{product_type},
                $device->{serial_number},
                $device->{ip_address},
                $device->{software_version}
            )
        );
    }
}

1;

__END__

=head1 MODE

Check Extreme Cloud IQ device average CPU.

=over 8

=item B<--device-id>

Set the Extreme Cloud IQ device ID. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--device-serial>

Set the Extreme Cloud IQ device serial. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--warning-average>

Warning threshold for CPU average.

=item B<--critical-average>

Critical threshold for CPU average.

=item B<--unit>

Select the time unit for the performance data and thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back

=cut
