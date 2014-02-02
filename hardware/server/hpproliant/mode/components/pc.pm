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

package hardware::server::hpproliant::mode::components::pc;

use strict;
use warnings;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
);

my %present_map = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);

my %redundant_map = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);

sub check {
    my ($self) = @_;

    # In MIB 'CPQHLTH-MIB.mib'
    $self->{output}->output_add(long_msg => "Checking power converters");
    $self->{components}->{pc} = {name => 'power converters', total => 0};
    return if ($self->check_exclude('pc'));
    
    my $oid_cpqHePwrConvPresent = '.1.3.6.1.4.1.232.6.2.13.3.1.3';
    my $oid_cpqHePwrConvIndex = '.1.3.6.1.4.1.232.6.2.13.3.1.2';
    my $oid_cpqHePwrConvChassis = '.1.3.6.1.4.1.232.6.2.13.3.1.1';
    my $oid_cpqHePwrConvCondition = '.1.3.6.1.4.1.232.6.2.13.3.1.8';
    my $oid_cpqHePwrConvRedundant = '.1.3.6.1.4.1.232.6.2.13.3.1.6';
    my $oid_cpqHePwrConvRedundantGroupId = '.1.3.6.1.4.1.232.6.2.13.3.1.7';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqHePwrConvPresent);
    return if (scalar(keys %$result) <= 0);
    my @get_oids = ();
    my @oids_end = ();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($present_map{$result->{$key}} ne 'present');
        # Chassis + index
        $key =~ /(\d+\.\d+)$/;
        my $oid_end = $1;
        
        push @oids_end, $oid_end;
        push @get_oids, $oid_cpqHePwrConvCondition . "." . $oid_end, $oid_cpqHePwrConvRedundant . "." . $oid_end,
                $oid_cpqHePwrConvRedundantGroupId . "." . $oid_end;
    }
    $result = $self->{snmp}->get_leef(oids => \@get_oids);
    foreach (@oids_end) {
        my ($pc_chassis, $pc_index) = split /\./;
        my $pc_condition = $result->{$oid_cpqHePwrConvIndex . '.' . $_};
        my $pc_redundant = $result->{$oid_cpqHePwrConvRedundant . '.' . $_};
        my $pc_redundantgroup = defined($result->{$oid_cpqHePwrConvRedundantGroupId . '.' . $_}) ? $result->{$oid_cpqHePwrConvRedundantGroupId . '.' . $_} : 'undefined';

        $self->{components}->{pc}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("powerconverter %d status is %s [chassis: %s, redundance: %s, redundant group: %s].",
                                    $pc_index, ${$conditions{$pc_condition}}[0],
                                    $pc_chassis, $redundant_map{$pc_redundant}, $pc_redundantgroup
                                    ));
        if ($pc_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$pc_condition}}[1],
                                        short_msg => sprintf("powerconverter %d status is %s",
                                           $pc_index, ${$conditions{$pc_condition}}[0]));
        }
    }
}

1;