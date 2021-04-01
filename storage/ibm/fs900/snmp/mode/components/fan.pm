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

package storage::ibm::fs900::snmp::mode::components::fan;

use strict;
use warnings;

# In MIB 'IBM-FLASHSYSTEM.MIB'
my $mapping = {
    fanObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.2' },
    fanPWM => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.4' },
    fanTemp => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.5' },
    fan0 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.6' },
    fan1 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.7' },
    fan2 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.8' },
    fan3 => { oid => '.1.3.6.1.4.1.2.6.255.1.1.6.10.1.9' },
};
my $oid_fanTableEntry = '.1.3.6.1.4.1.2.6.255.1.1.6.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fanTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fan modules");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanTableEntry}})) {
        next if ($oid !~ /^$mapping->{fanObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan module '%s' [instance = %s, PWM = %s%%, temperature = %sC, fan0 speed = %s%%, fan1 speed = %s%%, fan2 speed = %s%%, fan3 speed = %s%%]",
                                    $result->{fanObject}, $instance, $result->{fanPWM}, $result->{fanTemp} / 10, $result->{fan0}, $result->{fan1}, $result->{fan2}, $result->{fan3}));

        
        if (defined($result->{fanPWM}) && $result->{fanPWM} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan.pwm', instance => $instance, value => $result->{fanPWM});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan module '%s' PWM is %s%", $instance, $result->{fanPWM}));
            }
            $self->{output}->perfdata_add(
                label => 'fan_pwm', unit => '%',
                nlabel => 'hardware.fan.pwm.percentage',
                instances => $instance,
                value => $result->{fanPWM},
                warning => $warn,
                critical => $crit,
                min => 0, max => 100,
            );
        }

        if (defined($result->{fanTemp}) && $result->{fanTemp} =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan.temperature', instance => $instance, value => $result->{fanTemp} / 10);        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan module '%s' temperature is %s degree centigrade", $instance, $result->{fanTemp} / 10));
            }
            $self->{output}->perfdata_add(
                label => 'fan_temp', unit => 'C',
                nlabel => 'hardware.fan.temperature.celsius',
                instances => $instance,
                value => $result->{fanTemp} / 10,
                warning => $warn,
                critical => $crit,
                min => 0,
            );
        }

        foreach my $fan ('fan0', 'fan1', 'fan2', 'fan3') {
            if (defined($result->{$fan}) && $result->{$fan} =~ /[0-9]/) {
                my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $result->{$fan});        
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Fan module '%s' fan '%s' speed is %s%%", $instance, $fan, $result->{$fan}));
                }
                $self->{output}->perfdata_add(
                    label => 'fan_speed', unit => '%',
                    nlabel => 'hardware.fan.speed.percentage',
                    instances => [$instance, $fan],
                    value => $result->{$fan},
                    warning => $warn,
                    critical => $crit,
                    min => 0, max => 100,
                );
            }
        }
    }
}

1;
