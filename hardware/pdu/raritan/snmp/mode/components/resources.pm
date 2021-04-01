#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::pdu::raritan::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $thresholds;
our $mapping;
our %raritan_type;
our %map_type;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($thresholds $mapping %raritan_type %map_type);

my %map_units = (
    -1 => { unit => '' }, # none
    0 => { unit => 'other', nunit => 'count' },
    1 => { unit => 'V', nunit => 'volt' }, # volt,
    2 => { unit => 'A', nunit => 'ampere' }, # amp,
    3 => { unit => 'W', nunit => 'watt' }, # watt
    4 => { unit => 'voltamp' },
    5 => { unit => 'wattHour' },
    6 => { unit => 'voltampHour' },
    7 => { unit => 'C', nunit => 'celsius' }, # degreeC
    8 => { unit => 'Hz', nunit => 'hertz' }, # hertz
    9 => { unit => '%', nunit => 'percentage' }, # percent
    10 => { unit => 'meterpersec' },
    11 => { unit => 'pascal' },
    12 => { unit => 'psi' },
    13 => { unit => 'g' },
    14 => { unit => 'degreeF', nunit => 'fahrenheit' },
    15 => { unit => 'feet' },
    16 => { unit => 'inches' },
    17 => { unit => 'cm' },
    18 => { unit => 'meters' },
    19 => { unit => 'rpm' },
    20 => { unit => 'degrees' },
    21 => { unit => 'lux' },
);

my %map_state = (
    -1 => 'unavailable', 0 => 'open', 1 => 'closed', 2 => 'belowLowerCritical',
    3 => 'belowLowerWarning', 4 => 'normal', 5 => 'aboveUpperWarning', 6 => 'aboveUpperCritical',
    7 => 'on', 8 => 'off', 9 => 'detected', 10 => 'notDetected', 11 => 'alarmed',
    12 => 'ok', 14 => 'fail', 15 => 'yes', 16 => 'no', 17 => 'standby',
    18 => 'one', 19 => 'two', 20 => 'inSync', 21 => 'outOfSync',
    22 => 'i1OpenFault', 23 => 'i1ShortFault',
    24 => 'i2OpenFault', 25 => 'i2ShortFault', 26 => 'fault',
    27 => 'warning', 28 => 'critical',
    29 => 'selfTest',
);

$mapping = {
    inlet_label => {
        Label   => { oid => '.1.3.6.1.4.1.13742.6.3.3.3.1.2' }, # inletLabel
    },
    inlet => {
        Unit    => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.6', map => \%map_units }, # inletSensorUnits
        Decimal => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.7' }, # inletSensorDecimalDigits
        EnabledThresholds => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.25' }, # inletSensorEnabledThresholds
        LowerCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.21' }, # inletSensorLowerCriticalThreshold
        LowerWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.22' }, # inletSensorLowerWarningThreshold
        UpperCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.23' }, # inletSensorUpperCriticalThreshold
        UpperWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.3.4.1.24' }, # inletSensorUpperWarningThreshold
        State   => { oid => '.1.3.6.1.4.1.13742.6.5.2.3.1.3', map => \%map_state }, # measurementsInletSensorState
        Value => { oid => '.1.3.6.1.4.1.13742.6.5.2.3.1.4' }, # measurementsInletSensorValue
    },
    outlet_label => {
        Label   => { oid => '.1.3.6.1.4.1.13742.6.3.5.3.1.2' }, # outletLabel
    },
    outlet => {
        Unit    => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.6', map => \%map_units }, # outletSensorUnits
        Decimal => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.7' }, # outletSensorDecimalDigits
        EnabledThresholds => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.25' }, # outletSensorEnabledThresholds
        LowerCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.21' }, # outletSensorLowerCriticalThreshold
        LowerWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.22' }, # outletSensorLowerWarningThreshold
        UpperCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.23' }, # outletSensorUpperCriticalThreshold
        UpperWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.5.4.1.24' }, # outletSensorUpperWarningThreshold
        State   => { oid => '.1.3.6.1.4.1.13742.6.5.4.3.1.3', map => \%map_state }, # measurementsOutletSensorState
        Value => { oid => '.1.3.6.1.4.1.13742.6.5.4.3.1.4' }, # measurementsOutletSensorValue
    },
    ocprot_label => {
        Label   => { oid => '.1.3.6.1.4.1.13742.6.3.4.3.1.2' }, # overCurrentProtectorLabel
    },
    ocprot => {
        Unit    => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.6', map => \%map_units }, # overCurrentProtectorSensorUnits
        Decimal => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.7' }, # overCurrentProtectorSensorDecimalDigits
        EnabledThresholds => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.25' }, # overCurrentProtectorSensorEnabledThresholds
        LowerCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.21' }, # overCurrentProtectorSensorLowerCriticalThreshold
        LowerWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.22' }, # overCurrentProtectorSensorLowerWarningThreshold
        UpperCriticalThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.23' }, # overCurrentProtectorSensorUpperCriticalThreshold
        UpperWarningThreshold => { oid => '.1.3.6.1.4.1.13742.6.3.4.4.1.24' }, # overCurrentProtectorSensorUpperWarningThreshold
        State   => { oid => '.1.3.6.1.4.1.13742.6.5.3.3.1.3', map => \%map_state }, # measurementsOverCurrentProtectorSensorState
        Value => { oid => '.1.3.6.1.4.1.13742.6.5.3.3.1.4' }, # measurementsOverCurrentProtectorSensorValue
    },
};

%raritan_type = (
    rmsCurrent => 1, peakCurrent => 2, unbalancedCurrent => 3,
    rmsVoltage => 4, activePower => 5, apparentPower => 6,
    powerFactor => 7, activeEnergy => 8, apparentEnergy => 9,
    temperature => 10, humidity => 11, airFlow => 12,
    airPressure => 13, onOff => 14, trip => 15,
    vibration => 16, waterDetection => 17, smokeDetection => 18,
    binary => 19, contact => 20, fanSpeed => 21,
    surgeProtectorStatus => 22, frequency => 23, phaseAngle => 24,
    rmsVoltageLN => 25, residualCurrent => 26, rcmState => 27,
    other => 30, none => 31, powerQuality => 32,
    overloadStatus => 33, overheatStatus => 34, fanStatus => 37,
    inletPhaseSyncAngle => 38, inletPhaseSync => 39, operatingState => 40,
    activeInlet => 41, illuminance => 42, doorContact => 43,
    tamperDetection => 44, motionDetection => 45, i1smpsStatus => 46,
    i2smpsStatus => 47, switchStatus => 48,
);

%map_type = (
    1 => 'numeric',
    2 => 'numeric',
    3 => 'numeric',
    4 => 'numeric',
    5 => 'numeric',
    6 => 'numeric',
    7 => 'numeric',
    8 => 'numeric',
    9 => 'numeric',
    10 => 'numeric',
    11 => 'numeric',
    12 => 'numeric',
    13 => 'numeric',
    14 => 'onoff',
    15 => 'contact',
    16 => 'alarm',
    17 => 'alarm',
    18 => 'alarm',
    19 => 'alarm',
    20 => 'alarm',
    21 => 'numeric',
    22 => 'fault',
    23 => 'numeric',
    24 => 'numeric',
    25 => 'numeric',
    26 => 'numeric',
    27 => 'alarm',
    30 => 'numeric',
    31 => 'numeric',
    32 => 'powerQuality',
    33 => 'fault',
    34 => 'fault',
    37 => 'fault',
    38 => 'numeric',
    39 => 'inletPhaseSync',
    40 => 'operatingState',
    41 => 'activeInlet',
    42 => 'numeric',
    43 => 'contact',
    44 => 'alarm',
    45 => 'motionDetection',
    46 => 'fault',
    47 => 'fault',
    48 => 'switchStatus',
);

$thresholds = {
    numeric => [
        ['unavailable', 'UNKNOWN'],
        ['normal', 'OK'],
        ['belowLowerCritical', 'CRITICAL'],
        ['belowLowerWarning', 'WARNING'],
        ['aboveUpperWarning', 'WARNING'],
        ['aboveUpperCritical', 'CRITICAL'],
    ],
    onoff => [
        ['unavailable', 'UNKNOWN'],
        ['on', 'OK'],
        ['off', 'OK'],
    ],
    contact => [
        ['unavailable', 'UNKNOWN'],
        ['open', 'OK'],
        ['closed', 'OK'],
    ],
    alarm => [
        ['unavailable', 'UNKNOWN'],
        ['normal', 'OK'],
        ['alarmed', 'CRITICAL'],
        ['selfTest', 'OK'],
        ['fail', 'CRITICAL'],
    ],
    fault => [
        ['unavailable', 'UNKNOWN'],
        ['ok', 'OK'],
        ['fault', 'CRITICAL'],
    ],
    powerQuality => [
        ['unavailable', 'UNKNOWN'],
        ['normal', 'OK'],
        ['warning', 'WARNING'],
        ['critical', 'CRITICAL'],
    ],
    inletPhaseSync => [
        ['unavailable', 'UNKNOWN'],
        ['inSync', 'OK'],
        ['outOfSync', 'CRITICAL'],
    ],    
    operatingState => [
        ['unavailable', 'UNKNOWN'],
        ['normal', 'OK'],
        ['standby', 'OK'],
        ['off', 'CRITICAL'],
    ],
    activeInlet => [
        ['unavailable', 'UNKNOWN'],
        ['one', 'OK'],
        ['two', 'OK'],
        ['none', 'WARNING'],
    ],
    motionDetection => [
        ['unavailable', 'UNKNOWN'],
    ],
    switchStatus => [
        ['unavailable', 'UNKNOWN'],
        ['ok', 'OK'],
        ['i1OpenFault', 'WARNING'],
        ['i1ShortFault', 'WARNING'],
        ['i2OpenFault', 'WARNING'],
        ['i2ShortFault', 'WARNING'],
    ],
};

1;
