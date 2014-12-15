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

package storage::emc::DataDomain::mode::components::disk;

use strict;
use warnings;
use centreon::plugins::misc;

my $oid_diskPropState;

my %map_disk_status = (
    1 => 'ok',
    2 => 'unknown',
    3 => 'absent',
    4 => 'failed',
    5 => 'spare',     # since OS 5.4
    6 => 'available', # since OS 5.4
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));
    
    my $oid_diskPropState;
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_diskPropState = '.1.3.6.1.4.1.19746.1.6.1.1.1.8';
    } else {
        $oid_diskPropState = '.1.3.6.1.4.1.19746.1.6.1.1.1.7';
    }

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskPropState}})) {
        $oid =~ /^$oid_diskPropState\.(.*)$/;
        my $instance = $1;
        my $disk_status = defined($map_disk_status{$self->{results}->{$oid_diskPropState}->{$oid}}) ?
                            $map_disk_status{$self->{results}->{$oid_diskPropState}->{$oid}} : 'unknown';

        next if ($self->check_exclude(section => 'disk', instance => $instance));
        next if ($disk_status =~ /absent/i && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' status is '%s'",
                                    $instance, $disk_status));
        my $exit = $self->get_severity(section => 'disk', value => $disk_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is '%s'", $instance, $disk_status));
        }
    }
}

1;