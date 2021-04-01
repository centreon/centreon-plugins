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

package hardware::server::dell::idrac::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %map_state;
our %map_status;
our %map_probe_status;
our %map_enclosure_state;
our %map_amperage_type;
our %map_pdisk_state;
our %map_pdisk_smartstate;
our %map_vdisk_state;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    %map_probe_status %map_enclosure_state %map_state
    %map_status %map_amperage_type %map_pdisk_state
    %map_pdisk_smartstate %map_vdisk_state
);

%map_pdisk_smartstate = (
    0 => 'off',
    1 => 'on'
);

%map_probe_status = (
    1 => 'other', 
    2 => 'unknown', 
    3 => 'ok', 
    4 => 'nonCriticalUpper', 
    5 => 'criticalUpper', 
    6 => 'nonRecoverableUpper', 
    7 => 'nonCriticalLower', 
    8 => 'criticalLower', 
    9 => 'nonRecoverableLower', 
    10 => 'failed'
);

%map_status = (
    1 => 'other', 
    2 => 'unknown', 
    3 => 'ok', 
    4 => 'nonCritical', 
    5 => 'critical', 
    6 => 'nonRecoverable'
);

%map_state = (
    1 => 'unknown', 
    2 => 'enabled', 
    4 => 'notReady', 
    6 => 'enabledAndNotReady'
);

%map_enclosure_state = (
    1 => 'unknown',
    2 => 'ready',
    3 => 'failed',
    4 => 'missing',
    5 => 'degraded'
);

%map_pdisk_state = (
    1 => 'unknown',
    2 => 'ready',
    3 => 'online',
    4 => 'foreign',
    5 => 'offline',
    6 => 'blocked',
    7 => 'failed',
    8 => 'non-raid',
    9 => 'removed',
    10 => 'readonly'
);

%map_vdisk_state = (
    1 => 'unknown',
    2 => 'online',
    3 => 'failed',
    4 => 'degraded'
);

%map_amperage_type = (
    1 => 'amperageProbeTypeIsOther', 
    2 => 'amperageProbeTypeIsUnknown', 
    3 => 'amperageProbeTypeIs1Point5Volt', 
    4 => 'amperageProbeTypeIs3Point3volt', 
    5 => 'amperageProbeTypeIs5Volt', 
    6 => 'amperageProbeTypeIsMinus5Volt', 
    7 => 'amperageProbeTypeIs12Volt', 
    8 => 'amperageProbeTypeIsMinus12Volt', 
    9 => 'amperageProbeTypeIsIO', 
    10 => 'amperageProbeTypeIsCore', 
    11 => 'amperageProbeTypeIsFLEA', 
    12 => 'amperageProbeTypeIsBattery', 
    13 => 'amperageProbeTypeIsTerminator', 
    14 => 'amperageProbeTypeIs2Point5Volt', 
    15 => 'amperageProbeTypeIsGTL', 
    16 => 'amperageProbeTypeIsDiscrete', 
    23 => 'amperageProbeTypeIsPowerSupplyAmps', 
    24 => 'amperageProbeTypeIsPowerSupplyWatts', 
    25 => 'amperageProbeTypeIsSystemAmps', 
    26 => 'amperageProbeTypeIsSystemWatts'
);

1;
