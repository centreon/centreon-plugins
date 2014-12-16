################################################################################
# Copyright 2005-2014 MERETHIS
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

package storage::netapp::mode::components::raid;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_raid_states = (
    1 => 'active',
    2 => 'reconstructionInProgress',
    3 => 'parityReconstructionInProgress',
    4 => 'parityVerificationInProgress',
    5 => 'scrubbingInProgress',
    6 => 'failed',
    9 => 'prefailed',
    10 => 'offline',
);
my $oid_raidPStatus = '.1.3.6.1.4.1.789.1.6.10.1.2';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_raidPStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raids");
    $self->{components}->{raid} = {name => 'raids', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'raid'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidPStatus}})) {
        $oid =~ /^$oid_raidPStatus\.(.*)$/;
        my $instance = $1;
        my $raid_state = $map_raid_states{$self->{results}->{$oid_raidPStatus}->{$oid}};

        next if ($self->check_exclude(section => 'raid', instance => $instance));
        
        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Raid '%s' state is '%s'", 
                                                        $instance, $raid_state));
        my $exit = $self->get_severity(section => 'raid', value => $raid_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid '%s' state is '%s'", 
                                                             $instance, $raid_state));
        }
    }
}

1;
