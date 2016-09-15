#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::lefthand::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{temperature} = {name => 'temperature sensors', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperature sensors");
    return if ($self->check_exclude('temperature'));
    
    my $temperature_sensor_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.120.0";
    my $temperature_sensor_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.2";
    my $temperature_sensor_value_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.3";
    my $temperature_sensor_critical_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.4";
    my $temperature_sensor_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.5"; # warning. lower than critical
    my $temperature_sensor_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.90";
    my $temperature_sensor_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.121.1.91";
    return if ($self->{global_information}->{$temperature_sensor_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$temperature_sensor_name_oid, $temperature_sensor_value_oid,
                                 $temperature_sensor_critical_oid, $temperature_sensor_limit_oid, $temperature_sensor_state_oid, $temperature_sensor_status_oid],
                        begin => 1, end => $self->{global_information}->{$temperature_sensor_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_temperature = $self->{global_information}->{$temperature_sensor_count_oid};
    for (my $i = 1; $i <= $number_temperature; $i++) {
        my $ts_name = $result->{$temperature_sensor_name_oid . "." . $i};
        my $ts_value = $result->{$temperature_sensor_value_oid . "." . $i};
        my $ts_critical = $result->{$temperature_sensor_critical_oid . "." . $i};
        my $ts_limit = $result->{$temperature_sensor_limit_oid . "." . $i};
        my $ts_state = $result->{$temperature_sensor_state_oid . "." . $i};
        my $ts_status = $result->{$temperature_sensor_status_oid . "." . $i};
        
        $self->{components}->{temperature}->{total}++;
        
        if ($ts_value >= $ts_critical) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' too high");
        } elsif ($ts_value >= $ts_limit) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' over the limit");
        }
        $self->{output}->output_add(long_msg => "Temperature sensor '" .  $ts_name . "' value = '" . $ts_value  . "' (limit >= $ts_limit, critical >= $ts_critical)");
        $self->{output}->perfdata_add(label => $ts_name . "_temp",
                                      value => $ts_value,
                                      warning => $ts_limit, critical => $ts_critical);
 
        if ($ts_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Temperature sensor '" .  $ts_name . "' problem '" . $ts_state . "'");
        }
        $self->{output}->output_add(long_msg => "Temperature sensor '" .  $ts_name . "' status = '" . $ts_status  . "', state = '" . $ts_state . "'");
    }
}

1;