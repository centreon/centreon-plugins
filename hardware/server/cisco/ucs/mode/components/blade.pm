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

package hardware::server::cisco::ucs::mode::components::blade;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking blades");
    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'blade'));
    
    my $oid_cucsComputeBladePresence = '.1.3.6.1.4.1.9.9.719.1.9.2.1.45';
    my $oid_cucsComputeBladeOperState = '.1.3.6.1.4.1.9.9.719.1.9.2.1.42';
    my $oid_cucsComputeBladeDn = '.1.3.6.1.4.1.9.9.719.1.9.2.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsComputeBladePresence },
                                                            { oid => $oid_cucsComputeBladeOperState },
                                                            { oid => $oid_cucsComputeBladeDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsComputeBladePresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $blade_index = $1;        
        my $blade_dn = $result->{$oid_cucsComputeBladeDn}->{$oid_cucsComputeBladeDn . '.' . $blade_index};
        my $blade_operstate = defined($result->{$oid_cucsComputeBladeOperState}->{$oid_cucsComputeBladeOperState . '.' . $blade_index}) ?
                                $result->{$oid_cucsComputeBladeOperState}->{$oid_cucsComputeBladeOperState . '.' . $blade_index} : 0; # unknown
        my $blade_presence = defined($result->{$oid_cucsComputeBladePresence}->{$oid_cucsComputeBladePresence . '.' . $blade_index}) ? 
                                $result->{$oid_cucsComputeBladePresence}->{$oid_cucsComputeBladePresence . '.' . $blade_index} : 0;
        
        next if ($self->absent_problem(section => 'blade', instance => $blade_dn));
        next if ($self->check_exclude(section => 'blade', instance => $blade_dn));

        my $exit = $self->get_severity(section => 'blade', threshold => 'presence', value => $blade_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("blade '%s' presence is: '%s'",
                                                             $blade_dn, ${$thresholds->{presence}{$blade_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{blade}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("blade '%s' state is '%s' [presence: %s].",
                                                        $blade_dn, ${$thresholds->{operability}->{$blade_operstate}}[0],
                                                        ${$thresholds->{presence}->{$blade_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'blade', threshold => 'operability', value => $blade_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("blade '%s' state is '%s'.",
                                                             $blade_dn, ${$thresholds->{operability}->{$blade_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;