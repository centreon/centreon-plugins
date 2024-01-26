#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and cluster monitoring for
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

package hardware::devices::hms::netbiter::argos::restapi::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Date::Parse;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('Device: %s, Name: %s, Value: %s%s (%s)',
        $self->{result_values}->{device_name},
        $self->{result_values}->{display},
        $self->{result_values}->{value},
        $self->{result_values}->{unit},
        $self->{result_values}->{timestamp}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sensors', type => 1, message_multiple => 'All sensors are OK' },
    ];

    $self->{maps_counters}->{sensors} = [
        { label => 'sensor-value', nlabel => 'sensor.reading.count', set => {
                key_values => [ { name => 'value' }, { name => 'display' }, { name => 'device_name' }, { name => 'timestamp' }, { name => 'unit' }  ],
                closure_custom_output => $self->can('custom_status_output'),
                output_template => "value : %s",
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => $self->{result_values}->{unit},
                        instances => $self->{result_values}->{display},
                        value => sprintf('%.1f', $self->{result_values}->{value}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                    );
                }
            }
        }
   ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-device:s' => { name => 'filter_device' },
        'filter-name:s'   => { name => 'filter_name' },
        'filter-id:s'     => { name => 'filter_id' },
        'system-id:s'     => { name => 'system_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!(defined($self->{option_results}->{system_id})) || $self->{option_results}->{system_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --system-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sensors = $options{custom}->list_sensors(system_id => $self->{option_results}->{system_id});

    foreach (@{$sensors}) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_device}) && $self->{option_results}->{filter_device} ne '' &&
            $_->{deviceName} !~ /$self->{option_results}->{filter_device}/);

        my $url = '/system/' . $self->{option_results}->{system_id} . '/log/' . $_->{id};
        my $result = $options{custom}->request_api(
            request => $url,
            get_params => [ 'limitrows=1' ]
        );

        if (scalar(@{$result}) <= 0) {
            $self->{output}->add_option_msg(short_msg => 'Skipping ' . $_->{name} . ' (no value)');
            next
        }

        foreach my $entry (@{$result}) {
            my $timestamp = $options{custom}->convert_iso8601_to_epoch(time_string => $entry->{timestamp});
            $self->{sensors}->{$_->{id}} = {
                device_name => $_->{deviceName},
                display     => $_->{name},
                timestamp   => POSIX::strftime('%Y-%m-%d %H:%M:%S %Z', localtime($timestamp)),
                unit        => $_->{unit},
                value       => $entry->{value}
            }
        }
    }

    if (scalar(keys %{$self->{sensors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sensor found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Netbiter sensors values using Argos RestAPI.

Example:
perl centreon_plugins.pl --plugin=hardware::devices::hms::netbiter::argos::restapi::plugin --mode=sensors
--access-key='ABCDEFG1234567890' --system-id='XYZ123' --filter-name='My Sensor' --verbose

More information on'https://apidocs.netbiter.net/?page=methods&show=getSystemLoggedValues'.

=over 8

=item B<--system-id>

Set the Netbiter Argos System ID (mandatory).

=item B<--filter-id>

Filter by sensor ID (regexp can be used).
Example: --filter-id='^1234.5678$'

=item B<--filter-device>

Filter by device name (regexp can be used).
Example: --filter-device='^ZONE(1|2)$'

=item B<--filter-name>

Filter by sensor name (regexp can be used).
Example: --filter-name='^temperature_(in|out)$'

=item B<--warning-sensor-value>

Warning threshold.

=item B<--critical-sensor-value>

Critical threshold.

=back

=cut
