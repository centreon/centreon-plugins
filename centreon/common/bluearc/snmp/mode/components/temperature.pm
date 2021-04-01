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

package centreon::common::bluearc::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_status = (
    1 => 'ok', 2 => 'tempWarning', 3 => 'tempSevere',
    4 => 'tempSensorFailed', 5 => 'tempSensorWarning',
    6 => 'unknown',
);

my $mapping = {
    temperatureSensorStatus     => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.2.1.9.1.3', map => \%map_status },
    temperatureSensorCReading   => { oid => '.1.3.6.1.4.1.11096.6.1.1.1.2.1.9.1.4' },
};
my $oid_temperatureSensorEntry = '.1.3.6.1.4.1.11096.6.1.1.1.2.1.9.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_temperatureSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureSensorEntry}})) {
        next if ($oid !~ /^$mapping->{temperatureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $instance, $result->{temperatureSensorStatus}, $instance, 
                                    $result->{temperatureSensorCReading}));
        
        my $exit = $self->get_severity(section => 'temperature', value => $result->{temperatureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $instance, $result->{temperatureSensorStatus}));
            next;
        }
     
        if (defined($result->{temperatureSensorCReading}) && $result->{temperatureSensorCReading} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureSensorCReading});
            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $result->{temperatureSensorCReading}));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $instance,
                value => $result->{temperatureSensorCReading},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
