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

package storage::quantum::scalar::snmp::mode::components::temperature;

use strict;
use warnings;
use storage::quantum::scalar::snmp::mode::components::resources qw($map_sensor_status);

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryTemperatureSensorName     => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.2' },
    libraryTemperatureSensorLocation => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.3' },
    libraryTemperatureSensorStatus   => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.4', map => $map_sensor_status },
    libraryTemperatureSensorValue    => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1.5' },
};
my $oid_libraryTemperatureSensorEntry = '.1.3.6.1.4.1.3697.1.10.15.5.120.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_libraryTemperatureSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_libraryTemperatureSensorEntry}})) {
        next if ($oid !~ /^$mapping->{libraryTemperatureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_libraryTemperatureSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{libraryTemperatureSensorLocation}, $result->{libraryTemperatureSensorStatus}, $instance, 
                                    $result->{libraryTemperatureSensorValue}));
        
        $exit = $self->get_severity(label => 'default', section => 'temperature', instance => $instance, value => $result->{libraryTemperatureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{libraryTemperatureSensorLocation}, $result->{libraryTemperatureSensorStatus}));
        }

        next if (!defined($result->{libraryTemperatureSensorValue}) || $result->{libraryTemperatureSensorValue} !~ /[0-9]/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{libraryTemperatureSensorValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Temperature '%s' is %s degree centigrade", $result->{libraryTemperatureSensorLocation}, $result->{libraryTemperatureSensorValue})
            );
        }
        
        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.temperature.celsius', unit => 'C',
            instances => $result->{libraryTemperatureSensorLocation},
            value => $result->{libraryTemperatureSensorValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
