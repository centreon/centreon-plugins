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

package hardware::server::hp::bladechassis::snmp::mode::components::fuse;

use strict;
use warnings;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
    4 => 'Weird!!!', # for blades it can return 4, which is NOT spesified in MIB
);

sub check {
    my ($self) = @_;

    $self->{components}->{fuses} = {name => 'fuses', total => 0};
    $self->{output}->output_add(long_msg => "Checking fuse");
    return if ($self->check_exclude('fuse'));
    
    my $oid_cpqRackCommonEnclosureFusePresent = '.1.3.6.1.4.1.232.22.2.3.1.4.1.6';
    my $oid_cpqRackCommonEnclosureFuseIndex = '.1.3.6.1.4.1.232.22.2.3.1.4.1.3';
    my $oid_cpqRackCommonEnclosureFuseEnclosureName = '.1.3.6.1.4.1.232.22.2.3.1.4.1.4';
    my $oid_cpqRackCommonEnclosureFuseLocation = '.1.3.6.1.4.1.232.22.2.3.1.4.1.5';
    my $oid_cpqRackCommonEnclosureFuseCondition = '.1.3.6.1.4.1.232.22.2.3.1.4.1.7';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureFusePresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($present_map{$result->{$key}} ne 'present');
        $key =~ /\.([0-9]+)$/;
        my $oid_end = $1;
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqRackCommonEnclosureFuseIndex . "." . $oid_end, $oid_cpqRackCommonEnclosureFuseEnclosureName . "." . $oid_end,
                $oid_cpqRackCommonEnclosureFuseLocation . "." . $oid_end, $oid_cpqRackCommonEnclosureFuseCondition . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my $fuse_index = $result->{$oid_cpqRackCommonEnclosureFuseIndex . '.' . $_};
        my $fuse_name = $result->{$oid_cpqRackCommonEnclosureFuseEnclosureName . '.' . $_};
        my $fuse_location = $result->{$oid_cpqRackCommonEnclosureFuseLocation . '.' . $_};
        my $fuse_condition = $result->{$oid_cpqRackCommonEnclosureFuseCondition . '.' . $_};
        
        $self->{components}->{fuses}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fuse %d status is %s [name: %s, location: %s].",
                                    $fuse_index, ${$conditions{$fuse_condition}}[0],
                                    $fuse_name, $fuse_location));
        if ($fuse_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$fuse_condition}}[1],
                                        short_msg => sprintf("Fuse %d status is %s",
                                            $fuse_index, ${$conditions{$fuse_condition}}[0]));
        }
    }
}

1;