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

package storage::hp::lefthand::mode::components::device;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{device} = {name => 'devices', total => 0};
    $self->{output}->output_add(long_msg => "Checking devices");
    return if ($self->check_exclude('device'));
    
    my $device_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.4.1.0";
    my $device_name_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.14';
    my $device_serie_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.7';
    my $device_present_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.90';
    my $device_present_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.91';
    my $device_health_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.17'; # normal, marginal, faulty
    my $device_health_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.18';
    my $device_temperature_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.9';
    my $device_temperature_critical_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.10';
    my $device_temperature_limit_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.11';
    my $device_temperature_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.12';
    return if ($self->{global_information}->{$device_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$device_name_oid, $device_serie_oid,
                                 $device_present_state_oid, $device_present_status_oid,
                                 $device_health_state_oid, $device_health_status_oid,
                                 $device_temperature_oid, $device_temperature_critical_oid,
                                 $device_temperature_limit_oid, $device_temperature_status_oid],
                        begin => 1, end => $self->{global_information}->{$device_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_device = $self->{global_information}->{$device_count_oid};
    for (my $i = 1; $i <= $number_device; $i++) {
        my $device_name = $result->{$device_name_oid . "." . $i};
        my $device_serie = $result->{$device_serie_oid . "." . $i};
        my $device_present_state = $result->{$device_present_state_oid . "." . $i};
        my $device_present_status = $result->{$device_present_status_oid . "." . $i};
        my $device_health_state = $result->{$device_health_state_oid . "." . $i};
        my $device_health_status = $result->{$device_health_status_oid . "." . $i};
        my $device_temperature = $result->{$device_temperature_oid . "." . $i};
        my $device_temperature_critical = $result->{$device_temperature_critical_oid . "." . $i};
        my $device_temperature_limit = $result->{$device_temperature_limit_oid . "." . $i};
        my $device_temperature_status = $result->{$device_temperature_status_oid . "." . $i};
        
        $self->{components}->{device}->{total}++;
        
        $self->{output}->output_add(long_msg => "Storage Device '$device_name' and Serial Number '$device_serie', state = '$device_present_state'");
        # Check if present
        if ($device_present_state =~ /off_and_secured|off_or_removed/i) {
            next;
        }
        
        # Check global health
        if ($device_health_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Storage Device '" .  $device_name . "' Smart Health problem '" . $device_health_state . "'");
        }
        $self->{output}->output_add(long_msg => "    Smart Health status = '" . $device_health_status  . "', Smart Health state = '" . $device_health_state . "'");
        
        # Check temperature
        if ($device_temperature >= $device_temperature_critical) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Device Storage '" . $device_name . "' temperature too high");
        } elsif ($device_temperature >= $device_temperature_limit) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Device Storage '" . $device_name . "' over the limit");
        }
        $self->{output}->output_add(long_msg => "    Temperature value = '" . $device_temperature  . "' (limit >= $device_temperature_limit, critical >= $device_temperature_critical)");
        $self->{output}->perfdata_add(label => $device_name . "_temp",
                                      value => $device_temperature,
                                      warning => $device_temperature_limit, critical => $device_temperature_critical);
    }
}

1;