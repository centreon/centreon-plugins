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

package network::nortel::standard::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our ($map_comp_status, $map_fan_status, $map_psu_status, $map_card_status, $map_led_status);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_comp_status $map_fan_status $map_psu_status $map_card_status $map_led_status);

$map_fan_status = {
    1 => 'unknown',
    2 => 'up',
    3 => 'down',
};

$map_psu_status = {
    1 => 'unknown',
    2 => 'empty',
    3 => 'up',
    4 => 'down',
};

$map_card_status = {
    1 => 'up',
    2 => 'down',
    3 => 'testing',
    4 => 'unknown',
    5 => 'dormant',
};

$map_comp_status = {
    1 => 'other',
    2 => 'notAvail',
    3 => 'removed',
    4 => 'disabled',
    5 => 'normal',
    6 => 'resetInProg',
    7 => 'testing',
    8 => 'warning',
    9 => 'nonFatalErr',
    10 => 'fatalErr',
    11 => 'notConfig',
    12 => 'obsoleted',
};

$map_led_status = {
    1 => 'unknown',
    2 => 'greenSteady',
    3 => 'greenBlinking',
    4 => 'amberSteady',
    5 => 'amberBlinking',
    6 => 'greenamberBlinking',
    7 => 'off'
};

1;
