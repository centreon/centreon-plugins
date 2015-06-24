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

package hardware::server::dell::cmc::snmp::mode::components::chassis;

use strict;
use warnings;

# In MIB 'DELL-RAC-MIB'
my $mapping = {
    drsWattsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.1.1.13', section => 'power', label => 'power', unit => 'W' },
    drsAmpsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.1.1.14', section => 'current', label => 'current', unit => 'A' },
};
my $oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry = '.1.3.6.1.4.1.674.10892.2.4.1.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'chassis'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry}})) {
        next if ($oid !~ /^$mapping->{drsWattsReading}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_drsCMCPowerTableEntrydrsCMCPowerTableEntry}, instance => $instance);

        next if ($self->check_exclude(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Chassis '%s': power %s W, current %s A [instance: %s].",
                                    $instance, $result->{drsWattsReading}, $result->{drsAmpsReading},
                                    $instance
                                    ));
        foreach my $probe (('drsWattsReading', 'drsAmpsReading')) {
            next if (!defined($result->{$probe}));
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'chassis.' . $mapping->{$probe}->{section}, instance => $instance, value => $result->{$probe});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Chassis '%s' %s is %s%s", $instance, 
                                                                 $mapping->{$probe}->{section}, $result->{$probe}, $mapping->{$probe}->{unit}));
            }
            $self->{output}->perfdata_add(label => 'chassis_' . $mapping->{$probe}->{label} . '_' . $instance, unit => $mapping->{$probe}->{unit},
                                          value => $result->{$probe},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;