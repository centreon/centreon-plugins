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

package centreon::common::cisco::standard::snmp::mode::components::sensor;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_sensor_status = (
    1 => 'ok',
    2 => 'unavailable',
    3 => 'nonoperational',
);
my %map_sensor_type = (
    1 => 'other',
    2 => 'unknown',
    3 => 'voltsAC',
    4 => 'voltsDC',
    5 => 'amperes',
    6 => 'watts',
    7 => 'hertz',
    8 => 'celsius',
    9 => 'percentRH',
    10 => 'rpm',
    11 => 'cmm',
    12 => 'truthvalue',
    13 => 'specialEnum',
    14 => 'dBm',
);
my %map_scale = (
    1 => -24, # yocto, 
    2 => -21, # zepto
    3 => -18, # atto
    4 => -15, # femto 
    5 => -12, # pico
    6 => -9, # nano
    7 => -6, # micro
    8 => -3, # milli
    9 => 0, #units
    10 => 3, #kilo
    11 => 6, #mega
    12 => 9, #giga
    13 => 12, #tera
    14 => 18, #exa
    15 => 15, #peta
    16 => 21, #zetta
    17 => 24, #yotta
);
my %map_severity = (
    1 => 'other',
    10 => 'minor',
    20 => 'major',
    30 => 'critical',
);
my %map_relation = (
    1 => 'lessThan',
    2 => 'lessOrEqual',
    3 => 'greaterThan',
    4 => 'greaterOrEqual',
    5 => 'equalTo',
    6 => 'notEqualTo',
);
my %perfdata_unit = (
    'other' => '',
    'unknown' => '',
    'voltsAC' => 'V',
    'voltsDC' => 'V',
    'amperes' => 'A',
    'watts' => 'W',
    'hertz' => 'Hz',
    'celsius' => 'C',
    'percentRH' => '%',
    'rpm' => 'rpm',
    'cmm' => '',
    'truthvalue' => '',
    'specialEnum' => '',
    'dBm' => 'dBm',
);

# In MIB 'CISCO-ENTITY-SENSOR-MIB'
my $mapping = {
    entSensorType            => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.1', map => \%map_sensor_type },
    entSensorScale           => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.2', map => \%map_scale },
    entSensorPrecision       => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.3' },
    entSensorValue           => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.4' },
    entSensorStatus          => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.5', map => \%map_sensor_status },
    entSensorValueUpdateRate => { oid => '.1.3.6.1.4.1.9.9.91.1.1.1.1.7' }, # 0 means no threshold check
};
my $mapping2 = {
    entSensorThresholdSeverity => { oid => '.1.3.6.1.4.1.9.9.91.1.2.1.1.2', map => \%map_severity },
    entSensorThresholdRelation => { oid => '.1.3.6.1.4.1.9.9.91.1.2.1.1.3', map => \%map_relation },
    entSensorThresholdValue    => { oid => '.1.3.6.1.4.1.9.9.91.1.2.1.1.4' },
};
my $oid_entSensorValueEntry     = '.1.3.6.1.4.1.9.9.91.1.1.1.1';
my $oid_entSensorThresholdEntry = '.1.3.6.1.4.1.9.9.91.1.2.1.1';
my $oid_entPhysicalDescr        = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_entSensorValueEntry, end => $mapping->{entSensorStatus}->{oid} }, 
        { oid => $oid_entSensorThresholdEntry, end => $mapping2->{entSensorThresholdValue}->{oid} };
}

sub get_default_warning_threshold {
    my ($self, %options) = @_;
    my ($high_th, $low_th);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_entSensorThresholdEntry}})) {
        next if ($oid !~ /^$mapping2->{entSensorThresholdSeverity}->{oid}\.$options{instance}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_entSensorThresholdEntry}, instance => $options{instance} . '.' . $instance);
        next if ($result->{entSensorThresholdSeverity} ne 'minor');

        my $value = $result->{entSensorThresholdValue} * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision})));
        if ($result->{entSensorThresholdRelation} eq 'greaterOrEqual') {
            $high_th = $value - (1 * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision}))));
        } elsif ($result->{entSensorThresholdRelation} eq 'greaterThan') {
            $high_th = $value;
        } elsif ($result->{entSensorThresholdRelation} eq 'lessOrEqual') {
            $low_th = $value + (1 * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision}))));
        } elsif ($result->{entSensorThresholdRelation} eq 'lessThan') {
            $low_th = $value;
        }
    }

    # when it's the same value. Means no threshold.
    if (defined($low_th) && defined($high_th) && $high_th <= $low_th) {
        return '';
    }
    my $th = '';
    $th = centreon::plugins::misc::expand_exponential(value => $low_th) . ':' if (defined($low_th));
    $th .= centreon::plugins::misc::expand_exponential(value => $high_th) if (defined($high_th));
    $th = '~:' . $high_th if (defined($high_th) && !defined($low_th));

    return $th;
}

sub get_default_critical_threshold {
    my ($self, %options) = @_;
    my ($high_th, $low_th);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_entSensorThresholdEntry}})) {
        next if ($oid !~ /^$mapping2->{entSensorThresholdSeverity}->{oid}\.$options{instance}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_entSensorThresholdEntry}, instance => $options{instance} . '.' . $instance);
        next if ($result->{entSensorThresholdSeverity} !~ /major|critical/);

        my $value = $result->{entSensorThresholdValue} * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision})));
        if ($result->{entSensorThresholdRelation} eq 'greaterOrEqual') {
            $high_th = $value - (1 * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision}))));
        } elsif ($result->{entSensorThresholdRelation} eq 'greaterThan') {
            $high_th = $value;
        } elsif ($result->{entSensorThresholdRelation} eq 'lessOrEqual') {
            $low_th = $value + (1 * (10 ** ($options{result}->{entSensorScale}) * (10 ** -($options{result}->{entSensorPrecision}))));
        } elsif ($result->{entSensorThresholdRelation} eq 'lessThan') {
            $low_th = $value;
        }
    }

    # when it's the same value. Means no threshold.
    if (defined($low_th) && defined($high_th) && $high_th <= $low_th) {
        return '';
    }
    my $th = '';
    $th = centreon::plugins::misc::expand_exponential(value => $low_th) . ':' if (defined($low_th));
    $th .= centreon::plugins::misc::expand_exponential(value => $high_th) if (defined($high_th));
    $th = '~:' . $high_th if (defined($high_th) && !defined($low_th));

    return $th;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    my $verify_th_update = {};
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_entSensorValueEntry}})) {
        next if ($oid !~ /^$mapping->{entSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_entSensorValueEntry}, instance => $instance);

        next if (!defined($self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance}));
        my $sensor_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};

        next if ($self->check_filter(section => 'sensor', instance => $result->{entSensorType} . '.' . $instance));
        $self->{components}->{sensor}->{total}++;

        $result->{entSensorValue} = defined($result->{entSensorValue}) ? 
           $result->{entSensorValue} * (10 ** ($result->{entSensorScale}) * (10 ** -($result->{entSensorPrecision}))) : undef;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Sensor '%s' status is '%s' [instance: %s] [value: %s %s]", 
                $sensor_descr, $result->{entSensorStatus},
                $instance, 
                defined($result->{entSensorValue}) ? $result->{entSensorValue} : '-',
                $result->{entSensorType}
            )
        );
        my $exit = $self->get_severity(section => $result->{entSensorType}, label => 'sensor', value => $result->{entSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Sensor '%s/%s' status is '%s'", 
                    $sensor_descr, $instance, $result->{entSensorStatus}
                )
            );
        }

        next if (!defined($result->{entSensorValue}) || $result->{entSensorValue} !~ /[0-9]/);

        my $component = 'sensor.' . $result->{entSensorType};
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $component, instance => $instance, value => $result->{entSensorValue});
        if ($checked == 0) {
            my $warn_th = get_default_warning_threshold($self, instance => $instance, result => $result);
            my $crit_th = get_default_critical_threshold($self, instance => $instance, result => $result);
            $self->{perfdata}->threshold_validate(label => 'warning-' . $component . '-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-' . $component . '-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $component . '-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $component  . '-instance-' . $instance);
            $exit2 = $self->{perfdata}->threshold_check(
                value => $result->{entSensorValue}, 
                threshold => [
                    { label => 'critical-' . $component  . '-instance-' . $instance, exit_litteral => 'critical' }, 
                    { label => 'warning-' . $component . '-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            # we verify if it's a entSensorValueUpdateRate is not zero
            if ($checked == 0) {
                $verify_th_update->{$instance} = { result => $result, warn => $warn, crit => $crit, sensor_descr => $sensor_descr, status => $exit2 };
                next;
            }
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Sensor '%s/%s' is %s %s",
                    $sensor_descr, $instance, $result->{entSensorValue}, $perfdata_unit{$result->{entSensorType}}
                )
            );
        }

        $self->{output}->perfdata_add(
            label => $component, unit => $perfdata_unit{$result->{entSensorType}},
            nlabel => 'hardware.' . $component, 
            instances => $sensor_descr,
            value => $result->{entSensorValue},
            warning => $warn,
            critical => $crit
        );
    }

    return if (scalar(keys %$verify_th_update) <= 0);
    my $snmp_result = $self->{snmp}->get_leef(oids => [map($mapping->{entSensorValueUpdateRate}->{oid} . '.' . $_, keys(%$verify_th_update))]);
    foreach (keys %$verify_th_update) {
        my ($warn, $crit) = ($verify_th_update->{$_}->{warn}, $verify_th_update->{$_}->{crit});
        if (defined($snmp_result->{$mapping->{entSensorValueUpdateRate}->{oid} . '.' . $_}) &&
            $snmp_result->{$mapping->{entSensorValueUpdateRate}->{oid} . '.' . $_} == 0) {
            ($warn, $crit) = ('', '');
            $verify_th_update->{$_}->{status} = 'ok';
        }

        if (!$self->{output}->is_status(value => $verify_th_update->{$_}->{status}, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $verify_th_update->{$_}->{status},
                short_msg => sprintf(
                    "Sensor '%s/%s' is %s %s",
                    $verify_th_update->{$_}->{sensor_descr}, $_,
                    $verify_th_update->{$_}->{result}->{entSensorValue},
                    $perfdata_unit{  $verify_th_update->{$_}->{result}->{entSensorType} }
                )
            );
        }

        $self->{output}->perfdata_add(
            label => 'sensor.' . $verify_th_update->{$_}->{result}->{entSensorType},
            unit => $perfdata_unit{ $verify_th_update->{$_}->{result}->{entSensorType} },
            nlabel => 'hardware.sensor.' . $verify_th_update->{$_}->{result}->{entSensorType}, 
            instances => $verify_th_update->{$_}->{sensor_descr},
            value => $verify_th_update->{$_}->{result}->{entSensorValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
