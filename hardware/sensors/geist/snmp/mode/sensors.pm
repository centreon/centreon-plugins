#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::sensors::geist::snmp::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'internal', type => 1, cb_prefix_output => 'prefix_internal_output', message_multiple => 'All internal sensors are ok', skipped_code => { -10 => 1 } },
        { name => 'climate', type => 1, cb_prefix_output => 'prefix_climate_output', message_multiple => 'All climate sensors are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{climate} = [
        { label => 'climate-temperature', nlabel => 'sensor.climate.temperature.celsius', set => {
                key_values => [ { name => 'climateTempC', no_value => 0, } ],
                output_template => 'temperature %s C',
                perfdatas => [
                    { value => 'climateTempC', template => '%s', unit => 'C', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'climate-humidity', nlabel => 'sensor.climate.humidity.percentage', set => {
                key_values => [ { name => 'climateHumidity', no_value => 0 } ],
                output_template => 'humidity %.2f %%',
                perfdatas => [
                    { value => 'climateHumidity', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'climate-light', nlabel => 'sensor.climate.ambientlight.percentage', set => {
                key_values => [ { name => 'climateLight', no_value => 0 } ],
                output_template => 'ambient light %.2f %%',
                perfdatas => [
                    { value => 'climateLight', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'climate-airflow', nlabel => 'sensor.climate.airflow.percentage', set => {
                key_values => [ { name => 'climateAirflow', no_value => 0 } ],
                output_template => 'airflow %.2f %%',
                perfdatas => [
                    { value => 'climateAirflow', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'climate-sound', nlabel => 'sensor.climate.sound.percentage', set => {
                key_values => [ { name => 'climateSound', no_value => 0 } ],
                output_template => 'sound %.2f %%',
                perfdatas => [
                    { value => 'climateSound', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'climate-dewpoint', nlabel => 'sensor.climate.dewpoint.celsius', set => {
                key_values => [ { name => 'climateDewPointC', no_value => 0 } ],
                output_template => 'dew point %s C',
                perfdatas => [
                    { value => 'climateDewPointC', template => '%s', unit => 'C', label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{internal} = [
        { label => 'internal-temperature', nlabel => 'sensor.internal.temperature.celsius', set => {
                key_values => [ { name => 'internalTemp', no_value => 0, } ],
                output_template => 'temperature %s C',
                perfdatas => [
                    { value => 'internalTemp', template => '%s', unit => 'C', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'internal-humidity', nlabel => 'sensor.internal.humidity.percentage', set => {
                key_values => [ { name => 'internalHumidity', no_value => 0 } ],
                output_template => 'humidity %.2f %%',
                perfdatas => [
                    { value => 'internalHumidity', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'internal-dewpoint', nlabel => 'sensor.internal.dewpoint.celsius', set => {
                key_values => [ { name => 'internalDewPoint', no_value => 0 } ],
                output_template => 'dew point %s C',
                perfdatas => [
                    { value => 'internalDewPoint', template => '%s', unit => 'C', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_climate_output {
    my ($self, %options) = @_;

    return "Climate '" . $options{instance_value}->{climateName} . "' ";
}

sub prefix_internal_output {
    my ($self, %options) = @_;

    return "Internal '" . $options{instance_value}->{internalName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub get_climate_v3 {
    my ($self, %options) = @_;

    return if (!defined($options{count}) || $options{count} == 0);

    my $mapping = {
        climateName      => { oid => '.1.3.6.1.4.1.21239.2.2.1.3' },
        climateTempC     => { oid => '.1.3.6.1.4.1.21239.2.2.1.5' },
        climateHumidity  => { oid => '.1.3.6.1.4.1.21239.2.2.1.7' },
        climateLight     => { oid => '.1.3.6.1.4.1.21239.2.2.1.8' },
        climateAirflow   => { oid => '.1.3.6.1.4.1.21239.2.2.1.9' },
        climateDewPointC => { oid => '.1.3.6.1.4.1.21239.2.2.1.31' },
    };

    my $oid_climateEntry = '.1.3.6.1.4.1.21239.2.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_climateEntry, start => $mapping->{climateName}->{oid},
    );

    $self->{climate} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{climateName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $self->{climate}->{$result->{climateName}} = { %$result };
    }
}

sub geist_v3 {
    my ($self, %options) = @_;

    my $oid_climateCount = '.1.3.6.1.4.1.21239.2.1.8.1.2.0';
    my $oid_tempSensorCount = '.1.3.6.1.4.1.21239.2.1.8.1.4.0';
    my $oid_airflowSensorCount = '.1.3.6.1.4.1.21239.2.1.8.1.5.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_climateCount, $oid_tempSensorCount, $oid_airflowSensorCount],
    );

    return 1 if (!defined($snmp_result->{$oid_climateCount}));

    $self->get_climate_v3(%options, count => $snmp_result->{$oid_climateCount});

    return 0;
}

sub get_internal_v4 {
    my ($self, %options) = @_;

    my $mapping = {
        internalName     => { oid => '.1.3.6.1.4.1.21239.5.1.2.1.3' },
        internalTemp     => { oid => '.1.3.6.1.4.1.21239.5.1.2.1.5' },
        internalHumidity => { oid => '.1.3.6.1.4.1.21239.5.1.2.1.6' },
        internalDewPoint => { oid => '.1.3.6.1.4.1.21239.5.1.2.1.7' },
    };

    my $oid_internalEntry = '.1.3.6.1.4.1.21239.5.1.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_internalEntry, start => $mapping->{internalName}->{oid},
    );

    $self->{internal} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{internalName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if ($options{temp_unit} eq 'F') {
            $result->{internalTemp} = centreon::plugins::misc::convert_fahrenheit(value => $result->{internalTemp});
            $result->{internalDewPoint} = centreon::plugins::misc::convert_fahrenheit(value => $result->{internalDewPoint});
        }
        
        $result->{internalTemp} /= 10;
        $result->{internalDewPoint} /= 10;
        $self->{internal}->{$result->{internalName}} = { %$result };
    }
}

sub geist_v4 {
    my ($self, %options) = @_;

    my $oid_temperatureUnits = '.1.3.6.1.4.1.21239.5.1.1.7.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_temperatureUnits], nothing_quit => 1
    );
    
    my $temp_unit = $snmp_result->{$oid_temperatureUnits} == 1 ? 'C' : 'F';
    $self->get_internal_v4(%options, temp_unit => $temp_unit);
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($self->geist_v3(%options)) {
        $self->geist_v4(%options)
    }
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'climate-temperature', 'climate-humidity', 'climate-light',
'climate-airflow', 'climate-sound', 'climate-dewpoint',
'internal-temperature', 'internal-humidity', 'internal-dewpoint'.

=back

=cut
