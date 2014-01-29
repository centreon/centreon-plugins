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

package hardware::server::hpbladechassis::mode::components::manager;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL'],
);
my %map_role = (
    1 => 'Standby',
    2 => 'Active',
);

sub check {
    my ($self, %options) = @_;
    
    $self->{components}->{managers} = {name => 'managers', total => 0};
    return if ($self->check_exclude('managers'));

    # No check if OK
    if ((!defined($options{force}) || $options{force} != 1) && $self->{output}->is_status(compare => 'ok', litteral => 1)) {
        return ;
    }
    $self->{output}->output_add(long_msg => "Checking managers");
    
    my $oid_cpqRackCommonEnclosureManagerIndex = '.1.3.6.1.4.1.232.22.2.3.1.6.1.3';
    my $oid_cpqRackCommonEnclosureManagerPartNumber = '.1.3.6.1.4.1.232.22.2.3.1.6.1.6';
    my $oid_cpqRackCommonEnclosureManagerSparePartNumber = '.1.3.6.1.4.1.232.22.2.3.1.6.1.7';
    my $oid_cpqRackCommonEnclosureManagerSerialNum = '.1.3.6.1.4.1.232.22.2.3.1.6.1.8';
    my $oid_cpqRackCommonEnclosureManagerRole = '.1.3.6.1.4.1.232.22.2.3.1.6.1.9';
    my $oid_cpqRackCommonEnclosureManagerCondition = '.1.3.6.1.4.1.232.22.2.3.1.6.1.12';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqRackCommonEnclosureManagerIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqRackCommonEnclosureManagerPartNumber, $oid_cpqRackCommonEnclosureManagerSparePartNumber,
                                $oid_cpqRackCommonEnclosureManagerSerialNum, $oid_cpqRackCommonEnclosureManagerRole,
                                $oid_cpqRackCommonEnclosureManagerCondition],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;
    
        my $man_part = $result2->{$oid_cpqRackCommonEnclosureManagerPartNumber . '.' . $instance};
        my $man_spare = $result2->{$oid_cpqRackCommonEnclosureManagerSparePartNumber . '.' . $instance};
        my $man_serial = $result2->{$oid_cpqRackCommonEnclosureManagerSerialNum . '.' . $instance};
        my $man_role = $result2->{$oid_cpqRackCommonEnclosureManagerRole . '.' . $instance};
        my $man_condition = $result2->{$oid_cpqRackCommonEnclosureManagerCondition . '.' . $instance};
        
        $self->{components}->{managers}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Enclosure management module %d is %s, status is %s [serial: %s, part: %s, spare: %s].", 
                                    $instance, ${$conditions{$man_condition}}[0], $map_role{$man_role},
                                    $man_serial, $man_part, $man_spare));
        if ($man_condition != 2) {
            $self->{output}->output_add(severity =>  ${$conditions{$man_condition}}[1],
                                        short_msg => sprintf("Enclosure management module %d is %s, status is %s", 
                                            $instance, ${$conditions{$man_condition}}[0], $map_role{$man_role}));
        }
    }
}

1;