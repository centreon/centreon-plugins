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

package network::alcatel::isam::snmp::mode::components::cardtemperature;

use strict;
use warnings;
use network::alcatel::isam::snmp::mode::components::resources qw($mapping_slot);

my $oid_eqptBoardThermalSensorActualTemperature = '.1.3.6.1.4.1.637.61.1.23.10.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqptBoardThermalSensorActualTemperature };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking card temperatures");
    $self->{components}->{cardtemperature} = {name => 'card temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cardtemperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqptBoardThermalSensorActualTemperature}})) {
        $oid =~ /^$oid_eqptBoardThermalSensorActualTemperature\.(.*?)\.(.*?)$/;
        my ($slot_id, $thermal_id) = ($1, $2);
        
        my $temperature = $self->{results}->{$oid_eqptBoardThermalSensorActualTemperature}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping_slot, results => 
            { %{$self->{results}->{$mapping_slot->{eqptSlotActualType}->{oid}}}, %{$self->{results}->{$mapping_slot->{eqptBoardInventorySerialNumber}->{oid}}} }, instance => $slot_id);
        
        next if ($self->check_filter(section => 'cardtemperature', instance => $slot_id . '.' . $thermal_id));

        my $name = $result->{eqptSlotActualType} . '/' . $result->{eqptBoardInventorySerialNumber} . '/' . $thermal_id;
        $self->{components}->{cardtemperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("card '%s' temperature is %s C [instance = %s]",
                                                        $name, $temperature, $slot_id . '.' . $thermal_id));
        
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'cardtemperature', instance => $slot_id . '.' . $thermal_id, value => $temperature);            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Card '%s' temperature is %s C", $name, $temperature));
        }
        $self->{output}->perfdata_add(
            label => 'cardtemperature', unit => 'C',
            nlabel => 'hardware.card.temperature.celsius',
            instances => $name,
            value => $temperature,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
