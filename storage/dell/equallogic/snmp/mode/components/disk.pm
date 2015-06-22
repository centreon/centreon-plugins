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

package storage::dell::equallogic::snmp::mode::components::disk;

use strict;
use warnings;

my %map_disk_status = (
    1 => 'on-line',
    2 => 'spare',
    3 => 'failed',
    4 => 'off-line',
    5 => 'alt-sig',
    6 => 'too-small',
    7 => 'history-of-failures',
    8 => 'unsupported-version',
    9 => 'unhealthy',
    10 => 'replacement',
);

# In MIB 'eqldisk.mib'
my $mapping = {
    eqlDiskStatus => { oid => '.1.3.6.1.4.1.12740.3.1.1.1.8', map => \%map_disk_status },
};
my $oid_eqlDiskStatus = '.1.3.6.1.4.1.12740.3.1.1.1.8';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_eqlDiskStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlDiskStatus}})) {
        next if ($oid !~ /^$mapping->{eqlDiskStatus}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlDiskStatus}, instance => $member_instance . '.' . $instance);

        next if ($self->check_exclude(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Disk '%s/%s' status is %s [instance: %s].",
                                    $member_name, $instance, $result->{eqlDiskStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'disk', value => $result->{eqlDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Disk '%s/%s' status is %s",
                                                             $member_name, $instance, $result->{eqlDiskStatus}));
        }
    }
}

1;