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

package hardware::server::cisco::ucs::mode::components::fan;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%presence %operability);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0};
    return if ($self->check_exclude('fan'));
    
    my $oid_cucsEquipmentFanPresence = '.1.3.6.1.4.1.9.9.719.1.15.12.1.13';
    my $oid_cucsEquipmentFanOperState = '.1.3.6.1.4.1.9.9.719.1.15.12.1.9';
    my $oid_cucsEquipmentFanDn = '.1.3.6.1.4.1.9.9.719.1.15.12.1.2';

    my $result = $self->{snmp}->get_table(oid => $oid_cucsEquipmentFanPresence);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        # index
        $key =~ /\.(\d+)$/;
        my $oid_end = $1;

        if (${$presence{$result->{$key}}}[1] ne 'OK') {
            $self->{components}->{fan}->{total}++;
            $self->{output}->output_add(severity => ${$presence{$result->{$key}}}[1],
                                        short_msg => sprintf("fan index '%s' presence is: '%s'",
                                                             $oid_end, ${$presence{$result->{$key}}}[0])
                                        );
        }
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cucsEquipmentFanOperState . "." . $oid_end, $oid_cucsEquipmentFanDn . "." . $oid_end;
    }
    return if (scalar(@get_oids) <= 0);
    
    my $result2 = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my ($fan_index) = $_;
        my $fan_dn = $result2->{$oid_cucsEquipmentFanDn . '.' . $_};
        my $fan_operstate = $result2->{$oid_cucsEquipmentFanOperState . '.' . $_};
        my $fan_presence = $result->{$oid_cucsEquipmentFanPresence . '.' . $_};

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' state is '%s' [presence: %s].",
                                                        $fan_dn, ${$operability{$fan_operstate}}[0],
                                                        ${$presence{$fan_presence}}[0]
                                    ));
        if (${$operability{$fan_operstate}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$operability{$fan_operstate}}[1],
                                        short_msg => sprintf("fan '%s' state is '%s'.",
                                                             $fan_dn, ${$operability{$fan_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;