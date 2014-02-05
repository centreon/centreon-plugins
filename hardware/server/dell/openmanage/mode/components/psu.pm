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

package hardware::server::dell::openmanage::mode::components::psu;

use strict;
use warnings;

my %status = (
    1 => ['other', 'CRITICAL'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %type = (
    1 => 'other',
    2 => 'unknown',
    3 => 'Linear',
    4 => 'switching',
    5 => 'Battery',
    6 => 'UPS',
    7 => 'Converter',
    8 => 'Regulator',
    9 => 'AC',
    10 => 'DC',
    11 => 'VRM',
);

my %state = (
    1 => 'present',
    2 => 'failure',
    4 => 'predictiveFailure',
    8 => 'ACLost',
    16 => 'ACLostOrOutOfRange',
    32 => 'ACPresentButOutOfRange',
    64 => 'configurationError',
);

my %ConfigurationErrorType = (
    1 => 'vendorMismatch',
    2 => 'revisionMismatch',
    3 => 'processorMissing',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0};
    return if ($self->check_exclude('psu'));
   
    my $oid_powerSupplyStatus = '.1.3.6.1.4.1.674.10892.1.600.12.1.5';
    my $oid_powerSupplyType = '.1.3.6.1.4.1.674.10892.1.600.12.1.7';
    my $oid_powerSupplySensorState = '.1.3.6.1.4.1.674.10892.1.600.12.1.11';
    my $oid_powerSupplyConfigurationErrorType = '1.3.6.1.4.1.674.10892.1.600.12.1.12';

    my $result = $self->{snmp}->get_table(oid => $oid_powerSupplyStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_powerSupplyType, $oid_powerSupplySensorState, $oid_powerSupplyConfigurationErrorType],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $psu_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $psu_Index;
        
        my $psu_Status = $result->{$key};
        my $psu_Type = $result2->{$oid_powerSupplyType . '.' . $instance};
        my $psu_SensorState = $result2->{$oid_powerSupplySensorState . '.' . $instance};
        my $psu_ConfigurationErrorType = $result2->{$oid_powerSupplyConfigurationErrorType . '.' . $instance};

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("psu %d status is %s, state is %s [chassis: %d, type: %s].",
                                    $psu_Index, ${$status{$psu_Status}}[0], $state{$psu_SensorState},
                                    $chassis_Index, $type{$psu_Type}
                                    ));
        if ($psu_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$psu_Status}}[1],
                                        short_msg => sprintf("psu %d status is %s",
                                           $psu_Index, ${$status{$psu_Status}}[0]));
        }

    }
}

1;
