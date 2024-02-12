#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::sensors::apc::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_alarm_status;
our $map_comm_status;
our $map_comm_status2;
our $map_comm_status3;
our $map_fluid_state;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_alarm_status $map_fluid_state $map_comm_status $map_comm_status2 $map_comm_status3);

$map_alarm_status = {
    1 => 'normal',
    2 => 'warning',
    3 => 'critical'
};

$map_comm_status = {
    1 => 'notInstalled',
    2 => 'ok',
    3 => 'lost'
};

$map_comm_status2 = {
    1 => 'ok',
    2 => 'lost'
};

$map_comm_status3 = {
    0 => 'inactive',
    1 => 'active'
};

$map_fluid_state = {
    1 => 'fluidDetected',
    2 => 'noFuild',
    3 => 'unknown'
};

1;
