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

package storage::qnap::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'NAS.mib'
my $oid_CPU_Temperature_entry = '.1.3.6.1.4.1.24681.1.2.5';
my $oid_CPU_Temperature = '.1.3.6.1.4.1.24681.1.2.5.0';
my $oid_SystemTemperature_entry = '.1.3.6.1.4.1.24681.1.2.6';
my $oid_SystemTemperature = '.1.3.6.1.4.1.24681.1.2.6.0';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_CPU_Temperature_entry };
    push @{$options{request}}, { oid => $oid_SystemTemperature_entry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

    my $cpu_temp = defined($self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature}) ? 
                           $self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature} : 'unknown';
    if ($cpu_temp =~ /([0-9]+)\s*C/ && !$self->check_exclude(section => 'temperature', instance => 'cpu')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("CPU Temperature is '%s' degree centigrade",
                                                        $value));
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'cpu', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("CPU Temperature is '%s' degree centigrade", $value));
        }
        $self->{output}->perfdata_add(label => 'temp_cpu', unit => 'C',
                                      value => $value
                                      );
    }
    
    my $system_temp = defined($self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature}) ? 
                           $self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature} : 'unknown';
    if ($system_temp =~ /([0-9]+)\s*C/ && !$self->check_exclude(section => 'temperature', instance => 'system')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("System Temperature is '%s' degree centigrade",
                                                        $value));
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'system', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("System Temperature is '%s' degree centigrade", $value));
        }
        $self->{output}->perfdata_add(label => 'temp_system', unit => 'C',
                                      value => $value
                                      );
    }
}

1;