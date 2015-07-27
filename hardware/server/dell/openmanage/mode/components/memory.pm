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

package hardware::server::dell::openmanage::mode::components::memory;

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

my %failureModes = (
    0 => 'Not failure',
    1 => 'ECC single bit correction warning rate exceeded',
    2 => 'ECC single bit correction failure rate exceeded',
    4 => 'ECC multibit fault encountered',
    8 => 'ECC single bit correction logging disabled',
    16 => 'device disabled because of spare activation',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking Memory Modules");
    $self->{components}->{memory} = {name => 'memory modules', total => 0};
    return if ($self->check_exclude('memory'));
   
    my $oid_memoryDeviceStatus = '.1.3.6.1.4.1.674.10892.1.1100.50.1.5';
    my $oid_memoryDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.1100.50.1.8';
    my $oid_memoryDeviceSize = '.1.3.6.1.4.1.674.10892.1.1100.50.1.14';
    my $oid_memoryDeviceFailureModes = '.1.3.6.1.4.1.674.10892.1.1100.50.1.20';

    my $result = $self->{snmp}->get_table(oid => $oid_memoryDeviceStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_memoryDeviceLocationName, $oid_memoryDeviceSize, $oid_memoryDeviceFailureModes],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $memory_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $memory_Index;
        
        my $memory_deviceStatus = $result->{$key};
        my $memory_deviceLocationName = $result2->{$oid_memoryDeviceLocationName . '.' . $instance};
        my $memory_deviceSize = $result2->{$oid_memoryDeviceSize . '.' . $instance};
        my $memory_deviceFailureModes = $result2->{$oid_memoryDeviceFailureModes . '.' . $instance};
       
        $self->{components}->{memory}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("memory module %d status is %s, failure mode is %s, size is %d KB [location: %s].",
                                    $memory_Index, ${$status{$memory_deviceStatus}}[0], $failureModes{$memory_deviceFailureModes},
                                    $memory_deviceSize, $memory_deviceLocationName
                                    ));

        if ($memory_deviceStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$memory_deviceStatus}}[1],
                                        short_msg => sprintf("memory module %d status is %s",
                                           $memory_Index, ${$status{$memory_deviceStatus}}[0]));
        }

    }
}

1;
