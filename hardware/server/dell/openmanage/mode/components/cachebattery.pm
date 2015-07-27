#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
