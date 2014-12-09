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

package storage::emc::DataDomain::mode::components::battery;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_battery_status = ();
my ($oid_nvramBatteryStatus, $oid_nvramBatteryCharge);
my $oid_nvramBatteryEntry = '.1.3.6.1.4.1.19746.1.2.3.1.1';

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nvram batteries");
    $self->{components}->{battery} = {name => 'nvram batteries', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'battery'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_nvramBatteryStatus = '.1.3.6.1.4.1.19746.1.2.3.1.1.3';
        $oid_nvramBatteryCharge = '.1.3.6.1.4.1.19746.1.2.3.1.1.4';
        %map_battery_status = (0 => 'ok', 1 => 'disabled', 2 => 'discharged', 4 => 'softdisabled');
    } else {
        $oid_nvramBatteryStatus = '.1.3.6.1.4.1.19746.1.2.3.1.1.2';
        $oid_nvramBatteryCharge = '.1.3.6.1.4.1.19746.1.2.3.1.1.3';
        %map_battery_status =  (1 => 'ok', 2 => 'disabled', 3 => 'discharged', 4 => 'unknown', 
                                5 => 'softdisabled');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_nvramBatteryEntry}}) {
        next if ($oid !~ /^$oid_nvramBatteryStatus\.(.*)$/);
        my $instance = $1;
        my $batt_status = defined($map_battery_status{$self->{results}->{$oid_nvramBatteryEntry}->{$oid}}) ?
                            $map_battery_status{$self->{results}->{$oid_nvramBatteryEntry}->{$oid}} : 'unknown';
        my $batt_value = $self->{results}->{$oid_nvramBatteryEntry}->{$oid_nvramBatteryCharge . '.' . $instance};

        next if ($self->check_exclude(section => 'battery', instance => $instance));
        next if ($batt_status =~ /disabled/i && 
                 $self->absent_problem(section => 'battery', instance => $instance));
        
        $self->{components}->{battery}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Nvram battery '%s' status is '%s'",
                                    $instance, $batt_status));
        my $exit = $self->get_severity(section => 'battery', value => $batt_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Nvram battery '%s' status is '%s'", $instance, $batt_status));
        }

        if (defined($batt_value) && $batt_value =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'battery', instance => $instance, value => $batt_value);
            $self->{output}->output_add(long_msg => sprintf("Nvram battery '%s' charge is %s %%", $instance, $batt_value));
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Nvram battery '%s' charge is %s %%", $instance, $batt_value));
            }
            $self->{output}->perfdata_add(label => 'nvram_battery_' . $instance, unit => '%', 
                                          value => $batt_value,
                                          warning => $warn,
                                          critical => $crit,
                                          min => 0, max => 100
                                          );
        }
    }
}

1;