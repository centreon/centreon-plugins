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

package storage::emc::DataDomain::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

my %conditions = (
    0 => ['not found', 'UNKNOWN'], 
    1 => ['ok', 'OK'], 
    2 => ['failed', 'CRITICAL'], 
);
my %level_map = (
    0 => 'unknown',
    1 => 'low',
    2 => 'normal',
    3 => 'high',
);

sub check {
    my ($self) = @_;

    $self->{components}->{fans} = {name => 'fans', total => 0};
    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude('fans'));
    
    my $oid_fanPropertiesEntry = '.1.3.6.1.4.1.19746.1.1.3.1.1.1';
    my $oid_fanDescription = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.3';
    my $oid_fanLevel = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.4';
    my $oid_fanStatus = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_fanPropertiesEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_fanStatus\.(\d+)\.(\d+)$/);
        my ($enclosure_id, $fan_index) = ($1, $2);
    
        my $fan_descr = centreon::plugins::misc::trim($result->{$oid_fanDescription . '.' . $enclosure_id . '.' . $fan_index});
        my $fan_level = $result->{$oid_fanLevel . '.' . $enclosure_id . '.' . $fan_index};
        my $fan_status = $result->{$oid_fanStatus . '.' . $enclosure_id . '.' . $fan_index};

        $self->{components}->{fans}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is %s [enclosure = %d, index = %d, level = %s].", 
                                    $fan_descr, ${$conditions{$fan_status}}[0], $enclosure_id, $fan_index, $level_map{$fan_level}));
        if (!$self->{output}->is_status(litteral => 1, value => ${$conditions{$fan_status}}[1], compare => 'ok')) {
            $self->{output}->output_add(severity => ${$conditions{$fan_status}}[1],
                                        short_msg => sprintf("Fan '%s' status is %s", $fan_descr, ${$conditions{$fan_status}}[0]));
        }
    }
}

1;