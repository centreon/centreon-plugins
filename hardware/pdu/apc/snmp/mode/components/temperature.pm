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

package hardware::pdu::apc::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_status = (
    1 => 'notPresent',
    2 => 'belowMin',
    3 => 'belowLow',
    4 => 'normal',
    5 => 'aboveHigh',
    6 => 'aboveMax',
);
my %map_type = (
    1 => 'temperatureOnly',
    2 => 'temperatureHumidity',
    3 => 'commsLost',
    4 => 'notInstalled',
);

# In MIB 'PowerNet-MIB'
my $mapping = {
    rPDU2SensorTempHumidityStatusName => { oid => '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.3' },
    rPDU2SensorTempHumidityStatusNumber => { oid => '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.4' },
    rPDU2SensorTempHumidityStatusType => { oid => '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.5', map => \%map_type },
    rPDU2SensorTempHumidityStatusTempC => { oid => '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.8' },
    rPDU2SensorTempHumidityStatusTempStatus => { oid => '.1.3.6.1.4.1.318.1.1.26.10.2.2.1.9', map => \%map_status },
};
my $oid_rPDU2SensorTempHumidityStatusEntry = '.1.3.6.1.4.1.318.1.1.26.10.2.2.1';

sub load {
    my ($self) = @_;
    
    foreach (@{$self->{request}}) {
        return if ($_->{oid} eq $oid_rPDU2SensorTempHumidityStatusEntry);
    }
    push @{$self->{request}}, { oid => $oid_rPDU2SensorTempHumidityStatusEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rPDU2SensorTempHumidityStatusEntry}})) {
        next if ($oid !~ /^$mapping->{rPDU2SensorTempHumidityStatusTempStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rPDU2SensorTempHumidityStatusEntry}, instance => $instance);
        
        next if ($result->{rPDU2SensorTempHumidityStatusType} !~ /temperatureOnly|temperatureHumidity/i);
        next if ($self->check_filter(section => 'temperature', instance => $result->{rPDU2SensorTempHumidityStatusNumber}));
        next if ($result->{rPDU2SensorTempHumidityStatusTempStatus} !~ /notPresent/i && 
                 $self->absent_problem(section => 'temperature', instance => $result->{rPDU2SensorTempHumidityStatusNumber}));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance: %s, value: %s]", 
                                    $result->{rPDU2SensorTempHumidityStatusName}, $result->{rPDU2SensorTempHumidityStatusTempStatus}, 
                                    $result->{rPDU2SensorTempHumidityStatusNumber}, $result->{rPDU2SensorTempHumidityStatusTempC}));
        my $exit = $self->get_severity(section => 'temperature', instance => $result->{rPDU2SensorTempHumidityStatusNumber}, value => $result->{rPDU2SensorTempHumidityStatusTempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s", 
                                                             $result->{rPDU2SensorTempHumidityStatusName}, $result->{rPDU2SensorTempHumidityStatusTempStatus}));
        }
        
        if (defined($result->{rPDU2SensorTempHumidityStatusTempC}) && $result->{rPDU2SensorTempHumidityStatusTempC} =~ /[0-9]/) {
            my $value = $result->{rPDU2SensorTempHumidityStatusTempC} / 10;
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $result->{rPDU2SensorTempHumidityStatusNumber}, value => $value);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' value is %s C", $result->{rPDU2SensorTempHumidityStatusName}, $value));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.sensor.temperature.celsius',
                instances => $result->{rPDU2SensorTempHumidityStatusName},
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
