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

package centreon::common::cisco::standard::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_state1 = (
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical', 
    4 => 'shutdown',
    5 => 'not present',
    6 => 'not functioning',
);
my %map_fan_state2 = (
    1 => 'unknown',
    2 => 'up',
    3 => 'down',
    4 => 'warning',
);

my $oid_ciscoEnvMonFanStatusEntry = '.1.3.6.1.4.1.9.9.13.1.4.1'; # CISCO-ENVMON-MIB
my $oid_cefcFanTrayOperStatus = '.1.3.6.1.4.1.9.9.117.1.4.1.1.1'; # CISCO-ENTITY-SENSOR-MIB
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_ciscoEnvMonFanStatusEntry }, { oid => $oid_cefcFanTrayOperStatus };
}

sub check_fan_envmon {
    my ($self) = @_;

    my $mapping = {
        ciscoEnvMonFanStatusDescr => { oid => '.1.3.6.1.4.1.9.9.13.1.4.1.2' },
        ciscoEnvMonFanState => { oid => '.1.3.6.1.4.1.9.9.13.1.4.1.3', map => \%map_fan_state1 },
    };
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ciscoEnvMonFanStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ciscoEnvMonFanStatusDescr}->{oid}\./);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ciscoEnvMonFanStatusEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance, name => $result->{ciscoEnvMonFanStatusDescr}));
        next if ($result->{ciscoEnvMonFanState} =~ /not present/i && 
                 $self->absent_problem(section => 'fan', instance => $instance, name => $result->{ciscoEnvMonFanStatusDescr}));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s].",
                $result->{ciscoEnvMonFanStatusDescr}, $result->{ciscoEnvMonFanState},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{ciscoEnvMonFanState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("fan '%s' status is %s",
                                                             $result->{ciscoEnvMonFanStatusDescr}, $result->{ciscoEnvMonFanState}));
        }
    }
}

sub check_fan_entity {
    my ($self) = @_;
    
    my $mapping = {
        cefcFanTrayOperStatus => { oid => '.1.3.6.1.4.1.9.9.117.1.4.1.1.1', map => \%map_fan_state2 },
    };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcFanTrayOperStatus}})) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        
        my $fan_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cefcFanTrayOperStatus}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance, name => $fan_descr));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "Fan '%s' status is %s [instance: %s]",
                $fan_descr, $result->{cefcFanTrayOperStatus}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{cefcFanTrayOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s/%s' status is %s", $fan_descr, $instance, $result->{cefcFanTrayOperStatus}));
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    check_fan_envmon($self);
    check_fan_entity($self);
}

1;
