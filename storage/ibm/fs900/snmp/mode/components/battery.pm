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

package storage::ibm::fs900::snmp::mode::components::battery;

use strict;
use warnings;

# In MIB 'IBM-FLASHSYSTEM.MIB'
my $mapping = {
    batteryObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.2' },
    batteryCell1 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.4' }, #mV
    batteryCell2 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.5' }, #mV
    batteryCell3 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.6' }, #mV
    batteryTotal => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.7' }, #mV
    batteryChgCurr => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.8' },
    batteryRmngCap => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.9' },
    batteryFullCap => { oid => '.1.3.6.1.4.1.2.6.255.1.1.4.10.1.10' },
};
my $oid_batteryTableEntry = '.1.3.6.1.4.1.2.6.255.1.1.4.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_batteryTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking batteries");
    $self->{components}->{battery} = {name => 'batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'battery'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_batteryTableEntry}})) {
        next if ($oid !~ /^$mapping->{batteryObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_batteryTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'battery', instance => $instance));
        
        $self->{components}->{battery}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Battery '%s' [instance = %s, cell1 = %s mV, cell2 = %s mV, cell3 = %s mV, total = %s mV, current = %s, capacity remaining = %s, capacity full = %s]",
                                    $result->{batteryObject}, $instance, $result->{batteryCell1}, $result->{batteryCell2}, $result->{batteryCell3},
                                    $result->{batteryTotal}, $result->{batteryChgCurr}, $result->{batteryRmngCap}, $result->{batteryFullCap}));

        foreach my $cell ('batteryCell1', 'batteryCell2', 'batteryCell3', 'batteryTotal') {
            if (defined($result->{$cell}) && $result->{$cell} =~ /[0-9]/) {
                my $pretty_cell = $cell;
                $pretty_cell =~ s/battery//;
                my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'battery.cell', instance => $instance, value => $result->{$cell});        
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Battery '%s' cell '%s' voltage is %s mV", $instance, lc($pretty_cell), $result->{$cell}));
                }
                $self->{output}->perfdata_add(
                    label => 'battery_voltage', unit => 'mV',
                    nlabel => 'hardware.battery.voltage.millivolt',
                    instances => [$instance, lc($pretty_cell)],
                    value => $result->{$cell},
                    warning => $warn,
                    critical => $crit,
                    min => 0,
                );
            }
        }

        if (defined($result->{batteryChgCurr}) && $result->{batteryChgCurr} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'battery.current', instance => $instance, value => $result->{batteryChgCurr});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Battery '%s' current is %s", $instance, $result->{batteryChgCurr}));
            }
            $self->{output}->perfdata_add(
                label => 'battery_current',
                nlabel => 'hardware.battery.current.count',
                instances => $instance,
                value => $result->{batteryChgCurr},
                warning => $warn,
                critical => $crit,
                min => 0,
            );
        }

        if (defined($result->{batteryRmngCap}) && $result->{batteryRmngCap} =~ /[0-9]/ && defined($result->{batteryFullCap}) && $result->{batteryFullCap} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'battery.capacity', instance => $instance, value => $result->{batteryRmngCap});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Battery '%s' capacity is %s on %s", $instance, $result->{batteryRmngCap}, $result->{batteryFullCap}));
            }
            $self->{output}->perfdata_add(
                label => 'battery_capacity',
                nlabel => 'hardware.battery.capacity.count',
                instances => $instance,
                value => $result->{batteryRmngCap},
                warning => $warn,
                critical => $crit,
                min => 0, max => $result->{batteryFullCap},
            );
        }
    }
}

1;
