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

package hardware::server::dell::cmc::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_capable = (
    1 => 'absent', 
    2 => 'none', 
    3 => 'basic', 
);

# In MIB 'DELL-RAC-MIB'
my $mapping = {
    drsPSULocation => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.3' },
    drsPSUMonitoringCapable => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.4', map => \%map_psu_capable },
    drsPSUVoltsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.5', section => 'voltage', label => 'voltage', unit => 'V' },
    drsPSUAmpsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.6', section => 'current', label => 'current', unit => 'A' },
    drsPSUWattsReading => { oid => '.1.3.6.1.4.1.674.10892.2.4.2.1.7', section => 'power', label => 'power', unit => 'W' },
};
my $oid_drsCMCPSUTableEntry = '.1.3.6.1.4.1.674.10892.2.4.2.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_drsCMCPSUTableEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_drsCMCPSUTableEntry}})) {
        next if ($oid !~ /^$mapping->{drsPSUMonitoringCapable}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_drsCMCPSUTableEntry}, instance => $instance);

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($result->{drsPSUMonitoringCapable} !~ /basic/i);
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s': power %s W, current %s A, voltage %s V [instance: %s].",
                                    $result->{drsPSULocation}, $result->{drsPSUWattsReading}, $result->{drsPSUAmpsReading}, $result->{drsPSUVoltsReading},
                                    $instance
                                    ));
        foreach my $probe (('drsPSUVoltsReading', 'drsPSUAmpsReading', 'drsPSUWattsReading')) {
            next if (!defined($result->{$probe}));
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.' . $mapping->{$probe}->{section}, instance => $instance, value => $result->{$probe});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' %s is %s%s", $result->{drsPSULocation}, 
                                                                 $mapping->{$probe}->{section}, $result->{$probe}, $mapping->{$probe}->{unit}));
            }
            $self->{output}->perfdata_add(label => 'psu_' . $mapping->{$probe}->{label} . '_' . $instance, unit => $mapping->{$probe}->{unit},
                                          value => $result->{$probe},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;