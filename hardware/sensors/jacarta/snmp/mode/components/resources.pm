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

package hardware::sensors::jacarta::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %map_default_status;
our %map_input_status;
our %map_state;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%map_default_status %map_input_status %map_state);

%map_default_status = (
    1 => 'unknown',
    2 => 'disable',
    3 => 'normal',
    4 => 'below-low-warning',
    5 => 'below-low-critical',
    6 => 'above-high-warning',
    7 => 'above-high-critical',
);

%map_input_status = (
    1 => 'normal',
    2 => 'triggered',
);

%map_state = (
    1 => 'enabled',
    2 => 'disabled',
);

1;