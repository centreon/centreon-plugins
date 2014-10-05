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

package hardware::server::hp::proliant::snmp::mode::components::psu;

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

my %psustatus = (
    1  => 'noError',
    2  => 'generalFailure',
    3  => 'bistFailure',
    4  => 'fanFailure',
    5  => 'tempFailure',
    6  => 'interlockOpen',
    7  => 'epromFailed',
    8  => 'vrefFailed',
    9  => 'dacFailed',
    10 => 'ramTestFailed',
    11 => 'voltageChannelFailed',
    12 => 'orringdiodeFailed',
    13 => 'brownOut',
    14 => 'giveupOnStartup',
    15 => 'nvramInvalid',
    16 => 'calibrationTableInvalid',
);

sub check {
    my ($self) = @_;

    # In MIB 'CPQHLTH-MIB.mib'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    
    my $oid_cpqHeFltTolPowerSupplyPresent = '.1.3.6.1.4.1.232.6.2.9.3.1.3';
    my $oid_cpqHeFltTolPowerSupplyChassis = '.1.3.6.1.4.1.232.6.2.9.3.1.1';
    my $oid_cpqHeFltTolPowerSupplyBay = '.1.3.6.1.4.1.232.6.2.9.3.1.2';
    my $oid_cpqHeFltTolPowerSupplyCondition = '.1.3.6.1.4.1.232.6.2.9.3.1.4';
    my $oid_cpqHeFltTolPowerSupplyStatus = '.1.3.6.1.4.1.232.6.2.9.3.1.5';
    my $oid_cpqHeFltTolPowerSupplyRedundant = '.1.3.6.1.4.1.232.6.2.9.3.1.9';
    my $oid_cpqHeFltTolPowerSupplyCapacityUsed = '.1.3.6.1.4.1.232.6.2.9.3.1.7'; # Watts
    my $oid_cpqHeFltTolPowerSupplyCapacityMaximum = '.1.3.6.1.4.1.232.6.2.9.3.1.8';
    my $oid_cpqHeFltTolPowerSupplyMainVoltage = '.1.3.6.1.4.1.232.6.2.9.3.1.6'; # Volts
    my $oid_cpqHeFltTolPowerSupplyRedundantPartner = '.1.3.6.1.4.1.232.6.2.9.3.1.17';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqHeFltTolPowerSupplyPresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        # Chassis + Bay
        $key =~ /(\d+)\.(\d+)$/;
        my $oid_end = $1 . '.' . $2;
        
        next if ($present_map{$result->{$key}} ne 'present' &&
                 $self->absent_problem(section => 'psu', instance => $1 . '.' . $2));
        
        push @oids_end, $oid_end;
        push @get_oids,
                $oid_cpqHeFltTolPowerSupplyCondition . "." . $oid_end, $oid_cpqHeFltTolPowerSupplyStatus . "." . $oid_end,
                $oid_cpqHeFltTolPowerSupplyRedundant . "." . $oid_end, $oid_cpqHeFltTolPowerSupplyCapacityUsed . "." . $oid_end,
                $oid_cpqHeFltTolPowerSupplyCapacityMaximum . "." . $oid_end, $oid_cpqHeFltTolPowerSupplyMainVoltage . "." . $oid_end,
                $oid_cpqHeFltTolPowerSupplyRedundantPartner . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my ($psu_chassis, $psu_bay) = split /\./;
        my $psu_condition = $result->{$oid_cpqHeFltTolPowerSupplyCondition . '.' . $_};
        my $psu_status = $result->{$oid_cpqHeFltTolPowerSupplyStatus . '.' . $_};
        my $psu_redundant = $result->{$oid_cpqHeFltTolPowerSupplyRedundant . '.' . $_};
        my $psu_redundantpartner = defined($result->{$oid_cpqHeFltTolPowerSupplyRedundantPartner . '.' . $_}) ? $result->{$oid_cpqHeFltTolPowerSupplyRedundantPartner . '.' . $_} : 'undefined';
        my $psu_capacityused = $result->{$oid_cpqHeFltTolPowerSupplyCapacityUsed . '.' . $_};
        my $psu_capacitymaximum = $result->{$oid_cpqHeFltTolPowerSupplyCapacityMaximum . '.' . $_};
        my $psu_voltage = $result->{$oid_cpqHeFltTolPowerSupplyMainVoltage . '.' . $_};

        next if ($self->check_exclude(section => 'psu', instance => $psu_chassis . '.' . $psu_bay));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("powersupply %d status is %s [chassis: %s, redundance: %s, redundant partner: %s] (status %s).",
                                    $psu_bay, ${$conditions{$psu_condition}}[0],
                                    $psu_chassis, $redundant_map{$psu_redundant}, $psu_redundantpartner,
                                    $psustatus{$psu_status}
                                    ));
        if ($psu_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$psu_condition}}[1],
                                        short_msg => sprintf("powersupply %d status is %s",
                                           $psu_bay, ${$conditions{$psu_condition}}[0]));
        }
        
        $self->{output}->perfdata_add(label => "psu_" . $psu_bay . "_power", unit => 'W',
                                      value => $psu_capacityused,
                                      critical => $psu_capacitymaximum);
        $self->{output}->perfdata_add(label => "psu_" . $psu_bay . "_voltage", unit => 'V',
                                      value => $psu_voltage);
    }
}

1;