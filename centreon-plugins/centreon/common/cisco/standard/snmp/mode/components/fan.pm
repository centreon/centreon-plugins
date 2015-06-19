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
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_ciscoEnvMonFanStatusEntry };
    push @{$options{request}}, { oid => $oid_cefcFanTrayOperStatus };
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

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        next if ($result->{ciscoEnvMonFanState} =~ /not present/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s [instance: %s].",
                                    $result->{ciscoEnvMonFanStatusDescr}, $result->{ciscoEnvMonFanState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'fan', value => $result->{ciscoEnvMonFanState});
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
        
        next if ($self->check_exclude(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is %s [instance: %s]",
                                    $fan_descr, $result->{cefcFanTrayOperStatus}, $instance));
        my $exit = $self->get_severity(section => 'fan', value => $result->{cefcFanTrayOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is %s.", $fan_descr, $result->{cefcFanTrayOperStatus}));
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    check_fan_envmon($self);
    check_fan_entity($self);
}

1;