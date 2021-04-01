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

package apps::lmsensors::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    lmTempSensorsDevice => { oid => '.1.3.6.1.4.1.2021.13.16.2.1.2' },
    lmTempSensorsValue  => { oid => '.1.3.6.1.4.1.2021.13.16.2.1.3' },
};

my $oid_lmTempSensorsEntry = '.1.3.6.1.4.1.2021.13.16.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_lmTempSensorsEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_lmTempSensorsEntry}})) {
        next if ($oid !~ /^$mapping->{lmTempSensorsValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_lmTempSensorsEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance, name => $result->{lmTempSensorsDevice}));
        $self->{components}->{temperature}->{total}++;

        $result->{lmTempSensorsValue} /= 1000;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' is %s C [instance = %s]",
                                    $result->{lmTempSensorsDevice}, $result->{lmTempSensorsValue}, $instance, 
                                    ));
             
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, name => $result->{lmTempSensorsDevice}, value => $result->{lmTempSensorsValue});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %s C", $result->{lmTempSensorsDevice}, $result->{lmTempSensorsValue}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C', 
            nlabel => 'sensor.temperature.celsius',
            instances => $result->{lmTempSensorsDevice},
            value => $result->{lmTempSensorsValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
