#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package hardware::pdu::sentry::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (
    0 => 'normal',
    1 => 'notFound',
    2 => 'reading',
    3 => 'tempLow',
    4 => 'tempHigh',
    5 => 'readError',
    6 => 'lost',
    7 => 'noComm'
);

my $mapping = {
    tempHumidSensorID => { oid => '.1.3.6.1.4.1.1718.3.2.5.1.2' },
    tempHumidSensorName => { oid => '.1.3.6.1.4.1.1718.3.2.5.1.3' },
    tempHumidSensorTempValue => { oid => '.1.3.6.1.4.1.1718.3.2.5.1.6' },
    tempHumidSensorTempStatus => { oid => '.1.3.6.1.4.1.1718.3.2.5.1.5', map => \%map_temp_status },
};
my $oid_tempHumidSensorEntry = '.1.3.6.1.4.1.1718.3.2.5.1';

sub load {
    my ($self) = @_;
    
    foreach (@{$self->{request}}) {
        return if ($_->{oid} eq $oid_tempHumidSensorEntry);
    }
    push @{$self->{request}}, { oid => $oid_tempHumidSensorEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_tempHumidSensorEntry}})) {
        next if ($oid !~ /^$mapping->{tempHumidSensorTempStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_tempHumidSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $result->{tempHumidSensorID}));

        if ($result->{tempHumidSensorTempStatus} =~ /notFound/i) {
            $self->{output}->output_add(long_msg => "skipping not present temperature sensor for '" . $result->{tempHumidSensorName}, debug => 1);
            next;
        }

        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance: %s, value: %s]", 
                                    $result->{tempHumidSensorName}, $result->{tempHumidSensorTempStatus},
                                    $result->{tempHumidSensorID}, $result->{tempHumidSensorTempValue} / 10));
        my $exit = $self->get_severity(section => 'temperature', instance => $result->{tempHumidSensorID}, value => $result->{tempHumidSensorTempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s", 
                                                             $result->{tempHumidSensorName}, $result->{tempHumidSensorTempStatus}));
        }
        
        if (defined($result->{tempHumidSensorTempValue}) && $result->{tempHumidSensorTempValue} =~ /[0-9]/) {
            my $value = $result->{tempHumidSensorTempValue} / 10;
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $result->{tempHumidSensorID}, value => $value);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' value is %s C", $result->{tempHumidSensorName}, $value));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.sensor.temperature.celsius',
                instances => $result->{tempHumidSensorName},
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
