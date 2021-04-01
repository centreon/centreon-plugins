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

package network::sophos::es::snmp::mode::components::component;

use strict;
use warnings;

my %map_status = (0 => 'unknown', 1 => 'disabled', 2 => 'ok', 3 => 'warn', 4 => 'error');

my $mapping = {
    sophosHwMemoryConsumption   => { oid => '.1.3.6.1.4.1.2604.3.4', map => \%map_status, type => 'MemoryConsumption' },
    sophosHwMemoryStatus        => { oid => '.1.3.6.1.4.1.2604.3.5', map => \%map_status, type => 'Memory' },
    sophosHwRaid                => { oid => '.1.3.6.1.4.1.2604.3.6', map => \%map_status, type => 'Raid' },
    sophosHwCpuStatus           => { oid => '.1.3.6.1.4.1.2604.3.7', map => \%map_status, type => 'Cpu' },
    sophosHwPowerSupplyLeft     => { oid => '.1.3.6.1.4.1.2604.3.8', map => \%map_status, type => 'PowerSupplyLeft' },
    sophosHwPowerSupplyRight    => { oid => '.1.3.6.1.4.1.2604.3.9', map => \%map_status, type => 'PowerSupplyRight' },
    sophosHwPowerSupplyFanLeft  => { oid => '.1.3.6.1.4.1.2604.3.10', map => \%map_status, type => 'PowerSupplyFanLeft' },
    sophosHwPowerSupplyFanRight => { oid => '.1.3.6.1.4.1.2604.3.11', map => \%map_status, type => 'PowerSupplyFanRight' },
    sophosHwSystemFan           => { oid => '.1.3.6.1.4.1.2604.3.12', map => \%map_status, type => 'SystemFan' },
    sophosHwTemperature         => { oid => '.1.3.6.1.4.1.2604.3.13', map => \%map_status, type => 'Temperature' },
    sophosHwVoltage             => { oid => '.1.3.6.1.4.1.2604.3.14', map => \%map_status, type => 'Voltage' },
    sophosHwPowerSupplies       => { oid => '.1.3.6.1.4.1.2604.3.16', map => \%map_status, type => 'PowerSupplies' },
};
my $oid_sophosHardware = '.1.3.6.1.4.1.2604.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sophosHardware };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking components");
    $self->{components}->{component} = {name => 'components', total => 0, skip => 0};
    return if ($self->check_filter(section => 'component'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sophosHardware});
    if (scalar(keys %$result) == 0) {
        $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sophosHardware}, instance => '0');
        return  (scalar(keys %$result) == 0);
    }
    
    foreach (keys %{$mapping}) {
        next if ($self->check_filter(section => 'component', instance => $mapping->{$_}->{type}));
        
        $self->{components}->{component}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("component '%s' status is '%s' [instance: %s].",
                                    $mapping->{$_}->{type}, $result->{$_},
                                    $mapping->{$_}->{type}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'component', instance => $mapping->{$_}->{type}, value => $result->{$_});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("component '%s' status is '%s'",
                                                             $mapping->{$_}->{type}, $result->{$_}));
        }
    }
}

1;