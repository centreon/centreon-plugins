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

package storage::ibm::fs900::snmp::mode::components::flashcard;

use strict;
use warnings;

# In MIB 'IBM-FLASHSYSTEM.MIB'
my $mapping = {
    flashObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.2' },
    flashTempGW => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.7' },
    flashTempFPGA0 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.8' },
    flashTempFPGA1 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.9' },
    flashTempFPGA2 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.10' },
    flashTempFPGA3 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.11' },
    flashPower => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.12' },
    flashOverallHealth => { oid => '.1.3.6.1.4.1.2.6.255.1.1.3.1.1.14' },
};
my $oid_flashcardTableEntry = '.1.3.6.1.4.1.2.6.255.1.1.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_flashcardTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking flashcards");
    $self->{components}->{flashcard} = {name => 'flashcards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'flashcard'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_flashcardTableEntry}})) {
        next if ($oid !~ /^$mapping->{flashObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_flashcardTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'flashcard', instance => $instance));
        
        $self->{components}->{flashcard}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Flashcard '%s' [instance = %s, overall health = %s%%, temp gateway = %sC, temp FPGA0 = %sC, temp FPGA1 = %sC, temp FPGA2 = %sC, temp FPGA3 = %sC, power = %sW]",
                                    $result->{flashObject}, $instance, $result->{flashOverallHealth}, $result->{flashTempGW} / 10, $result->{flashTempFPGA0} / 10,
                                    $result->{flashTempFPGA1} / 10, $result->{flashTempFPGA2} / 10, $result->{flashTempFPGA3} / 10, $result->{flashPower}));

        foreach my $temp ('flashTempGW', 'flashTempFPGA0', 'flashTempFPGA1', 'flashTempFPGA2', 'flashTempFPGA3') {
            if (defined($result->{$temp}) && $result->{$temp} =~ /[0-9]/) {
                my $pretty_temp = $temp;
                $pretty_temp =~ s/flashTemp//;
                my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'flashcard.temperature', instance => $instance, value => $result->{$temp} / 10);        
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Flashcard '%s' temperature '%s' is %sC", $instance, uc($pretty_temp), $result->{$temp} / 10));
                }
                $self->{output}->perfdata_add(
                    label => 'flashcard_temperature', unit => 'C',
                    nlabel => 'hardware.flashcard.temperature.celsius',
                    instances => [$instance, lc($pretty_temp)],
                    value => $result->{$temp} / 10,
                    warning => $warn,
                    critical => $crit,
                    min => 0,
               );
            }
        }

        if (defined($result->{flashPower}) && $result->{flashPower} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'flashcard.power', instance => $instance, value => $result->{flashPower});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Flashcard '%s' power is %sW", $instance, $result->{flashPower}));
            }
            $self->{output}->perfdata_add(
                label => 'flashcard_power', unit => 'W',
                nlabel => 'hardware.flashcard.power.watt',
                instances => $instance,
                value => $result->{flashPower},
                warning => $warn,
                critical => $crit,
                min => 0,
            );
        }

        if (defined($result->{flashOverallHealth}) && $result->{flashOverallHealth} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'flashcard.overallhealth', instance => $instance, value => $result->{flashOverallHealth});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Flashcard '%s' overall health is %s%%", $instance, $result->{flashOverallHealth}));
            }
            $self->{output}->perfdata_add(
                label => 'flashcard_overallhealth', unit => '%',
                nlabel => 'hardware.flashcard.overallhealth.percentage',
                instances => $instance,
                value => $result->{flashOverallHealth},
                warning => $warn,
                critical => $crit,
                min => 0, max => 100,
            );
        }
    }
}

1;
