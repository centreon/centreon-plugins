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

package network::redback::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'RBN-ENVMON.mib'
my $mapping = {
    rbnEntityTempDescr => { oid => '.1.3.6.1.4.1.2352.2.4.1.6.1.2' },
    rbnEntityTempCurrent => { oid => '.1.3.6.1.4.1.2352.2.4.1.6.1.3' },
};
my $oid_rbnEntityTempSensorEntry = '.1.3.6.1.4.1.2352.2.4.1.6.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_rbnEntityTempSensorEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rbnEntityTempSensorEntry}})) {
        next if ($oid !~ /^$mapping->{rbnEntityTempCurrent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rbnEntityTempSensorEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("'%s' temperature is %dC [instance: %s].", 
                                    $result->{rbnEntityTempDescr}, $result->{rbnEntityTempCurrent},
                                    $instance));
     
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{rbnEntityTempCurrent});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %sC", $result->{rbnEntityTempDescr}, $result->{rbnEntityTempCurrent}));
        }
        $self->{output}->perfdata_add(label => "temp_" . $instance, unit => 'C',
                                      value => $result->{rbnEntityTempCurrent},
                                      warning => $warn,
                                      critical => $crit);
    }
}

1;