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

package storage::quantum::scalar::snmp::mode::components::voltage;

use strict;
use warnings;
use storage::quantum::scalar::snmp::mode::components::resources qw($map_sensor_status);

# In MIB 'QUANTUM-MIDRANGE-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryVoltageSensorName     => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.110.2.1.2' },
    libraryVoltageSensorLocation => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.110.2.1.3' },
    libraryVoltageSensorStatus   => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.110.2.1.5', map => $map_sensor_status },
    libraryVoltageSensorValue    => { oid => '.1.3.6.1.4.1.3697.1.10.15.5.110.2.1.6' }, # in mV
};
my $oid_libraryVoltageSensorEntry = '.1.3.6.1.4.1.3697.1.10.15.5.110.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_libraryVoltageSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_libraryVoltageSensorEntry}})) {
        next if ($oid !~ /^$mapping->{libraryVoltageSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_libraryVoltageSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("voltage '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{libraryVoltageSensorLocation}, $result->{libraryVoltageSensorStatus}, $instance, 
                                    $result->{libraryVoltageSensorValue}));
        
        $exit = $self->get_severity(label => 'default', section => 'voltage', instance => $instance, value => $result->{libraryVoltageSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' status is '%s'", $result->{libraryVoltageSensorLocation}, $result->{libraryVoltageSensorStatus}));
        }

        next if (!defined($result->{libraryVoltageSensorValue}) || $result->{libraryVoltageSensorValue} !~ /[0-9]/);

        $result->{libraryVoltageSensorValue} /= 1000;
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{libraryVoltageSensorValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Voltage '%s' is %s V", $result->{libraryVoltageSensorLocation}, $result->{libraryVoltageSensorValue})
            );
        }
        
        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensor.voltage.volt', unit => 'V',
            instances => $result->{libraryVoltageSensorLocation},
            value => $result->{libraryVoltageSensorValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
