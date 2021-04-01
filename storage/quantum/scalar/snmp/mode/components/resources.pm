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

package storage::quantum::scalar::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_rassubsytem_status;
our $map_sensor_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_rassubsytem_status $map_sensor_status);

$map_rassubsytem_status = {
    0 => 'unknown', 1 => 'redFailure', 2 => 'orangeDegraded',
    3 => 'yellowWarning', 4 => 'blueAttention',
    5 => 'greenInformation', 6 => 'greenGood',
};

$map_sensor_status = {
    0 => 'unknown', 1 => 'normal', 2 => 'warning', 3 => 'critical',
};

1;
