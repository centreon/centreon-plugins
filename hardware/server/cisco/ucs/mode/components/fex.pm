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

package hardware::server::cisco::ucs::mode::components::fex;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking fabric extenders");
    $self->{components}->{fex} = {name => 'fabric extenders', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fex'));
    
    my $oid_cucsEquipmentFexDn = '.1.3.6.1.4.1.9.9.719.1.15.19.1.2';
    my $oid_cucsEquipmentFexOperState = '.1.3.6.1.4.1.9.9.719.1.15.19.1.21';
    my $oid_cucsEquipmentFexPresence = '.1.3.6.1.4.1.9.9.719.1.15.19.1.24';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentFexDn },
                                                            { oid => $oid_cucsEquipmentFexOperState },
                                                            { oid => $oid_cucsEquipmentFexPresence },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentFexDn}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $fex_index = $1;
        my $fex_dn = $result->{$oid_cucsEquipmentFexDn}->{$oid_cucsEquipmentFexDn . '.' . $fex_index};
        my $fex_operstate = defined($result->{$oid_cucsEquipmentFexOperState}->{$oid_cucsEquipmentFexOperState . '.' . $fex_index}) ?
                                $result->{$oid_cucsEquipmentFexOperState}->{$oid_cucsEquipmentFexOperState . '.' . $fex_index} : 0; # unknown
        my $fex_presence = defined($result->{$oid_cucsEquipmentFexPresence}->{$oid_cucsEquipmentFexPresence . '.' . $fex_index}) ? 
                                $result->{$oid_cucsEquipmentFexPresence}->{$oid_cucsEquipmentFexPresence . '.' . $fex_index} : 0;
        
        next if ($self->absent_problem(section => 'fex', instance => $fex_dn));
        next if ($self->check_exclude(section => 'fex', instance => $fex_dn));

        my $exit = $self->get_severity(section => 'fex', threshold => 'presence', value => $fex_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fabric extender '%s' presence is: '%s'",
                                                             $fex_dn, ${$thresholds->{presence}->{$fex_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{fex}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Fabric extender '%s' state is '%s' [presence: %s].",
                                                        $fex_dn, ${$thresholds->{operability}->{$fex_operstate}}[0],
                                                        ${$thresholds->{presence}->{$fex_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'fex', threshold => 'operability', value => $fex_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fabric extender '%s' state is '%s'.",
                                                             $fex_dn, ${$thresholds->{operability}->{$fex_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
