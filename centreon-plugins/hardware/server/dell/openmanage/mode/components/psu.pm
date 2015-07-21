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

package hardware::server::dell::openmanage::mode::components::psu;

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

my %type = (
    1 => 'other',
    2 => 'unknown',
    3 => 'Linear',
    4 => 'switching',
    5 => 'Battery',
    6 => 'UPS',
    7 => 'Converter',
    8 => 'Regulator',
    9 => 'AC',
    10 => 'DC',
    11 => 'VRM',
);

my %state = (
    1 => 'present',
    2 => 'failure',
    4 => 'predictiveFailure',
    8 => 'ACLost',
    16 => 'ACLostOrOutOfRange',
    32 => 'ACPresentButOutOfRange',
    64 => 'configurationError',
);

my %ConfigurationErrorType = (
    1 => 'vendorMismatch',
    2 => 'revisionMismatch',
    3 => 'processorMissing',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0};
    return if ($self->check_exclude('psu'));
   
    my $oid_powerSupplyStatus = '.1.3.6.1.4.1.674.10892.1.600.12.1.5';
    my $oid_powerSupplyType = '.1.3.6.1.4.1.674.10892.1.600.12.1.7';
    my $oid_powerSupplySensorState = '.1.3.6.1.4.1.674.10892.1.600.12.1.11';
    my $oid_powerSupplyConfigurationErrorType = '.1.3.6.1.4.1.674.10892.1.600.12.1.12';

    my $result = $self->{snmp}->get_table(oid => $oid_powerSupplyStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_powerSupplyType, $oid_powerSupplySensorState, $oid_powerSupplyConfigurationErrorType],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $psu_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $psu_Index;
        
        my $psu_Status = $result->{$key};
        my $psu_Type = $result2->{$oid_powerSupplyType . '.' . $instance};
        my $psu_SensorState = $result2->{$oid_powerSupplySensorState . '.' . $instance};
        my $psu_ConfigurationErrorType = $result2->{$oid_powerSupplyConfigurationErrorType . '.' . $instance};

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("psu %d status is %s, state is %s [type: %s].",
                                    $psu_Index, ${$status{$psu_Status}}[0], $state{$psu_SensorState},
                                    $type{$psu_Type}
                                    ));
        if ($psu_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$psu_Status}}[1],
                                        short_msg => sprintf("psu %d status is %s",
                                           $psu_Index, ${$status{$psu_Status}}[0]));
        }

    }
}

1;
