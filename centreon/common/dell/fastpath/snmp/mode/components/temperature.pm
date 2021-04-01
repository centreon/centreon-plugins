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

package centreon::common::dell::fastpath::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (
    0 => 'low',
    1 => 'normal',
    2 => 'warning',
    3 => 'critical',
    4 => 'shutdown',
    5 => 'notpresent',
    6 => 'notoperational',
);

my $mapping1 = {
    boxServicesTempSensorState => { oid => '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.3', map => \%map_temp_status },
    boxServicesTempSensorTemperature => { oid => '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.4' },
};
my $mapping2 = {
    boxServicesTempSensorState => { oid => '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.4', map => \%map_temp_status },
    boxServicesTempSensorTemperature => { oid => '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1.5' },
};
my $oid_boxServicesTempSensorsEntry = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.43.1.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_boxServicesTempSensorsEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my ($result, $exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_boxServicesTempSensorsEntry}})) {
        next if ($oid !~ /^$mapping2->{boxServicesTempSensorState}->{oid}\.(.*)$/);
        my $instance = $1;
        
        if (defined($self->{results}->{$oid_boxServicesTempSensorsEntry}->{$mapping2->{boxServicesTempSensorTemperature}->{oid} . '.' . $instance})) {
            $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_boxServicesTempSensorsEntry}, instance => $instance);
        } else {
            $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$oid_boxServicesTempSensorsEntry}, instance => $instance);
        }
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        if ($result->{boxServicesTempSensorState} =~ /notPresent/i) {
            $self->absent_problem(section => 'temperature', instance => $instance);
            next;
        }
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s, temperature = %s]",
                                                        $instance, $result->{boxServicesTempSensorState}, $instance, defined($result->{boxServicesTempSensorTemperature}) ? $result->{boxServicesTempSensorTemperature} : 'unknown'));
        $exit = $self->get_severity(section => 'temperature', value => $result->{boxServicesTempSensorState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $instance, $result->{boxServicesTempSensorState}));
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{boxServicesTempSensorTemperature});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is '%s' C", $instance, $result->{boxServicesTempSensorTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance,
            value => $result->{boxServicesTempSensorTemperature},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
