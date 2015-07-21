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

package hardware::server::cisco::ucs::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $thresholds;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($thresholds);

$thresholds = {
    presence => {
        0 => ['unknown', 'UNKNOWN'], 
        1 => ['empty', 'OK'], 
        10 => ['equipped', 'OK'], 
        11 => ['missing', 'WARNING'],
        12 => ['mismatch', 'WARNING'],
        13 => ['equippedNotPrimary', 'OK'],
        20 => ['equippedIdentityUnestablishable', 'WARNING'],
        21 => ['mismatchIdentityUnestablishable', 'WARNING'],
        30 => ['inaccessible', 'UNKNOWN'],
        40 => ['unauthorized', 'UNKNOWN'],
        100 => ['notSupported', 'WARNING'],
    },
    operability => {
        0 => ['unknown', 'UNKNOWN'], 
        1 => ['operable', 'OK'], 
        2 => ['inoperable', 'CRITICAL'], 
        3 => ['degraded', 'WARNING'],
        4 => ['poweredOff', 'WARNING'],
        5 => ['powerProblem', 'CRITICAL'],
        6 => ['removed', 'WARNING'],
        7 => ['voltageProblem', 'CRITICAL'],
        8 => ['thermalProblem', 'CRITICAL'],
        9 => ['performanceProblem', 'CRITICAL'],
        10 => ['accessibilityProblem', 'WARNING'],
        11 => ['identityUnestablishable', 'WARNING'],
        12 => ['biosPostTimeout', 'WARNING'],
        13 => ['disabled', 'OK'],
        51 => ['fabricConnProblem', 'WARNING'],
        52 => ['fabricUnsupportedConn', 'WARNING'],
        81 => ['config', 'OK'],
        82 => ['equipmentProblem', 'CRITICAL'],
        83 => ['decomissioning', 'WARNING'],
        84 => ['chassisLimitExceeded', 'WARNING'],
        100 => ['notSupported', 'WARNING'],
        101 => ['discovery', 'OK'],
        102 => ['discoveryFailed', 'WARNING'],
        104 => ['postFailure', 'WARNING'],
        105 => ['upgradeProblem', 'WARNING'],
        106 => ['peerCommProblem', 'WARNING'],
        107 => ['autoUpgrade', 'OK'],
    },
    overall_status => {
        0 => ['indeterminate', 'UNKNOWN'],
        1 => ['unassociated', 'OK'],
        10 => ['ok', 'OK'],
        11 => ['discovery', 'OK'],
        12 => ['config', 'OK'],
        13 => ['unconfig', 'OK'],
        14 => ['power-off', 'WARNING'],
        15 => ['restart', 'WARNING'],
        20 => ['maintenance', 'OK'],
        21 => ['test', 'OK'],
        29 => ['compute-mismatch', 'WARNING'],
        30 => ['compute-failed', 'WARNING'],
        31 => ['degraded', 'WARNING'],
        32 => ['discovery-failed', 'WARNING'],
        33 => ['config-failure', 'WARNING'],
        34 => ['unconfig-failed', 'WARNING'],
        35 => ['test-failed', 'WARNING'],
        36 => ['maintenance-failed', 'WARNING'],
        40 => ['removed', 'WARNING'],
        41 => ['disabled', 'OK'],
        50 => ['inaccessible', 'WARNING'],
        60 => ['thermal-problem', 'CRITICAL'],
        61 => ['power-problem', 'CRITICAL'],
        62 => ['voltage-problem', 'CRITICAL'],
        63 => ['inoperable', 'CRITICAL'],
        101 => ['decommissioning', 'WARNING'],
        201 => ['bios-restore', 'WARNING'],
        202 => ['cmos-reset', 'WARNING'],
        203 => ['diagnostics', 'OK'],
        204 => ['diagnostic-failed', 'WARNING'],
    },
};

1;
