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

package storage::qnap::snmp::mode::components::disk;

use strict;
use warnings;

my %map_status_disk = (
    0 => 'ready',
    '-5' => 'noDisk',
    '-6' => 'invalid',
    '-9' => 'rwError',
    '-4' => 'unknown',
);

# In MIB 'NAS.mib'
my $mapping = {
    HdDescr => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.2' },
    HdTemperature => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.3' },
    HdStatus => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.4', map => \%map_status_disk },
};
my $mapping2 = {
    HdSmartInfo => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.7' },
};
my $oid_HdEntry = '.1.3.6.1.4.1.24681.1.2.11.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_HdEntry, start => $mapping->{HdDescr}->{oid}, end => $mapping->{HdStatus}->{oid} };
    push @{$options{request}}, { oid => $mapping2->{HdSmartInfo}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_HdEntry}})) {
        next if ($oid !~ /^$mapping->{HdDescr}->{oid}\.(\d+)$/);
        my $instance = $1;
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_HdEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{HdSmartInfo}->{oid} }, instance => $instance);

        next if ($self->check_exclude(section => 'disk', instance => $instance));
        next if ($result->{HdStatus} eq 'noDisk' && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' [instance: %s, temperature: %s, smart status: %s] status is %s.",
                                    $result->{HdDescr}, $instance, $result->{HdTemperature}, $result2->{HdSmartInfo}, $result->{HdStatus}));
        my $exit = $self->get_severity(section => 'disk', value => $result->{HdStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is %s.", $result->{HdDescr}, $result->{HdStatus}));
        }
        
        $exit = $self->get_severity(section => 'smartdisk', value => $result2->{HdSmartInfo});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' smart status is %s.", $result->{HdDescr}, $result2->{HdSmartInfo}));
        }
        
        if ($result->{HdTemperature} =~ /([0-9]+)\s*C/) {
            my $disk_temp = $1;
            my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'disk', instance => $instance, value => $disk_temp);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Disk '%s' temperature is %s degree centigrade", $result->{HdDescr}, $disk_temp));
            }
            $self->{output}->perfdata_add(label => 'temp_disk_' . $instance, unit => 'C',
                                          value => $disk_temp
                                          );
        }
    }
}

1;