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

package storage::ibm::fs900::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_state = (
    0 => 'success',
    1 => 'error',
);

# In MIB 'IBM-FLASHSYSTEM.MIB'
my $mapping = {
    psuObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.5.10.1.2' },
    psuCommErr => { oid => '.1.3.6.1.4.1.2.6.255.1.1.5.10.1.3', map => \%map_psu_state },
    psuACGood => { oid => '.1.3.6.1.4.1.2.6.255.1.1.5.10.1.4', map => \%map_psu_state },
    psuDCGood => { oid => '.1.3.6.1.4.1.2.6.255.1.1.5.10.1.5', map => \%map_psu_state },
    psuFan => { oid => '.1.3.6.1.4.1.2.6.255.1.1.5.10.1.6' },
};
my $oid_powerTableEntry = '.1.3.6.1.4.1.2.6.255.1.1.5.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_powerTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking psu");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerTableEntry}})) {
        next if ($oid !~ /^$mapping->{psuObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Psu '%s' [instance = %s, communications = %s, AC = %s, DC = %s, fan = %s rpm]",
                                    $result->{psuObject}, $instance, $result->{psuCommErr}, $result->{psuACGood}, $result->{psuDCGood}, $result->{psuFan}));
        
        my $exit = $self->get_severity(section => 'psu', value => $result->{psuCommErr});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Psu '%s' communications state is %s", 
                                            $instance, $result->{psuCommErr}));
        }

        $exit = $self->get_severity(section => 'psu', value => $result->{psuACGood});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Psu '%s' AC state is %s", 
                                            $instance, $result->{psuACGood}));
        }

        $exit = $self->get_severity(section => 'psu', value => $result->{psuDCGood});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Psu '%s' DC state is %s", 
                                            $instance, $result->{psuDCGood}));
        }

        if (defined($result->{psuFan}) && $result->{psuFan} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'psu.fan', instance => $instance, value => $result->{psuFan});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Psu '%s' fan speed is %s rpm", $instance, $result->{psuFan}));
            }
            $self->{output}->perfdata_add(
                label => 'psu_fan', unit => 'rpm',
                nlabel => 'hardware.psu.fan.speed.rpm',
                instances => $instance,
                value => $result->{psuFan},
                warning => $warn,
                critical => $crit,
                min => 0,
            );
        }
    }
}

1;
