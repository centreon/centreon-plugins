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

package centreon::common::violin::snmp::mode::components::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_chassisSystemTempAmbient = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.21';
my $oid_chassisSystemTempController = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.21';
my $oid_arrayVimmEntry_temp = '.1.3.6.1.4.1.35897.1.2.2.3.16.1.12';

sub temperature {
    my ($self, %options) = @_;
    my $oid = $options{oid};
    
    $options{oid} =~ /^$options{oid_short}\.(.*)$/;
    my ($dummy, $array_name, $extra_name) = $self->convert_index(value => $1);
    my $instance = $array_name . '-' . (defined($extra_name) ? $extra_name : $options{extra_instance});
    
    my $temperature = $options{value};

    return if ($self->check_exclude(section => 'temperature', instance => $instance));
        
    $self->{components}->{psu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %s degree centigrade.",
                                $instance, $temperature));
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temperature);
    $self->{output}->perfdata_add(label => 'temp_' . $instance, unit => 'C',
                                  value => $temperature,
                                  warning => $warn,
                                  critical => $crit);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $temperature));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));
    
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemTempAmbient}}) {
        temperature($self, oid => $oid, oid_short => $oid_chassisSystemTempAmbient, value => $self->{results}->{$oid_chassisSystemTempAmbient}->{$oid},
            extra_instance => 'ambient');
    }
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemTempController}}) {
        temperature($self, oid => $oid, oid_short => $oid_chassisSystemTempController, value => $self->{results}->{$oid_chassisSystemTempController}->{$oid},
            extra_instance => 'controller');
    }
    foreach my $oid (keys %{$self->{results}->{$oid_arrayVimmEntry_temp}}) {
        temperature($self, oid => $oid, oid_short => $oid_arrayVimmEntry_temp, value => $self->{results}->{$oid_arrayVimmEntry_temp}->{$oid});
    }
}

1;
