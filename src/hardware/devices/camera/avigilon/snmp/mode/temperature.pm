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

package hardware::devices::camera::avigilon::snmp::mode::temperature;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "sensor %s [type:%s] status: %s",
        $self->{result_values}->{id},
        $self->{result_values}->{type},
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sensors', type => 0 }
    ];

    $self->{maps_counters}->{sensors} = [
        { label => 'temperature',
          nlabel => 'sensor.temperature.celsius',
          set => {
                key_values      => [{ name => 'temperature' }],
                output_template => 'temperature: %.2f C',
                perfdatas       => [
                    { template => '%s', min => 0, unit => 'C', label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label            => 'status',
          type             => 2,
          critical_default => '%{status} ne "ok"',
          set              => {
              key_values                     => [{ name => 'status' }, { name => 'id' }, { name => 'type' }],
              closure_custom_output          => $self->can('custom_status_output'),
              closure_custom_perfdata        => sub { return 0; },
              closure_custom_threshold_check => \&catalog_status_threshold_ng
          }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-sensor-id:s' => { name => 'filter_id' }
    });

    return $self;
}

my $state_mapping = {
    1 => 'ok',
    2 => 'failure',
    3 => 'outOfBoundary'
};

my $type_mapping = {
    1 => 'mainSensor',
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_type        = '.1.3.6.1.4.1.46202.1.1.1.1.1.1'; # tempSensorType: The type of a temperature sensor, i.e. where it is mounted
    my $oid_id          = '.1.3.6.1.4.1.46202.1.1.1.1.1.2'; # tempSensorId: The unique identifier for a temperature sensor.
    my $oid_status      = '.1.3.6.1.4.1.46202.1.1.1.1.1.3'; # tempSensorStatus: The status of a temperature sensor.
    my $oid_temperature = '.1.3.6.1.4.1.46202.1.1.1.1.1.4'; # tempSensorValue: The temperature as measured in degrees Celsius.

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [$oid_type, $oid_id, $oid_status, $oid_temperature],
        nothing_quit => 1
    );

    $self->{sensors} = {
        id          => $snmp_result->{$oid_id},
        type        => $type_mapping->{$snmp_result->{$oid_type}},
        status      => $state_mapping->{$snmp_result->{$oid_status}},
        temperature => $snmp_result->{$oid_temperature}
    };
}

1;

__END__

=head1 MODE

Check temperature sensor state and value.

=over 8

=item B<--warning-status>

Define the conditions to match to return a warning status.
The condition can be written using the following macros: %{status}.

=item B<--critical-status>

Define the conditions to match to return a critical status (default: '%{status} ne "ok"').
The condition can be written using the following macros: %{status}.

=item B<--warning-temperature*>

Warning threshold for temperature (Celsius).

=item B<--critical-temperature*>

Critical threshold for temperature (Celsius).

=back

=cut
