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

package hardware::server::hp::proliant::snmp::mode::components::fan;

use strict;
use warnings;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);

my %redundant_map = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);

my %location_map = (
    1 => "other",
    2 => "unknown",
    3 => "system",
    4 => "systemBoard",
    5 => "ioBoard",
    6 => "cpu",
    7 => "memory",
    8 => "storage",
    9 => "removableMedia",
    10 => "powerSupply", 
    11 => "ambient",
    12 => "chassis",
    13 => "bridgeCard",
    14 => "managementBoard",
    15 => "backplane",
    16 => "networkSlot",
    17 => "bladeSlot",
    18 => "virtual",
);

my %fanspeed = (
    1 => "other",
    2 => "normal",
    3 => "high",
);

sub check {
    my ($self) = @_;

    # In MIB 'CPQHLTH-MIB.mib'
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    my $oid_cpqHeFltTolFanPresent = '.1.3.6.1.4.1.232.6.2.6.7.1.4';
    my $oid_cpqHeFltTolFanChassis = '.1.3.6.1.4.1.232.6.2.6.7.1.1';
    my $oid_cpqHeFltTolFanIndex = '.1.3.6.1.4.1.232.6.2.6.7.1.2';
    my $oid_cpqHeFltTolFanLocale = '.1.3.6.1.4.1.232.6.2.6.7.1.3';
    my $oid_cpqHeFltTolFanCondition = '.1.3.6.1.4.1.232.6.2.6.7.1.9';
    my $oid_cpqHeFltTolFanSpeed = '.1.3.6.1.4.1.232.6.2.6.7.1.6';
    my $oid_cpqHeFltTolFanCurrentSpeed = '.1.3.6.1.4.1.232.6.2.6.7.1.12';
    my $oid_cpqHeFltTolFanRedundant = '.1.3.6.1.4.1.232.6.2.6.7.1.7';
    my $oid_cpqHeFltTolFanRedundantPartner = '.1.3.6.1.4.1.232.6.2.6.7.1.8';

    my $result = $self->{snmp}->get_table(oid => $oid_cpqHeFltTolFanPresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        # Chassis + index
        $key =~ /(\d+)\.(\d+)$/;
        my $oid_end = $1 . '.' . $2;
        
        next if ($present_map{$result->{$key}} ne 'present' && 
                 $self->absent_problem(section => 'fan', instance => $1 . '.' . $2));
        
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqHeFltTolFanLocale . "." . $oid_end, $oid_cpqHeFltTolFanCondition . "." . $oid_end,
                $oid_cpqHeFltTolFanCurrentSpeed . "." . $oid_end, $oid_cpqHeFltTolFanSpeed . "." . $oid_end, 
                $oid_cpqHeFltTolFanRedundant . "." . $oid_end, $oid_cpqHeFltTolFanRedundantPartner . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my ($fan_chassis, $fan_index) = split /\./;
        my $fan_locale = $result->{$oid_cpqHeFltTolFanLocale . '.' . $_};
        my $fan_condition = $result->{$oid_cpqHeFltTolFanCondition . '.' . $_};
        my $fan_speed = $result->{$oid_cpqHeFltTolFanSpeed . '.' . $_};
        my $fan_currentspeed = $result->{$oid_cpqHeFltTolFanCurrentSpeed . '.' . $_};
        my $fan_redundant = $result->{$oid_cpqHeFltTolFanRedundant . '.' . $_};
        my $fan_redundantpartner = $result->{$oid_cpqHeFltTolFanRedundantPartner . '.' . $_};

        next if ($self->check_exclude(section => 'fan', instance => $fan_chassis . '.' . $fan_index));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan %d status is %s, speed is %s [chassis: %s, location: %s, redundance: %s, redundant partner: %s].",
                                    $fan_index, ${$conditions{$fan_condition}}[0], $fanspeed{$fan_speed},
                                    $fan_chassis, $location_map{$fan_locale},
                                    $redundant_map{$fan_redundant}, $fan_redundantpartner
                                    ));
        if ($fan_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$fan_condition}}[1],
                                        short_msg => sprintf("fan %d status is %s",
                                           $fan_index, ${$conditions{$fan_condition}}[0]));
        }

        if (defined($fan_currentspeed)) {
            $self->{output}->perfdata_add(label => "fan_" . $fan_index . "_speed", unit => 'rpm',
                                          value => $fan_currentspeed);
        }
    }
}

1;