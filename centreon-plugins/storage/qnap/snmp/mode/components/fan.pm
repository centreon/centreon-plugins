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

package storage::qnap::snmp::mode::components::fan;

use strict;
use warnings;

# In MIB 'NAS.mib'
my $oid_SysFanDescr = '.1.3.6.1.4.1.24681.1.2.15.1.2';
my $oid_SysFanSpeed = '.1.3.6.1.4.1.24681.1.2.15.1.3';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_SysFanDescr };
    push @{$options{request}}, { oid => $oid_SysFanSpeed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_SysFanDescr}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $fan_descr = $self->{results}->{$oid_SysFanDescr}->{$oid};
        my $fan_speed = defined($self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance}) ? 
                            $self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance} : 'unknown';

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' [instance: %s] speed is '%s'.",
                                    $fan_descr, $instance, $fan_speed));

        if ($fan_speed =~ /([0-9]+)\s*rpm/i) {
            my $fan_speed_value = $1;
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed_value);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan '%s' speed is %s rpm", $fan_descr, $fan_speed_value));
            }
            $self->{output}->perfdata_add(label => 'fan_' . $instance, unit => 'rpm',
                                          value => $fan_speed_value, min => 0
                                          );
        }
    }
}

1;