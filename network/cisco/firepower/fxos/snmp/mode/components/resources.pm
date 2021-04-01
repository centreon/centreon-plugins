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

package network::cisco::firepower::fxos::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_operability;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_operability);

$map_operability = {
    0 => 'unknown', 1 => 'operable',
    2 => 'inoperable', 3 => 'degraded',
    4 => 'poweredOff', 5 => 'powerProblem',
    6 => 'removed', 7 => 'voltageProblem',
    8 => 'thermalProblem', 9 => 'performanceProblem',
    10 => 'accessibilityProblem', 11 => 'identityUnestablishable',
    12 => 'biosPostTimeout', 13 => 'disabled',
    14 => 'malformedFru', 51 => 'fabricConnProblem',
    52 => 'fabricUnsupportedConn', 81 => 'config',
    82 => 'equipmentProblem', 83 => 'decomissioning',
    84 => 'chassisLimitExceeded', 100 => 'notSupported',
    101 => 'discovery', 102 => 'discoveryFailed',
    103 => 'identify', 104 => 'postFailure',
    105 => 'upgradeProblem', 106 => 'peerCommProblem',
    107 => 'autoUpgrade', 108 => 'linkActivateBlocked'
};

1;
