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

package hardware::server::hpproliant::mode::components::temperature;

use strict;
use warnings;

my %location_map = (
    1 => "other",
    2 => "unknown",
    3 => "system",
    4 => "systemBoard",
    5 => "ioBoard",
    6 => "cpu",
    7 => "memory",
    8 => "storage",
    9 => "removableMedia",
    10 => "powerSupply", 
    11 => "ambient",
    12 => "chassis",
    13 => "bridgeCard",
);

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
);

sub check {
    my ($self) = @_;
    # In MIB 'CPQSTDEQ-MIB.mib'
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));
    
    my $oid_cpqHeTemperatureEntry = '.1.3.6.1.4.1.232.6.2.6.8.1';
    my $oid_cpqHeTemperatureCondition = '.1.3.6.1.4.1.232.6.2.6.8.1.6';
    my $oid_cpqHeTemperatureLocale = '.1.3.6.1.4.1.232.6.2.6.8.1.3';
    my $oid_cpqHeTemperatureCelsius = '.1.3.6.1.4.1.232.6.2.6.8.1.4';
    my $oid_cpqHeTemperatureThreshold = '.1.3.6.1.4.1.232.6.2.6.8.1.5';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqHeTemperatureEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        # work when we have condition
        next if ($key !~ /^$oid_cpqHeTemperatureCondition/);
        # Chassis + index
        $key =~ /(\d+)\.(\d+)$/;
        my $temp_chassis = $1;
        my $temp_index = $2;
        my $instance = $temp_chassis . "." . $temp_index;
    
        my $temp_condition = $result->{$key};
        my $temp_current = $result->{$oid_cpqHeTemperatureCelsius . '.' . $instance};
        my $temp_threshold = $result->{$oid_cpqHeTemperatureThreshold . '.' . $instance};
        my $temp_locale = $result->{$oid_cpqHeTemperatureLocale . '.' . $instance};
        
        next if ($self->check_exclude(section => 'temperature', instance => $temp_chassis . '.' . $temp_index));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("%s %s temperature is %dC (%d max) (status is %s).", 
                                    $temp_index, $location_map{$temp_locale}, $temp_current,
                                    $temp_threshold,
                                    ${$conditions{$temp_condition}}[0]));
        if (${$conditions{$temp_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$temp_condition}}[1],
                                        short_msg => sprintf("temperature %d %s status is %s", 
                                            $temp_index, $location_map{$temp_locale}, ${$conditions{$temp_condition}}[0]));
        }
        
        $self->{output}->perfdata_add(label => "temp_" . $temp_index . "_" . $location_map{$temp_locale}, unit => 'C',
                                      value => $temp_current,
                                      critical => (($temp_threshold != -1) ? $temp_threshold : -1));
    }
}

1;