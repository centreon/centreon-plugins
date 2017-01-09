#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::sun::mgmt_cards::components::showenvironment::resources;

use strict;
use warnings;
use Exporter;

our $thresholds;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($thresholds);

$thresholds = {
    temperature => [
        ['^(?!(OK)$)', 'CRITICAL'],
        ['^OK$', 'OK'],
    ],
    si => [
        ['^(?!(OFF)$)', 'CRITICAL'],
        ['^OFF$', 'OK'],
    ],
    disk => [
        ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
        ['^OK|NOT PRESENT$', 'OK'],
    ],
    fan => [
        ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
        ['^OK|NOT PRESENT$', 'OK'],
    ],
    voltage => [
        ['^(?!(OK)$)', 'CRITICAL'],
        ['^OK$', 'OK'],
    ],
    psu => [
        ['^(?!(OK|NOT PRESENT)$)', 'CRITICAL'],
        ['^OK|NOT PRESENT$', 'OK'],
    ],
    sensors => [
        ['^(?!(OK)$)', 'CRITICAL'],
        ['^OK$', 'OK'],
    ],
};

1;