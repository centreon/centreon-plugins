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

my %map_fan_status = (
    0 => 'notfound',
    1 => 'ok',
    2 => 'failed',
);
my %level_map = ( 
    0 => 'unknown',
    1 => 'low',
    2 => 'normal',
    3 => 'high',
); 

my ($oid_fanDescription, $oid_fanLevel, $oid_fanStatus);
my $oid_fanPropertiesEntry = '.1.3.6.1.4.1.19746.1.1.3.1.1.1';

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_fanDescription = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.4';
        $oid_fanLevel = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.5';
        $oid_fanStatus = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.6';
    } else {
        $oid_fanDescription = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.3';
        $oid_fanLevel = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.4';
        $oid_fanStatus = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.5';
    }

    foreach my $oid (keys %{$self->{results}->{$oid_fanPropertiesEntry}}) {
        next if ($oid !~ /^$oid_fanStatus\.(.*)$/);
        my $instance = $1;
        my $fan_descr = centreon::plugins::misc::trim($self->{results}->{$oid_fanPropertiesEntry}->{$oid_fanDescription . '.' . $instance});
        my $fan_status = defined($map_fan_status{$self->{results}->{$oid_fanPropertiesEntry}->{$oid}}) ?
                            $map_fan_status{$self->{results}->{$oid_fanPropertiesEntry}->{$oid}} : 'unknown';
        my $fan_level = $self->{results}->{$oid_fanPropertiesEntry}->{$oid_fanLevel . '.' . $instance};

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        next if ($fan_status =~ /notfound/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is '%s' [instance = %s, level = %s]",
                                    $fan_descr, $fan_status, $instance, $level_map{$fan_level}));
        my $exit = $self->get_severity(section => 'fan', value => $fan_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $fan_descr, $fan_status));
        }
    }
}

1;