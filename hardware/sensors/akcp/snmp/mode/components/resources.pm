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

package hardware::sensors::akcp::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %map_default1_status;
our %map_default2_status;
our %map_online;
our %map_degree_type;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%map_default1_status %map_default2_status %map_online %map_degree_type);

%map_default1_status = (
    1 => 'noStatus',
    2 => 'normal',
    3 => 'highWarning',
    4 => 'highCritical',
    5 => 'lowWarning',
    6 => 'lowCritical',
    7 => 'sensorError',
    8 => 'relayOn',
    9 => 'relayOff',
);

%map_default2_status = (
    1 => 'noStatus',
    2 => 'normal',
    4 => 'critical',
    7 => 'sensorError',
);

%map_online = (
    1 => 'online',
    2 => 'offline',
);

%map_degree_type = (
    0 => { unit => 'F', unit_long => 'fahrenheit' },
    F => { unit => 'F', unit_long => 'fahrenheit' },
    1 => { unit => 'C', unit_long => 'celsius' },
    C => { unit => 'C', unit_long => 'celsius' },
);

1;
