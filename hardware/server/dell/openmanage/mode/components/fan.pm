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

package hardware::server::dell::openmanage::mode::components::fan;

use strict;
use warnings;

my %status = (
    1 => ['other', 'CRITICAL'], 
    2 => ['unknown', 'UNKNOWN'], 
    3 => ['ok', 'OK'], 
    4 => ['nonCriticalUpper', 'WARNING'],
    5 => ['criticalUpper', 'CRITICAL'],
    6 => ['nonRecoverableUpper', 'CRITICAL'],
    7 => ['nonCriticalLower', 'WARNING'],
    8 => ['criticalLower', 'CRITICAL'],
    9 => ['nonRecoverableLower', 'CRITICAL'],
    10 => ['failed', 'CRITICAL']

);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0};
    return if ($self->check_exclude('fan'));
   
    my $oid_coolingDeviceStatus = '.1.3.6.1.4.1.674.10892.1.700.12.1.5.1';
    my $oid_coolingDeviceReading = '.1.3.6.1.4.1.674.10892.1.700.12.1.6.1';
    my $oid_coolingDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.700.12.1.8.1';

    my $result = $self->{snmp}->get_table(oid => $oid_coolingDeviceStatus);
    return if (scalar(keys %$result) <= 0);

    my $result2 = $self->{snmp}->get_leef(oids => [$oid_coolingDeviceReading, $oid_coolingDeviceLocationName],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+\.\d+)$');
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $fan_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $fan_Index;
        
        my $fan_Status = $result->{$key};
        my $fan_Reading = $result2->{$oid_coolingDeviceReading . '.' . $instance};
        my $fan_LocationName = $result->{$oid_coolingDeviceLocationName . '.' . $instance};

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan %d status is %s, speed is %d [chassis: %d, location: %s].",
                                    $fan_Index, ${$status{$fan_Status}}[0], $fan_Reading,
                                    $chassis_Index, $fan_LocationName
                                    ));
        if ($fan_Status != 3) {
            $self->{output}->output_add(severity =>  ${$status{$fan_Status}}[1],
                                        short_msg => sprintf("fan %d status is %s",
                                           $fan_Index, ${$status{$fan_Status}}[0]));
        }

        if (defined($fan_Reading)) {
            $self->{output}->perfdata_add(label => "fan_" . $fan_Index . "_speed", unit => 'rpm',
                                          value => $fan_Reading);
        }
    }
}

1;
