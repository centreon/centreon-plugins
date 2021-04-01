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

package network::alcatel::isam::snmp::mode::components::sfp;

use strict;
use warnings;
use network::alcatel::isam::snmp::mode::components::resources qw($mapping_slot);

my %map_los = (1 => 'los', 2 => 'noLos', 3 => 'notAvailable');

my $mapping = {
    sfpDiagLOS              => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.4', map => \%map_los },
    sfpDiagTxPower          => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.6' },
    sfpDiagRxPower          => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.7' },
    sfpDiagTxBiasCurrent    => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.8' },
    sfpDiagSupplyVoltage    => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.9' },
    sfpDiagTemperature      => { oid => '.1.3.6.1.4.1.637.61.1.56.5.1.10' },
};
my $oid_sfpDiagEntry = '.1.3.6.1.4.1.637.61.1.56.5.1';

sub load {
    my ($self) = @_;
    
    foreach (keys %$mapping) {
        push @{$self->{request}}, { oid => $mapping->{$_}->{oid} };
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sfp");
    $self->{components}->{sfp} = {name => 'sfp', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sfp'));

    my $results = {};
    foreach (keys %$mapping) {
        $results = { %$results, %{$self->{results}->{$mapping->{$_}->{oid}}} };
    }
    
    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{sfpDiagLOS}->{oid}}})) {
        $oid =~ /^$mapping->{sfpDiagLOS}->{oid}\.(.*?)\.(.*?)$/;
        my ($slot_id, $sfp_faceplate_num) = ($1, $2);
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping_slot, results => 
            { %{$self->{results}->{$mapping_slot->{eqptSlotActualType}->{oid}}}, %{$self->{results}->{$mapping_slot->{eqptBoardInventorySerialNumber}->{oid}}} }, instance => $slot_id);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $slot_id . '.' . $sfp_faceplate_num);
        
        next if ($self->check_filter(section => 'sfp', instance => $slot_id . '.' . $sfp_faceplate_num));

        my $name = $result->{eqptSlotActualType} . '/' . $result->{eqptBoardInventorySerialNumber} . '/' . $sfp_faceplate_num;
        $self->{components}->{sfp}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sfp '%s' signal status is '%s' [instance = %s]",
                                                        $name, $result2->{sfpDiagLOS}, $slot_id . '.' . $sfp_faceplate_num));
        $exit = $self->get_severity(section => 'sfp', instance => $slot_id . '.' . $sfp_faceplate_num, value => $result2->{sfpDiagLOS});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sfp '%s' signal status is '%s'", $name, $result2->{sfpDiagLOS}));
        }
        
        if ($result2->{sfpDiagSupplyVoltage} =~ /(\S+)\s+VDC/i) {
            my $value = $1;
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sfp.voltage', instance => $slot_id . '.' . $sfp_faceplate_num, value => $value);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sfp '%s' voltage is %s VDC", $name, $value));
            }
            $self->{output}->perfdata_add(
                label => 'sfp_voltage', unit => 'vdc',
                nlabel => 'hardware.sfp.voltage.voltdc',
                instances => $name,
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
        
        if ($result2->{sfpDiagTemperature} =~ /(\S+)\s+degrees Celsius/i) {
            my $value = $1;
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sfp.temperature', instance => $slot_id . '.' . $sfp_faceplate_num, value => $value);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sfp '%s' temperature is %s C", $name, $value));
            }
            $self->{output}->perfdata_add(
                label => 'sfp_temperature',  unit => 'C',
                nlabel => 'hardware.sfp.temperature.celsius',
                instances => $name, 
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
        
        if ($result2->{sfpDiagTxPower} =~ /(\S+)\s+dBm/i) {
            my $value = $1;
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sfp.txpower', instance => $slot_id . '.' . $sfp_faceplate_num, value => $value);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sfp '%s' tx power is %s dBm", $name, $value));
            }
            $self->{output}->perfdata_add(
                label => 'sfp_txpower', unit => 'dBm',
                nlabel => 'hardware.sfp.txpower.dbm',
                instances => $name,
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
        
        if ($result2->{sfpDiagRxPower} =~ /(\S+)\s+dBm/i) {
            my $value = $1;
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sfp.rxpower', instance => $slot_id . '.' . $sfp_faceplate_num, value => $value);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sfp '%s' rx power is %s dBm", $name, $value));
            }
            $self->{output}->perfdata_add(
                label => 'sfp_rxpower', unit => 'dBm',
                nlabel => 'hardware.sfp.rxpower.dbm',
                instances => $name,
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
        
        if ($result2->{sfpDiagTxBiasCurrent} =~ /(\S+)\s+mA/i) {
            my $value = $1;
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sfp.current', instance => $slot_id . '.' . $sfp_faceplate_num, value => $value);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sfp '%s' current is %s mA", $name, $value));
            }
            $self->{output}->perfdata_add(
                label => 'sfp_current', unit => 'mA',
                nlabel => 'hardware.sfp.current.milliampere',
                instances => $name,
                value => $value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
