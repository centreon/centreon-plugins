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

package hardware::server::dell::openmanage::mode::components::memory;

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

my %failureModes = (
    0 => 'Not failure',
    1 => 'ECC single bit correction warning rate exceeded',
    2 => 'ECC single bit correction failure rate exceeded',
    4 => 'ECC multibit fault encountered',
    8 => 'ECC single bit correction logging disabled',
    16 => 'device disabled because of spare activation',
);

sub check {
    my ($self) = @_;

    # In MIB '10892.mib'
    $self->{output}->output_add(long_msg => "Checking Memory Modules");
    $self->{components}->{memory} = {name => 'memory modules', total => 0};
    return if ($self->check_exclude('memory'));
   
    my $oid_memoryDeviceStatus = '.1.3.6.1.4.1.674.10892.1.1100.50.1.5';
    my $oid_memoryDeviceLocationName = '.1.3.6.1.4.1.674.10892.1.1100.50.1.8';
    my $oid_memoryDeviceSize = '.1.3.6.1.4.1.674.10892.1.1100.50.1.14';
    my $oid_memoryDeviceFailureModes = '.1.3.6.1.4.1.674.10892.1.1100.50.1.20';

    my $result = $self->{snmp}->get_table(oid => $oid_memoryDeviceStatus);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_memoryDeviceLocationName, $oid_memoryDeviceSize, $oid_memoryDeviceFailureModes],
                        instances => [keys %$result],
                        instance_regexp => '(\d+\.\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)\.(\d+)$/;
        my ($chassis_Index, $memory_Index) = ($1, $2);
        my $instance = $chassis_Index . '.' . $memory_Index;
        
        my $memory_deviceStatus = $result->{$key};
        my $memory_deviceLocationName = $result2->{$oid_memoryDeviceLocationName . '.' . $instance};
        my $memory_deviceSize = $result2->{$oid_memoryDeviceSize . '.' . $instance};
        my $memory_deviceFailureModes = $result2->{$oid_memoryDeviceFailureModes . '.' . $instance};
       
        $self->{components}->{memory}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("memory module %d status is %s, failure mode is %s, size is %d Ko [chassis: %d, Location: %s].",
                                    $memory_Index, ${$status{$memory_deviceStatus}}[0], $failureModes{$memory_deviceFailureModes},
                                    $memory_deviceSize, $chassis_Index, $memory_deviceLocationName
                                    ));

        if ($memory_deviceStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$memory_deviceStatus}}[1],
                                        short_msg => sprintf("memory module %d status is %s",
                                           $memory_Index, ${$status{$memory_deviceStatus}}[0]));
        }

    }
}

1;
