################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_ciscoEnvMonSupplyStatusEntry };
    push @{$options{request}}, { oid => $oid_cefcFRUPowerOperStatus };
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

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($result->{ciscoEnvMonSupplyState} =~ /not present/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s] [source: %s]",
                                    $result->{ciscoEnvMonSupplyStatusDescr}, $result->{ciscoEnvMonSupplyState},
                                    $instance, $result->{ciscoEnvMonSupplySource}
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{ciscoEnvMonSupplyState});
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
        
        next if ($self->check_exclude(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s]",
                                    $psu_descr, $result->{cefcFRUPowerOperStatus}, $instance));
        my $exit = $self->get_severity(section => 'psu', value => $result->{cefcFRUPowerOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s.", $psu_descr, $result->{cefcFRUPowerOperStatus}));
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    check_psu_envmon($self);
    check_psu_entity($self);
}

1;