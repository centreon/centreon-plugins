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

package hardware::server::cisco::ucs::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $thresholds;
our %mapping_presence;
our %mapping_operability;
our %mapping_overall_status;
our %mapping_drive_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($thresholds %mapping_presence %mapping_operability %mapping_overall_status %mapping_drive_status);

%mapping_drive_status = (
    0 => 'unknown',
    1 => 'online',
    2 => 'unconfiguredGood',
    3 => 'globalHotSpare',
    4 => 'dedicatedHotSpare',
    5 => 'jbod',
    6 => 'offline',
    7 => 'rebuilding',
    8 => 'copyback',
    9 => 'failed',
    10 => 'unconfiguredBad',
    11 => 'predictiveFailure',
    12 => 'disabledForRemoval',
    13 => 'foreignConfiguration',
);
%mapping_presence = (
    0 => 'unknown', 
    1 => 'empty', 
    10 => 'equipped', 
    11 => 'missing',
    12 => 'mismatch',
    13 => 'equippedNotPrimary',
    20 => 'equippedIdentityUnestablishable',
    21 => 'mismatchIdentityUnestablishable',
    30 => 'inaccessible',
    40 => 'unauthorized',
    100 => 'notSupported',
);
%mapping_operability = (
    0 => 'unknown',
    1 => 'operable',
    2 => 'inoperable',
    3 => 'degraded',
    4 => 'poweredOff',
    5 => 'powerProblem',
    6 => 'removed',
    7 => 'voltageProblem',
    8 => 'thermalProblem',
    9 => 'performanceProblem',
    10 => 'accessibilityProblem',
    11 => 'identityUnestablishable',
    12 => 'biosPostTimeout',
    13 => 'disabled',
    51 => 'fabricConnProblem',
    52 => 'fabricUnsupportedConn',
    81 => 'config',
    82 => 'equipmentProblem',
    83 => 'decomissioning',
    84 => 'chassisLimitExceeded',
    100 => 'notSupported',
    101 => 'discovery',
    102 => 'discoveryFailed',
    104 => 'postFailure',
    105 => 'upgradeProblem',
    106 => 'peerCommProblem',
    107 => 'autoUpgrade',
    108 => 'linkActivateBlocked',
);
%mapping_overall_status = (
    0 => 'indeterminate',
    1 => 'unassociated',
    10 => 'ok',
    11 => 'discovery',
    12 => 'config',
    13 => 'unconfig',
    14 => 'power-off',
    15 => 'restart',
    20 => 'maintenance',
    21 => 'test',
    29 => 'compute-mismatch',
    30 => 'compute-failed',
    31 => 'degraded',
    32 => 'discovery-failed',
    33 => 'config-failure',
    34 => 'unconfig-failed',
    35 => 'test-failed',
    36 => 'maintenance-failed',
    40 => 'removed',
    41 => 'disabled',
    50 => 'inaccessible',
    60 => 'thermal-problem',
    61 => 'power-problem',
    62 => 'voltage-problem',
    63 => 'inoperable',
    101 => 'decommissioning',
    201 => 'bios-restore',
    202 => 'cmos-reset',
    203 => 'diagnostics',
    204 => 'diagnostic-failed',
);

$thresholds = {
    'default.drivestatus' => [
        ['unknown', 'UNKNOWN'], 
        ['online', 'OK'],
        ['unconfiguredGood', 'OK'], 
        ['globalHotSpare', 'OK'], 
        ['dedicatedHotSpare', 'OK'], 
        ['jbod', 'OK'], 
        ['offline', 'OK'], 
        ['rebuilding', 'WARNING'], 
        ['copyback', 'OK'], 
        ['failed', 'CRITICAL'], 
        ['unconfiguredBad', 'CRITICAL'], 
        ['predictiveFailure', 'WARNING'], 
        ['disabledForRemoval', 'OK'],
        ['foreignConfiguration', 'OK'], 
    ],
    'default.presence' => [
        ['unknown', 'UNKNOWN'], 
        ['empty', 'OK'], 
        ['equipped', 'OK'], 
        ['missing', 'WARNING'],
        ['mismatch', 'WARNING'],
        ['equippedNotPrimary', 'OK'],
        ['equippedIdentityUnestablishable', 'WARNING'],
        ['mismatchIdentityUnestablishable', 'WARNING'],
        ['inaccessible', 'UNKNOWN'],
        ['unauthorized', 'UNKNOWN'],
        ['notSupported', 'WARNING'],
    ],
    'default.operability' => [
        ['unknown', 'UNKNOWN'], 
        ['operable', 'OK'], 
        ['inoperable', 'CRITICAL'], 
        ['degraded', 'WARNING'],
        ['poweredOff', 'WARNING'],
        ['powerProblem', 'CRITICAL'],
        ['removed', 'WARNING'],
        ['voltageProblem', 'CRITICAL'],
        ['thermalProblem', 'CRITICAL'],
        ['performanceProblem', 'CRITICAL'],
        ['accessibilityProblem', 'WARNING'],
        ['identityUnestablishable', 'WARNING'],
        ['biosPostTimeout', 'WARNING'],
        ['disabled', 'OK'],
        ['fabricConnProblem', 'WARNING'],
        ['fabricUnsupportedConn', 'WARNING'],
        ['config', 'OK'],
        ['equipmentProblem', 'CRITICAL'],
        ['decomissioning', 'WARNING'],
        ['chassisLimitExceeded', 'WARNING'],
        ['notSupported', 'WARNING'],
        ['discovery', 'OK'],
        ['discoveryFailed', 'WARNING'],
        ['postFailure', 'WARNING'],
        ['upgradeProblem', 'WARNING'],
        ['peerCommProblem', 'WARNING'],
        ['autoUpgrade', 'OK'],
    ],
    'default.overall_status' => [
        ['indeterminate', 'UNKNOWN'],
        ['unassociated', 'OK'],
        ['ok', 'OK'],
        ['discovery', 'OK'],
        ['config', 'OK'],
        ['unconfig', 'OK'],
        ['power-off', 'WARNING'],
        ['restart', 'WARNING'],
        ['maintenance', 'OK'],
        ['test', 'OK'],
        ['compute-mismatch', 'WARNING'],
        ['compute-failed', 'WARNING'],
        ['degraded', 'WARNING'],
        ['discovery-failed', 'WARNING'],
        ['config-failure', 'WARNING'],
        ['unconfig-failed', 'WARNING'],
        ['test-failed', 'WARNING'],
        ['maintenance-failed', 'WARNING'],
        ['removed', 'WARNING'],
        ['disabled', 'OK'],
        ['inaccessible', 'WARNING'],
        ['thermal-problem', 'CRITICAL'],
        ['power-problem', 'CRITICAL'],
        ['voltage-problem', 'CRITICAL'],
        ['inoperable', 'CRITICAL'],
        ['decommissioning', 'WARNING'],
        ['bios-restore', 'WARNING'],
        ['cmos-reset', 'WARNING'],
        ['diagnostics', 'OK'],
        ['diagnostic-failed', 'WARNING'],
    ],
};

1;
