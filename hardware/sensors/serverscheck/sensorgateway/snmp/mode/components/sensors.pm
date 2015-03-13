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

package hardware::sensors::serverscheck::sensorgateway::snmp::mode::components::sensors;

use strict;
use warnings;

my $oid_control = '.1.3.6.1.4.1.17095.3';
my $list_oids = {
    1 => 1,
    2 => 5,
    3 => 9,
    4 => 13,
    5 => 17,
}

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_control };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensors} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'sensors'));

    foreach my $i (keys %{$list_oids}) {
        if (!defined($self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'}) || 
            $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'} !~ /([0-9\.]+)/) {
            $self->{output}->output_add(long_msg => sprintf("skip sensor '%s': no values", 
                                                             $i));
            next;
        }
        
        my $name = $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i}) . '.0'}
        my $value = $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'};
        
        next if ($self->check_exclude(section => 'sensors', instance => $temp));
        $self->{components}->{sensors}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("sensor '%s' value is %s.", 
                                                        $name, $value));
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensor', instance => $name, value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sensor '%s' value is %s", 
                                                             $name, $value));
        }
        $self->{output}->perfdata_add(label => $name,
                                      value => $value,
                                      warning => $warn,
                                      critical => $crit);
    }
}

1;