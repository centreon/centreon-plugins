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

package centreon::common::ibm::tapelibrary::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_operational;
our $map_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_operational $map_status);

$map_status = {
    1 => 'notinstalled',
    2 => 'ok',
    3 => 'notok',
};

$map_operational = {
    0 => 'unknown',
    1 => 'other',
    2 => 'ok',
    3 => 'degraded',
    4 => 'stressed',
    5 => 'predictiveFailure',
    6 => 'error',
    7 => 'non-RecoverableError',
    8 => 'starting',
    9 => 'stopping',
    10 => 'stopped',
    11 => 'inService',
    12 => 'noContact',
    13 => 'lostCommunication',
    14 => 'aborted',
    15 => 'dormant',
    16 => 'supportingEntityInError',
    17 => 'completed',
    18 => 'powerMode',
    19 => 'dMTFReserved',
    32768 => 'vendorReserved',
};

1;