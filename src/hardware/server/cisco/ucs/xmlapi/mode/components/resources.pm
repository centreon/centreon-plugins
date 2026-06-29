#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $VERSION = '1.0';
our @ISA     = ('Exporter');
our @EXPORT  = qw(%mapping_presence %mapping_operability %mapping_overall_status %mapping_drive_status $thresholds);

our %mapping_presence = (
    unknown        => 0,
    empty          => 1,
    equipped       => 2,
    missing        => 3,
    mismatch       => 4,
    'mismatch-hw'  => 5,
    'mismatch-sw'  => 6,
    accessibility  => 7,
    'not-supported'=> 8,
    degraded       => 9,
);

our %mapping_operability = (
    unknown                  => 0,
    operable                 => 1,
    inoperable               => 2,
    degraded                 => 3,
    poweredOff               => 4,
    powerProblem             => 5,
    removed                  => 6,
    voltageProblem           => 7,
    thermalProblem           => 8,
    performanceProblem       => 9,
    accessibilityProblem     => 10,
    identityUnestablishable  => 11,
    biosPostTimeout          => 12,
    disabled                 => 13,
    fabricConnProblem        => 14,
    fabricUnsupportedConn    => 15,
    config                   => 16,
    equipmentProblem         => 17,
    decomissioning           => 18,
    chassisLimitExceeded     => 19,
    'not-supported'          => 20,
    discovery                => 21,
    discoveryFailed          => 22,
    postFailure              => 23,
    upgradeProblem           => 24,
    peerCommProblem          => 25,
    autoUpgrade              => 26,
    linkActivateBlocked      => 27,
);

our %mapping_overall_status = (
    indeterminate         => 0,
    unassociated          => 1,
    ok                    => 2,
    discovery             => 3,
    config                => 4,
    unconfig              => 5,
    'power-off'           => 6,
    restart               => 7,
    maintenance           => 8,
    test                  => 9,
    'compute-mismatch'    => 10,
    'compute-failed'      => 11,
    degraded              => 12,
    'discovery-failed'    => 13,
    'config-failure'      => 14,
    'unconfig-failed'     => 15,
    'test-failed'         => 16,
    'maintenance-failed'  => 17,
    removed               => 18,
    disabled              => 19,
    inaccessible          => 20,
    'thermal-problem'     => 21,
    'power-problem'       => 22,
    'voltage-problem'     => 23,
    inoperable            => 24,
    decommissioning       => 25,
    'bios-restore'        => 26,
    'cmos-reset'          => 27,
    diagnostics           => 28,
    'diagnostic-failed'   => 29,
);

our %mapping_drive_status = (
    unknown         => 0,
    present         => 1,
    'in-use'        => 2,
    'broken'        => 3,
    rebuilding      => 4,
    'write-cache-good'   => 5,
    'pre-failure'   => 6,
    online          => 7,
    copyback        => 8,
    'bad-type'      => 9,
    predictive      => 10,
    'wait-ready'    => 11,
    'degraded-copy' => 12,
    foreign         => 13,
);

our $thresholds = {
    presence => [
        ['^unknown$',   'UNKNOWN'],
        ['^empty$',     'OK'],
        ['^equipped$',  'OK'],
        ['^missing$',   'WARNING'],
        ['^mismatch',   'WARNING'],
        ['^degraded$',  'WARNING'],
    ],
    operability => [
        ['^operable$',          'OK'],
        ['^poweredOff$',        'OK'],
        ['^autoUpgrade$',       'OK'],
        ['^discovery$',         'OK'],
        ['^config$',            'OK'],
        ['^maintenance$',       'OK'],
        ['^unassociated$',      'OK'],
        ['^unknown$',           'UNKNOWN'],
        ['^inoperable$',        'CRITICAL'],
        ['^degraded$',          'WARNING'],
        ['^.*[Pp]roblem.*$',    'CRITICAL'],
        ['^.*[Ff]ailed.*$',     'CRITICAL'],
        ['^.*[Tt]imeout.*$',    'WARNING'],
        ['^disabled$',          'WARNING'],
        ['^decomissioning$',    'WARNING'],
        ['^removed$',           'WARNING'],
        ['^.*$',                'CRITICAL'],
    ],
    overall_status => [
        ['^ok$',                'OK'],
        ['^unassociated$',      'OK'],
        ['^discovery$',         'OK'],
        ['^config$',            'OK'],
        ['^maintenance$',       'OK'],
        ['^test$',              'OK'],
        ['^restart$',           'OK'],
        ['^diagnostics$',       'OK'],
        ['^power-off$',         'OK'],
        ['^unconfig$',          'OK'],
        ['^indeterminate$',     'UNKNOWN'],
        ['^degraded$',          'WARNING'],
        ['^inaccessible$',      'WARNING'],
        ['^disabled$',          'WARNING'],
        ['^decommissioning$',   'WARNING'],
        ['^removed$',           'WARNING'],
        ['^bios-restore$',      'WARNING'],
        ['^cmos-reset$',        'WARNING'],
        ['^compute-mismatch$',  'WARNING'],
        ['^inoperable$',        'CRITICAL'],
        ['^.*-failed$',         'CRITICAL'],
        ['^.*-failure$',        'CRITICAL'],
        ['^.*-problem$',        'CRITICAL'],
        ['^.*-mismatch$',       'WARNING'],
        ['^compute-failed$',    'CRITICAL'],
        ['^.*$',                'CRITICAL'],
    ],
    drive_status => [
        ['^online$',        'OK'],
        ['^in-use$',        'OK'],
        ['^present$',       'OK'],
        ['^write-cache-good$', 'OK'],
        ['^wait-ready$',    'OK'],
        ['^rebuilding$',    'WARNING'],
        ['^copyback$',      'WARNING'],
        ['^predictive$',    'WARNING'],
        ['^pre-failure$',   'WARNING'],
        ['^degraded-copy$', 'WARNING'],
        ['^broken$',        'CRITICAL'],
        ['^bad-type$',      'CRITICAL'],
        ['^foreign$',       'WARNING'],
        ['^unknown$',       'UNKNOWN'],
        ['^.*$',            'CRITICAL'],
    ],
};

1;
