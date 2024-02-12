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

package hardware::ups::inmatics::sputnik::snmp::mode::environment;

use base qw(centreon::plugins::templates::counter);

# Needed libraries
use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # Declare options
    $options{options}->add_options(arguments => {
        'filter-id:s' => { name => 'filter_id' }
    });

    return $self;
}

sub prefix_sensors_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "': ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sensors', type => 1, cb_prefix_output => 'prefix_sensors_output', message_multiple => 'All sensors are ok' }
    ];

    $self->{maps_counters}->{sensors} = [
        { label => 'temperature', nlabel => 'environment.temperature.celsius', set => {
                key_values => [ { name => 'temperature' }, { name => 'display' } ],
                output_template => 'temperature %.2f C',
                perfdatas => [
                    { label => 'temperature', template => '%.2f', unit => 'C', label_extra_instance => 1,  instance_use => 'display' }
                ]
            }
        },
        { label => 'humidity', nlabel => 'environment.humidity.percentage', set => {
                key_values => [ { name => 'humidity' }, { name => 'display' } ],
                output_template => 'humidity %s %%',
                perfdatas => [
                    { label => 'humidity', template => '%s', min => 0, max => 100, unit => '%', label_extra_instance => 1,  instance_use => 'display' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # FI: upsEnvSensorCounts is not used but it gives the number of sensors
    #my $oid_upsEnvSensorCounts = '.1.3.6.1.4.1.54661.1.1.1.2.1.0';
    my $oid_upsEnvSensors = '.1.3.6.1.4.1.54661.1.1.1.2.2.1';
    # FI: the actual MIB OIDs:
    #my $oid_upsEnvSensorTemperature = '.1.3.6.1.4.1.54661.1.1.1.2.2.1.2';
    #my $oid_upsEnvSensorHumidity = '.1.3.6.1.4.1.54661.1.1.1.2.2.1.3';

    # Each sensor will provide a temperature (in 100th of degrees) and a humidity percentage
    my $mapping = {
        upsEnvSensorTemperature     => { oid => $oid_upsEnvSensors.'.2' },
        upsEnvSensorHumidity        => { oid => $oid_upsEnvSensors.'.3' }
    };
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsEnvSensors,
        nothing_quit => 1
    );

    $self->{sensors} = {};
    foreach my $oid (sort(keys %{$snmp_result})) {
        next if ($oid !~ /^$oid_upsEnvSensors\.2\.(.*)$/);
        # The index of the sensor will be used in the instance name
        my $sensor_index = $1;

        # Skip if a filter is defined and the current sensor does not match
        if (defined($self->{option_results}->{filter_id}) && $sensor_index ne '' && $sensor_index !~ /$self->{option_results}->{filter_id}/ ) {
            $self->{output}->output_add(
                long_msg => "With filter-id: '$self->{option_results}->{filter_id}' - Skipping sensor '$sensor_index'.",
                debug    => 1
            );
            next;
        }

        # Get all the metrics for the current instance
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $sensor_index
        );

        # The temperature is given multiplied by 100, so we have to divide it by 100
        # cf MIB: UNITS     "0.01 degrees Centigrade"
        $self->{sensors}->{$sensor_index} = {
            display => 'Sensor '.$sensor_index,
            temperature => $result->{upsEnvSensorTemperature} / 100,
            humidity => $result->{upsEnvSensorHumidity}
        };
    }

    # No results is not OK
    if (scalar(keys %{$self->{sensors}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sensors found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor temperature and humidity using the device's environment sensors.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds. Can be: 'humidity' (%), 'temperature' (C).

=item B<--filter-id>

Define which sensors should be monitored based on their IDs. This option will be treated as a regular expression.

=back

=cut
