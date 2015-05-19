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

package hardware::server::hp::bladechassis::snmp::mode::components::enclosure;

use strict;
use warnings;

my %map_conditions = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

sub check {
    my ($self) = @_;

    my $oid_cpqRackCommonEnclosurePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.1.1.5.1';
    my $oid_cpqRackCommonEnclosureSparePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.1.1.6.1';
    my $oid_cpqRackCommonEnclosureSerialNum = '.1.3.6.1.4.1.232.22.2.3.1.1.1.7.1';
    my $oid_cpqRackCommonEnclosureFWRev = '.1.3.6.1.4.1.232.22.2.3.1.1.1.8.1';
    my $oid_cpqRackCommonEnclosureCondition = '.1.3.6.1.4.1.232.22.2.3.1.1.1.16.1';
    
    $self->{components}->{enclosure} = {name => 'enclosure', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking enclosure");
    return if ($self->check_exclude(section => 'enclosure'));
  
    my $result = $self->{snmp}->get_leef(oids => [$oid_cpqRackCommonEnclosurePartNumber, $oid_cpqRackCommonEnclosureSparePartNumber, 
                                                  $oid_cpqRackCommonEnclosureSerialNum, $oid_cpqRackCommonEnclosureFWRev,
                                                  $oid_cpqRackCommonEnclosureCondition], nothing_quit => 1);  
    $self->{components}->{enclosure}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("Enclosure overall health condition is %s [part: %s, spare: %s, sn: %s, fw: %s].", 
                                $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}},
                                $result->{$oid_cpqRackCommonEnclosurePartNumber},
                                $result->{$oid_cpqRackCommonEnclosureSparePartNumber},
                                $result->{$oid_cpqRackCommonEnclosureSerialNum},
                                $result->{$oid_cpqRackCommonEnclosureFWRev}));
    my $exit = $self->get_severity(section => 'enclosure', value => $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Enclosure overall health condition is %s", $map_conditions{$result->{$oid_cpqRackCommonEnclosureCondition}}));
    }
}

1;