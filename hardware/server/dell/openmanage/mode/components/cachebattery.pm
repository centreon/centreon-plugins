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

package hardware::server::dell::openmanage::mode::components::cachebattery;

use strict;
use warnings;

my %state = (
    0 => 'unknown', 
    1 => 'ready', 
    2 => 'failed', 
    6 => 'degraded',
    7 => 'reconditioning',
    9 => 'high',
    10 => 'powerLow',
    12 => 'charging',
    21 => 'missing',
    36 => 'learning',
);

my %componentStatus = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %learnState = (
    1 => 'failed',
    2 => 'active',
    4 => 'timedOut',
    8 => 'requested',
    16 => 'idle',
    32 => 'due',
);

my %predictedCapacity = (
    1 => 'failed',
    2 => 'ready',
    4 => 'unknown',
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking cache batteries");
    $self->{components}->{cachebattery} = {name => 'cache batteries', total => 0};
    return if ($self->check_exclude('cachebattery'));
   
    my $oid_batteryState = '.1.3.6.1.4.1.674.10893.1.20.130.15.1.4';
    my $oid_batteryComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.15.1.6';
    my $oid_batteryPredictedCapicity = '.1.3.6.1.4.1.674.10893.1.20.130.15.1.10';
    my $oid_batteryLearnState = '.1.3.6.1.4.1.674.10893.1.20.130.15.1.12';

    my $result = $self->{snmp}->get_table(oid => $oid_batteryState);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_batteryComponentStatus, $oid_batteryPredictedCapicity, $oid_batteryLearnState],
                                          instances => [keys %$result],
                                          instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $battery_Index = $1;
        
        my $battery_State = $result->{$key};
        my $battery_ComponentStatus = $result2->{$oid_batteryComponentStatus . '.' . $battery_Index};
        my $battery_PredictedCapacity = $result2->{$oid_batteryPredictedCapicity . '.' . $battery_Index};
        my $battery_LearnState = $result2->{$oid_batteryLearnState . '.' . $battery_Index};

        $self->{components}->{cachebattery}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("cache battery %d status is %s, state is %s, learn state is %s, predicted capacity is %s.",
                                    $battery_Index, ${$componentStatus{$battery_ComponentStatus}}[0], $state{$battery_State},
                                    $learnState{$battery_LearnState}, $predictedCapacity{$battery_PredictedCapacity}
                                    ));
        if ($battery_ComponentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$componentStatus{$battery_ComponentStatus}}[1],
                                        short_msg => sprintf("cache battery %d status is %s",
                                           $battery_Index, ${$componentStatus{$battery_ComponentStatus}}[0]));
        }

    }
}

1;
