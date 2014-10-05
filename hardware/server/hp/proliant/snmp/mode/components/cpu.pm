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

package hardware::server::hp::proliant::snmp::mode::components::cpu;

use strict;
use warnings;

my %cpustatus = (
    1 => ['unknown', 'UNKNOWN'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
    5 => ['disabled', 'OK']
);

sub check {
    my ($self) = @_;
    # In MIB 'CPQSTDEQ-MIB.mib'
    
    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'cpu'));
    
    my $oid_cpqSeCpuUnitIndex = '.1.3.6.1.4.1.232.1.2.2.1.1.1';
    my $oid_cpqSeCpuSlot = '.1.3.6.1.4.1.232.1.2.2.1.1.2';
    my $oid_cpqSeCpuName = '.1.3.6.1.4.1.232.1.2.2.1.1.3';
    my $oid_cpqSeCpuStatus = '.1.3.6.1.4.1.232.1.2.2.1.1.6';
    my $oid_cpqSeCpuSocketNumber = '.1.3.6.1.4.1.232.1.2.2.1.1.9';

    my $result = $self->{snmp}->get_table(oid => $oid_cpqSeCpuUnitIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqSeCpuSlot, $oid_cpqSeCpuName,
                                 $oid_cpqSeCpuStatus, $oid_cpqSeCpuSocketNumber],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;

        my $cpu_slot = $result2->{$oid_cpqSeCpuSlot . '.' . $instance};
        my $cpu_name = $result2->{$oid_cpqSeCpuName . '.' . $instance};
        my $cpu_status = $result2->{$oid_cpqSeCpuStatus . '.' . $instance};
        my $cpu_socket_number =  $result2->{$oid_cpqSeCpuSocketNumber . '.' . $instance};
        
        next if ($self->check_exclude(section => 'cpu', instance => $instance));
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("cpu [slot: %s, unit: %s, name: %s, socket: %s] status is %s.", 
                                    $cpu_slot, $result->{$key}, $cpu_name, $cpu_socket_number,
                                    ${$cpustatus{$cpu_status}}[0]));
        if (${$cpustatus{$cpu_status}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$cpustatus{$cpu_status}}[1],
                                        short_msg => sprintf("cpu %d is %s", 
                                            $result->{$key}, ${$cpustatus{$cpu_status}}[0]));
        }
    }
}

1;