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

package network::extreme::cloudiq::restapi::location::mode::devicehealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::PP;
use Time::HiRes qw(gettimeofday);
use POSIX qw(strftime);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{display} . ' ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'overall-score',
            nlabel => 'overall.score',
            set    => {
                key_values      => [ { name => 'overall_score' } ],
                output_template => 'overall score: %d',
                perfdatas       => [
                    { template => '%d', min => 0, max => 100 }
                ]
            }
        },
        {
            label  => 'device-availability-score',
            nlabel => 'device.availability.score',
            set    => {
                key_values      => [ { name => 'device_availability_score' } ],
                output_template => 'device availability score: %d',
                perfdatas       => [
                    { template => '%d', min => 0, max => 100 }
                ]
            }
        },
        {
            label  => 'device-hardware-health-score',
            nlabel => 'device.hardware.health.score',
            set    => {
                key_values      => [ { name => 'device_hardware_health_score' } ],
                output_template => 'device hardware health score: %d',
                perfdatas       => [
                    { template => '%d', min => 0, max => 100 }
                ]
            }
        },
        {
            label  => 'config-and-firmware-score',
            nlabel => 'configfirmware.score',
            set    => {
                key_values      => [ { name => 'config_and_firmware_score' } ],
                output_template => 'config and firmware score: %d',
                perfdatas       => [
                    { template => '%d', min => 0, max => 100 }
                ]
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
            'location-id:s'   => { name => 'location_id' },
            'location-name:s' => { name => 'location_name' },
            'location-type:s' => { name => 'location_type', default => 'site' },
            'time-interval:s' => { name => 'time_interval', default => 10 }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{location_id}) && length($self->{option_results}->{location_id}) == 0) {
        $self->{option_results}->{location_id} = undef;
    }

    if (defined($self->{option_results}->{location_name}) && length($self->{option_results}->{location_name}) == 0) {
        $self->{option_results}->{location_name} = undef;
    }

    if (defined($self->{option_results}->{location_type}) && length($self->{option_results}->{location_type}) == 0) {
        $self->{option_results}->{location_type} = undef;
    }

    if ((defined($self->{option_results}->{location_id}) && defined($self->{option_results}->{location_name}))
        || (!defined($self->{option_results}->{location_id}) && !defined($self->{option_results}->{location_name}))) {
        $self->{output}->add_option_msg(
            short_msg =>
                "Please use --location-id OR --location-name. One of two parameters must be set, but not both"
        );
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{location_name}) && !defined($self->{option_results}->{location_type})) {
        $self->{output}->add_option_msg(
            short_msg =>
                "Please use --location-name in combination with --location-type."
        );
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my ($endpoint, $location_id);

    # options only allows --location-id or --location-name. One of two parameters must be set, but not both
    # if --location-name is used we have to get the location-id first. We get it using the location-name and type.
    # if we found more than one (should be unique) we raise an error
    if (defined($self->{option_results}->{location_name}) && length($self->{option_results}->{location_name})) {
        $endpoint = sprintf(
            "/locations/%s?page=1&limit=10&name=%s",
            $self->{option_results}->{location_type},
            $self->{option_results}->{location_name},
        );

        my $locations = $options{custom}->request_api(
            endpoint => $endpoint
        );

        # the location should be unique
        if ($locations->{total_count} <= 0) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "No data found. Please check if the location with name $self->{option_results}->{location_name} exists."
            );
            $self->{output}->option_exit();
        } elsif ($locations->{total_count} > 1) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "$locations->{total_count} locations with name $self->{option_results}->{location_name} exists. Please use the --location-id instead of --location-name"
            );
            $self->{output}->option_exit();
        }

        $location_id = $locations->{data}[0]->{id};

    } else {
        $location_id = $self->{option_results}->{location_id}
    }

    my $location = $options{custom}->request_api(
        endpoint => sprintf(
            "/locations/%s/%s",
            $self->{option_results}->{location_type},
            $location_id,
        )
    );

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
        "/network-scorecard/deviceHealth/%s?startTime=%s&endTime=%s",
        $location_id,
        $start,
        $end
    );

    my $scores = $options{custom}->request_api(
        endpoint => $endpoint
    );

    $self->{global} = {
        overall_score                => $scores->{score},
        device_availability_score    => $scores->{device_availability_score},
        device_hardware_health_score => $scores->{device_hardware_health_score},
        config_and_firmware_score    => $scores->{config_and_firmware_score},
        display                      => sprintf('%s %s', $location->{type}, $location->{unique_name})
    };
}

1;

__END__

=head1 MODE

Check Extreme Cloud IQ location device health scores.

=over 8

=item B<--location-id>

Set the Extreme Cloud IQ location ID. Use either --location-id or --location-name and --location-type in combination.

=item B<--location-name>

Set the Extreme Cloud IQ location name. Use either --location-id or --location-name and --location-type in combination.

=item B<--location-type>

Set the Extreme Cloud IQ location type. Use either --location-id or --location-name and --location-type in combination.

=item B<--warning-overall-score>

Warning threshold for overall score. (0-100)

=item B<--critical-overall-score>

Critical threshold for overall score. (0-100)

=item B<--warning-device-availability-score>

Warning threshold for device availability score. (0-100)

=item B<--critical-device-availability-score>

Critical threshold for device availability score. (0-100)

=item B<--warning-device-hardware-health-score>

Warning threshold for device hardware health score. (0-100)

=item B<--critical-device-hardware-health-score>

Critical threshold for device hardware health score. (0-100)

=item B<--warning-config-and-firmware-score>

Warning threshold for config and firmware score. (0-100)

=item B<--critical-config-and-firmware-score>

Critical threshold for config and firmware score. (0-100)

=back

=cut
