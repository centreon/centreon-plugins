#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::devices::video::axis::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temperature_status = (
    1 => 'ok',
    2 => 'failed',
    3 => 'outOfBoundary',
);

my $mapping = {
    axisTemperatureState => { oid => '.1.3.6.1.4.1.368.4.1.3.1.3', map => \%map_temperature_status },
    axisTemperatureCelsius => { oid => '.1.3.6.1.4.1.368.4.1.3.1.4' },
};

my $oid_axisTemperatureEntry = '.1.3.6.1.4.1.368.4.1.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_axisTemperatureEntry, start => $mapping->{axisTemperatureState}->{oid}, end => $mapping->{axisTemperatureCelsius}->{oid} };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_axisTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{axisTemperatureState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_axisTemperatureEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature camera is %d°C (Sensor status is %s).",
                                    $result->{axisTemperatureCelsius}, $result->{axisTemperatureState}
                                    ));
        my $exit = $self->get_severity(section => 'temperature', value => $result->{axisTemperatureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Temperature '%s' and State is %s", 
                                                             $result->{axisTemperaturecelsius}, $result->{axisTemperatureState}));
        }
    

    if (defined($result->{axisTemperatureCelsius}) && $result->{axisTemperatureCelsius} != -1) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{axisTemperatureCelsius});
            if ($checked == 0) {
                my $warn_th = '55';
                my $crit_th = '60';
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $result->{axisTemperatureCelsius}));
            }
            $self->{output}->perfdata_add(label => "temp_device_" . $instance, unit => '°C',
                                          value => $result->{axisTemperatureCelsius},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;
