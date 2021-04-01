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

package hardware::sensors::hwgste::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %map_sens_unit;
our %map_sens_state;
our $mapping;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($mapping);

%map_sens_state = (
    0 => 'invalid',
    1 => 'normal',
    2 => 'outOfRangeLo',
    3 => 'outOfRangeHi',
    4 => 'alarmLo',
    5 => 'alarmHi',
);
%map_sens_unit = (
    0 => '', # none
    1 => 'C',
    2 => 'F',
    3 => 'K',
    4 => '%',
);

$mapping = {
    branch_sensors => {
        hwgste => '.1.3.6.1.4.1.21796.4.1.3',
        hwgste2 => '.1.3.6.1.4.1.21796.4.9.3',
    },
    hwgste => {
        sensName  => { oid => '.1.3.6.1.4.1.21796.4.1.3.1.2' },
        sensState => { oid => '.1.3.6.1.4.1.21796.4.1.3.1.3', map => \%map_sens_state },
        sensValue => { oid => '.1.3.6.1.4.1.21796.4.1.3.1.5' },
        sensUnit  => { oid => '.1.3.6.1.4.1.21796.4.1.3.1.7', map => \%map_sens_unit },
    },
    hwgste2 => {
        sensName  => { oid => '.1.3.6.1.4.1.21796.4.9.3.1.2' },
        sensState => { oid => '.1.3.6.1.4.1.21796.4.9.3.1.3', map => \%map_sens_state },
        sensValue => { oid => '.1.3.6.1.4.1.21796.4.9.3.1.5' },
        sensUnit  => { oid => '.1.3.6.1.4.1.21796.4.9.3.1.7', map => \%map_sens_unit },
    },
};

1;
