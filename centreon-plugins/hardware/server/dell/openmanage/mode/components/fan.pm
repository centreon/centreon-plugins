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

package hardware::server::dell::openmanage::mode::components::fan;

use strict;
use warnings;

my %status = (
    1 => ['other', 'CRITICAL'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['nonCriticalUpper', 'WARNING'],
    5 => ['criticalUpper', 'CRITICAL'],
    6 => ['nonRecoverableUpper', 'CRITICAL'],
    7 => ['nonCriticalLower', 'WARNING'],
    8 => ['criticalLower', 'CRITICAL'],
    9 => ['nonRecoverableLower', 'CRITICAL'],
    10 => ['failed', 'CRITICAL']

);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0};
    return if ($self->check_exclude('fan'));
   
    my $oid_coolingDeviceStatus = '.1.3.6.1.4.1.674.10892.1.700.12.1.5';
    my $oid_coolingDeviceReading = '.1.3.6.1.4.1.674.10892.1.700.12.1.6';
    my $oid_coolingDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.700.12.1.8';

    my $result = $self->{snmp}->get_table(oid => $oid_coolingDeviceStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_coolingDeviceReading, $oid_coolingDeviceLocationName],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $fan_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $fan_Index;
        
        my $fan_Status = $result->{$key};
        my $fan_Reading = $result2->{$oid_coolingDeviceReading . '.' . $instance};
        my $fan_LocationName = $result2->{$oid_coolingDeviceLocationName . '.' . $instance};

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan %d status is %s, speed is %d RPM [location: %s].",
                                    $fan_Index, ${$status{$fan_Status}}[0], $fan_Reading,
                                    $fan_LocationName
                                    ));
        if ($fan_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$fan_Status}}[1],
                                        short_msg => sprintf("fan %d status is %s",
                                           $fan_Index, ${$status{$fan_Status}}[0]));
        }
    }
}

1;
