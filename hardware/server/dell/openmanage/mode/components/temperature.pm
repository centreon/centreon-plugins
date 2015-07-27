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

package hardware::server::dell::openmanage::mode::components::temperature;

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
    10 => ['failed', 'CRITICAL'],
);

my %type = (
    1 => 'other',
    2 => 'unknown',
    3 => 'Ambient ESM',
    4 => 'Discrete',
);

my %discreteReading = (
    1 => 'good',
    2 => 'bad',
);


sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking temperature probes");
    $self->{components}->{temperature} = {name => 'temperature probes', total => 0};
    return if ($self->check_exclude('temperature'));
   
    my $oid_temperatureProbeStatus = '.1.3.6.1.4.1.674.10892.1.700.20.1.5';
    my $oid_temperatureProbeReading = '.1.3.6.1.4.1.674.10892.1.700.20.1.6';
    my $oid_temperatureProbeType = '.1.3.6.1.4.1.674.10892.1.700.20.1.7';
    my $oid_temperatureProbeLocationName = '.1.3.6.1.4.1.674.10892.1.700.20.1.8';

    my $result = $self->{snmp}->get_table(oid => $oid_temperatureProbeStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_temperatureProbeReading, $oid_temperatureProbeType, $oid_temperatureProbeLocationName],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $temperature_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $temperature_Index;
        
        my $temperature_Status = $result->{$key};
        my $temperature_Reading = $result2->{$oid_temperatureProbeReading . '.' . $instance};
        my $temperature_Type = $result2->{$oid_temperatureProbeType . '.' . $instance};
        my $temperature_LocationName = $result2->{$oid_temperatureProbeLocationName . '.' . $instance};

        my $temperature_Reading2 = $temperature_Reading/10;

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature probe %d status is %s, temperature is %.1f °C [location: %s].",
                                    $temperature_Index, ${$status{$temperature_Status}}[0], $temperature_Reading2,
                                    $temperature_LocationName
                                    ));
        if ($temperature_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$temperature_Status}}[1],
                                        short_msg => sprintf("temperature probe %d status is %s",
                                           $temperature_Index, ${$status{$temperature_Status}}[0]));
        }

    }
}

1;
