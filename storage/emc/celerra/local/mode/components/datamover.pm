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

package storage::emc::celerra::local::mode::components::datamover;

use strict;
use warnings;

my %map_dm_status = (
    0 => 'Reset (or unknown state)',
    1 => 'DOS boot phase, BIOS check, boot sequence',
    2 => 'SIB POST failures (that is, hardware failures)',
    3 => 'DART is loaded on Data Mover, DOS boot and execution of boot.bat, boot.cfg',
    4 => 'DART is ready on Data Mover, running, and MAC threads started',
    5 => 'DART is in contact with Control Station box monitor',
    7 => 'DART is in panic state',
    9 => 'DART reboot is pending or in halted state',
    13 => 'DART panicked and completed memory dump',
    14 => 'DM Misc problems',
    15 => 'Data Mover is flashing firmware. DART is flashing BIOS and/or POST firmware. Data Mover cannot be reset',
    17 => 'Data Mover Hardware fault detected',
    18 => 'DM Memory Test Failure. BIOS detected memory error',
    19 => 'DM POST Test Failure. General POST error',
    20 => 'DM POST NVRAM test failure. Invalid NVRAM content error',
    21 => 'DM POST invalid peer Data Mover type',
    22 => 'DM POST invalid Data Mover part number',
    23 => 'DM POST Fibre Channel test failure. Error in blade Fibre connection',
    24 => 'DM POST network test failure. Error in Ethernet controller',
    25 => 'DM T2NET Error. Unable to get blade reason code due to management switch problems',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking data movers");
    $self->{components}->{datamover} = {name => 'data movers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'datamover'));

    foreach my $line (split /\n/, $self->{stdout}) {
        next if ($line !~ /^\s*(\d+)\s+-\s+(\S+)/);
        my ($code, $instance) = ($1, $2);
        next if (!defined($map_dm_status{$code}));
        
        return if ($self->check_exclude(section => 'datamover', instance => $instance));
        
        $self->{components}->{datamover}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Data mover '%s' status is '%s'",
                                    $instance, $map_dm_status{$code}));
        my $exit = $self->get_severity(section => 'datamover', value => $map_dm_status{$code});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Data mover '%s' status is '%s'",
                                                             $instance, $map_dm_status{$code}));
        }
    }
}

1;