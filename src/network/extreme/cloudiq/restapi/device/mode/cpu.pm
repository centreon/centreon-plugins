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

package network::extreme::cloudiq::restapi::device::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use POSIX qw(strftime);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0, cb_prefix_output => 'prefix_cpu_avg_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        {
            label  => 'average',
            nlabel => 'cpu.utilization.percentage',
            set    => {
                key_values      => [ { name => 'average' } ],
                output_template => '%.2f %%',
                perfdatas       => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub prefix_cpu_avg_output {
    my ($self, %options) = @_;

    return "CPU ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'device-id:s'     => { name => 'device_id' },
            'device-serial:s' => { name => 'device_serial' },
            'time-interval:s' => { name => 'time_interval', default => 10 }
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

    $min = int($min / 5) * 5;
    my $end_time = POSIX::mktime($sec, $min, $hour, (localtime($time))[3, 4, 5]);
    my $start_time = $end_time - ($self->{option_results}->{time_interval} * 60);

    my $end = $end_time * 1000;
    my $start = $start_time * 1000;

    $endpoint = sprintf(
        "/devices/%s/history/cpu-mem?startTime=%d&endTime=%d&interval=%d",
        $device_id,
        $start,
        $end,
        10
    );

    my $values = $options{custom}->request_api(
        endpoint => $endpoint
    );

    if (scalar(@{$values}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No data found. Please check time-interval $start - $end");
        $self->{output}->option_exit();
    }

    my $avg_total = 0;
    my $cnt = 0;
    foreach my $value (@{$values}) {
        $avg_total += $value->{average_cpu};
        $cnt++;
    }

    my $avg = $avg_total / $cnt;

    $self->{cpu_avg} = {
        average => $avg
    };

    $cnt = 0;
};

1;

__END__

=head1 MODE

Check Extreme Cloud IQ device average CPU.

=over 8

=item B<--device-id>

Set the Extreme Cloud IQ device ID. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--device-serial>

Set the Extreme Cloud IQ device serial. Use either --device-id or --device-serial. One of two parameters must be set, but not both.

=item B<--time-interval>
Set the time interval in minutes.

=item B<--warning-average>

Warning threshold for CPU average.

=item B<--critical-average>

Critical threshold for CPU average.

=back

=cut
