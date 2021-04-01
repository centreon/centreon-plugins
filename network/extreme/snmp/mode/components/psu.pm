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

package network::extreme::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'notPresent', 
    2 => 'presentOK', 
    3 => 'presentNotOK', 
    4 => 'presentPowerOff'
);

my $mapping = {
    extremePowerSupplyStatus => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.2', map => \%map_psu_status },
    extremePowerSupplyFan1Speed => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.6' },
    extremePowerSupplyFan2Speed => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.7' },
    extremePowerSupplyInputPowerUsage => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.9' },
    extremePowerSupplyInputPowerUsageUnitMultiplier => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.11' },
};
my $oid_extremePowerSupplyEntry = '.1.3.6.1.4.1.1916.1.1.1.27.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_extremePowerSupplyEntry, start => $mapping->{extremePowerSupplyStatus}->{oid} };
}

sub check_fan_speed {
    my ($self, %options) = @_;
    
    if (!defined($options{value}) || $options{value} < 0) {
        return ;
    }
    
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.fan', instance => $options{instance}, value => $options{value});            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Power supply fan '%s' is '%s' rpm",
                $options{instance},
                $options{value}
            )
        );
    }
    $self->{output}->perfdata_add(
        label => 'psu_fan_' . $options{instance}, unit => 'rpm', 
        value => $options{value},
        warning => $warn,
        critical => $crit,
        min => 0
    );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_extremePowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{extremePowerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_extremePowerSupplyEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        if ($result->{extremePowerSupplyStatus} =~ /notPresent/i) {
            $self->absent_problem(section => 'psu', instance => $instance);
            next;
        }

        my $power = $result->{extremePowerSupplyInputPowerUsage} * (10 ** $result->{extremePowerSupplyInputPowerUsageUnitMultiplier});
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance = %s, fan1speed = %s, fan2speed = %s, power = %s]",
                                                        $instance, $result->{extremePowerSupplyStatus}, $instance, 
                                                        $result->{extremePowerSupplyFan1Speed}, $result->{extremePowerSupplyFan2Speed}, $power
                                                        ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{extremePowerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $result->{extremePowerSupplyStatus}));
        }
        
        check_fan_speed($self, value => $result->{extremePowerSupplyFan1Speed}, instance => $instance . '.1');
        check_fan_speed($self, value => $result->{extremePowerSupplyFan2Speed}, instance => $instance . '.2');
        
        if ($power != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => 'psu', value => $power);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' power is '%s' W", $instance, $power));
            }
            $self->{output}->perfdata_add(
                label => 'psu_power', unit => 'W',
                nlabel => 'hardware.powersupply.power.watt',
                instances => $instance,
                value => $power,
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
