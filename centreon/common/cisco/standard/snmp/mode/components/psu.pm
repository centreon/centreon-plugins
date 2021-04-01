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

package centreon::common::cisco::standard::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_source = (
    1 => 'unknown',
    2 => 'ac',
    3 => 'dc',
    4 => 'externalPowerSupply',
    5 => 'internalRedundant'
);
my %map_psu_state1 = (
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical', 
    4 => 'shutdown',
    5 => 'not present',
    6 => 'not functioning',
);
my %map_psu_state2 = (
    1 => 'offEnvOther',
    2 => 'on',
    3 => 'offAdmin',
    4 => 'offDenied',
    5 => 'offEnvPower',
    6 => 'offEnvTemp',
    7 => 'offEnvFan',
    8 => 'failed',
    9 => 'onButFanFail',
    10 => 'offCooling',
    11 => 'offConnectorRating',
    12 => 'onButInlinePowerFail',
);

my $oid_ciscoEnvMonSupplyStatusEntry = '.1.3.6.1.4.1.9.9.13.1.5.1'; # CISCO-ENVMON-MIB
my $oid_cefcFRUPowerOperStatus = '.1.3.6.1.4.1.9.9.117.1.1.2.1.2'; # CISCO-ENTITY-SENSOR-MIB
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_ciscoEnvMonSupplyStatusEntry }, { oid => $oid_cefcFRUPowerOperStatus };
}

sub check_psu_envmon {
    my ($self) = @_;

    my $mapping = {
        ciscoEnvMonSupplyStatusDescr => { oid => '.1.3.6.1.4.1.9.9.13.1.5.1.2' },
        ciscoEnvMonSupplyState => { oid => '.1.3.6.1.4.1.9.9.13.1.5.1.3', map => \%map_psu_state1 },
        ciscoEnvMonSupplySource => { oid => '.1.3.6.1.4.1.9.9.13.1.5.1.4', map => \%map_psu_source },
    };
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ciscoEnvMonSupplyStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ciscoEnvMonSupplyStatusDescr}->{oid}\./);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ciscoEnvMonSupplyStatusEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance, name => $result->{ciscoEnvMonSupplyStatusDescr}));
        next if ($result->{ciscoEnvMonSupplyState} =~ /not present/i && 
                 $self->absent_problem(section => 'psu', instance => $instance, name => $result->{ciscoEnvMonSupplyStatusDescr}));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s] [source: %s]",
                                    $result->{ciscoEnvMonSupplyStatusDescr}, $result->{ciscoEnvMonSupplyState},
                                    $instance, $result->{ciscoEnvMonSupplySource}
                                    ));
        my $exit = $self->get_severity(section => 'psu', instance => $instance, value => $result->{ciscoEnvMonSupplyState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s",
                                                             $result->{ciscoEnvMonSupplyStatusDescr}, $result->{ciscoEnvMonSupplyState}));
        }
    }
}

sub check_psu_entity {
    my ($self) = @_;
    
    my $mapping = {
        cefcFRUPowerOperStatus => { oid => '.1.3.6.1.4.1.9.9.117.1.1.2.1.2', map => \%map_psu_state2 },
    };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcFRUPowerOperStatus}})) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        
        my $psu_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cefcFRUPowerOperStatus}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance, name => $psu_descr));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s]",
                                    $psu_descr, $result->{cefcFRUPowerOperStatus}, $instance));
        my $exit = $self->get_severity(section => 'psu', instance => $instance, value => $result->{cefcFRUPowerOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s/%s' status is %s", $psu_descr, $instance, $result->{cefcFRUPowerOperStatus}));
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    check_psu_envmon($self);
    check_psu_entity($self);
}

1;
