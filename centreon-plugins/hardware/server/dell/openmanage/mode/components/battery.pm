#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::openmanage::mode::components::battery;

use strict;
use warnings;

my %status = (
    1 => ['other', 'CRITICAL'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %reading = (
    1 => 'Predictive Failure',
    2 => 'Failed',
    4 => 'Presence Detected',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking batteries");
    $self->{components}->{battery} = {name => 'batteries', total => 0};
    return if ($self->check_exclude('battery'));
   
    my $oid_batteryStatus = '.1.3.6.1.4.1.674.10892.1.600.50.1.5';
    my $oid_batteryReading = '.1.3.6.1.4.1.674.10892.1.600.50.1.6';
    my $oid_batteryLocationName = '.1.3.6.1.4.1.674.10892.1.600.50.1.7';

    my $result = $self->{snmp}->get_table(oid => $oid_batteryStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_batteryReading, $oid_batteryLocationName],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $battery_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $battery_Index;
        
        my $battery_status = $result->{$key};
        my $battery_reading = $result2->{$oid_batteryReading . '.' . $instance};
        my $battery_locationName = $result2->{$oid_batteryLocationName . '.' . $instance};
       
        $self->{components}->{battery}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("battery %d status is %s, reading is %s [location: %s].",
                                    $battery_Index, ${$status{$battery_status}}[0], $reading{$battery_reading},
                                    $battery_locationName
                                    ));

        if ($battery_status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$battery_status}}[1],
                                        short_msg => sprintf("battery %d status is %s",
                                           $battery_Index, ${$status{$battery_status}}[0]));
        }

    }
}

1;
