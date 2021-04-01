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

package hardware::server::dell::openmanage::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);
my %map_type = (
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
my %map_state = (
    1 => 'present',
    2 => 'failure',
    4 => 'predictiveFailure',
    8 => 'ACLost',
    16 => 'ACLostOrOutOfRange',
    32 => 'ACPresentButOutOfRange',
    64 => 'configurationError',
);
my %map_ConfigurationErrorType = (
    1 => 'vendorMismatch',
    2 => 'revisionMismatch',
    3 => 'processorMissing',
);

# In MIB '10892.mib'
my $mapping = {
    powerSupplyStatus => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.5', map => \%map_status },
    powerSupplyOutputWatts => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.6' },
    powerSupplyType => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.7', map => \%map_type },
    powerSupplyLocationName => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.8' },
};
my $mapping2 = {
    powerSupplySensorState => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.11', map => \%map_state },
    powerSupplyConfigurationErrorType => { oid => '.1.3.6.1.4.1.674.10892.1.600.12.1.12', map => \%map_ConfigurationErrorType },
};
my $oid_powerSupplyTable = '.1.3.6.1.4.1.674.10892.1.600.12';
my $oid_powerSupplyTableEntry = '.1.3.6.1.4.1.674.10892.1.600.12.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_powerSupplyTable, start => $mapping->{powerSupplyStatus}->{oid}, end => $mapping->{powerSupplyLocationName}->{oid} },
        { oid => $oid_powerSupplyTableEntry, start => $mapping2->{powerSupplySensorState}->{oid}, end => $mapping2->{powerSupplyConfigurationErrorType}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerSupplyTable}})) {
        next if ($oid !~ /^$mapping->{powerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerSupplyTable}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_powerSupplyTableEntry}, instance => $instance);
        $result2->{powerSupplyConfigurationErrorType} = defined($result2->{powerSupplyConfigurationErrorType}) ? $result2->{powerSupplyConfigurationErrorType} : '-';
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance: %s, location: %s, type: %s, output watts: %s, state: %s, configuration error: %s]",
                                    $instance, $result->{powerSupplyStatus}, $instance, 
                                    $result->{powerSupplyLocationName}, $result->{powerSupplyType}, 
                                    defined($result->{powerSupplyOutputWatts}) ? $result->{powerSupplyOutputWatts} : '-',
                                    $result2->{powerSupplySensorState}, $result2->{powerSupplyConfigurationErrorType}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{powerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'",
                                           $instance, $result->{powerSupplyStatus}));
        }
        
        if (defined($result->{powerSupplyOutputWatts}) && $result->{powerSupplyOutputWatts} =~ /[0-9]/) {
            $result->{powerSupplyOutputWatts} /= 10;
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.power', instance => $instance, value => $result->{powerSupplyOutputWatts});
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' power is %s W", $instance, $result->{powerSupplyOutputWatts}));
            }
            $self->{output}->perfdata_add(
                label => 'psu_power', unit => 'W',
                nlabel => 'hardware.powersupply.power.watt',
                instances => $instance,
                value => $result->{powerSupplyOutputWatts},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
