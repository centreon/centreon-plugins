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

package storage::emc::DataDomain::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = ();
my ($oid_powerModuleDescription, $oid_powerModuleStatus);
my $oid_powerModuleEntry = '.1.3.6.1.4.1.19746.1.1.1.1.1.1';

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_powerModuleDescription = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.3';
        $oid_powerModuleStatus = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.4';
        %map_psu_status = (0 => 'absent', 1 => 'ok', 2 => 'failed', 3 => 'faulty', 4 => 'acnone',
                           99 => 'unknown');
    } else {
        $oid_powerModuleDescription = ''; # none
        $oid_powerModuleStatus = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.4';
        %map_psu_status = (1 => 'ok', 2 => 'unknown', 3 => 'failed');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_powerModuleEntry}}) {
        next if ($oid !~ /^$oid_powerModuleStatus\.(.*)$/);
        my $instance = $1;
        my $psu_descr = defined($self->{results}->{$oid_powerModuleEntry}->{$oid_powerModuleDescription . '.' . $instance}) ? 
                            centreon::plugins::misc::trim($self->{results}->{$oid_powerModuleEntry}->{$oid_powerModuleDescription . '.' . $instance}) : 'unknown';
        my $psu_status = defined($map_psu_status{$self->{results}->{$oid_powerModuleEntry}->{$oid}}) ?
                            $map_psu_status{$self->{results}->{$oid_powerModuleEntry}->{$oid}} : 'unknown';

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($psu_status =~ /absent/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' status is '%s' [description = %s]",
                                    $instance, $psu_status, $instance));
        my $exit = $self->get_severity(section => 'psu', value => $psu_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is '%s'", $instance, $psu_status));
        }
    }
}

1;