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

package hardware::server::cisco::ucs::mode::components::psu;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%presence %operability);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    
    my $oid_cucsEquipmentPsuPresence = '.1.3.6.1.4.1.9.9.719.1.15.56.1.11';
    my $oid_cucsEquipmentPsuOperState = '.1.3.6.1.4.1.9.9.719.1.15.56.1.7';
    my $oid_cucsEquipmentPsuDn = '.1.3.6.1.4.1.9.9.719.1.15.56.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentPsuPresence },
                                                            { oid => $oid_cucsEquipmentPsuOperState },
                                                            { oid => $oid_cucsEquipmentPsuDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentPsuPresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $psu_index = $1;        
        my $psu_dn = $result->{$oid_cucsEquipmentPsuDn}->{$oid_cucsEquipmentPsuDn . '.' . $psu_index};
        my $psu_operstate = defined($result->{$oid_cucsEquipmentPsuOperState}->{$oid_cucsEquipmentPsuOperState . '.' . $psu_index}) ?
                                $result->{$oid_cucsEquipmentPsuOperState}->{$oid_cucsEquipmentPsuOperState . '.' . $psu_index} : 0; # unknown
        my $psu_presence = defined($result->{$oid_cucsEquipmentPsuPresence}->{$oid_cucsEquipmentPsuPresence . '.' . $psu_index}) ? 
                                $result->{$oid_cucsEquipmentPsuPresence}->{$oid_cucsEquipmentPsuPresence . '.' . $psu_index} : 0;
        
        next if ($self->absent_problem(section => 'psu', instance => $psu_dn));
        next if ($self->check_exclude(section => 'psu', instance => $psu_dn));

        if (${$presence{$psu_presence}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$presence{$psu_presence}}[1],
                                        short_msg => sprintf("power supply '%s' presence is: '%s'",
                                                             $psu_dn, ${$presence{$psu_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{psu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' state is '%s' [presence: %s].",
                                                        $psu_dn, ${$operability{$psu_operstate}}[0],
                                                        ${$presence{$psu_presence}}[0]
                                    ));
        if (${$operability{$psu_operstate}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$operability{$psu_operstate}}[1],
                                        short_msg => sprintf("power supply '%s' state is '%s'.",
                                                             $psu_dn, ${$operability{$psu_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;