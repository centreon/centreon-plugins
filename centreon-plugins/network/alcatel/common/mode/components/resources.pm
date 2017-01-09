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

package network::alcatel::common::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %physical_class;
our %phys_oper_status;
our %phys_admin_status;
our %oids;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%physical_class %phys_oper_status %phys_admin_status %oids);

%physical_class = (
    1 => 'other',
    2 => 'unknown',
    3 => 'chassis',
    4 => 'backplane',
    5 => 'container', 
    6 => 'powerSupply',
    7 => 'fan',
    8 => 'sensor',
    9 => 'module', 
    10 => 'port',
    11 => 'stack',
);

%phys_oper_status = (
    1 => 'up', 
    2 => 'down', 
    3 => 'testing',
    4 => 'unknown',
    5 => 'secondary',
    6 => 'not present',
    7 => 'unpowered',
    8 => 'master',
    9 => 'idle',
    10 => 'unpoweredLicMismatch',
);

%phys_admin_status = (
    1 => 'unknown',
    2 => 'powerOff',
    3 => 'powerOn',
    4 => 'reset',
    5 => 'takeover',
    6 => 'resetAll',
    7 => 'standby',
    8 => 'resetWithFabric',
    9 => 'takeoverWithFabrc',
);

%oids = (
    entPhysicalDescr => '.1.3.6.1.2.1.47.1.1.1.1.2',
    entPhysicalClass => '.1.3.6.1.2.1.47.1.1.1.1.5',
    entPhysicalName => '.1.3.6.1.2.1.47.1.1.1.1.7',
    chasEntPhysAdminStatus => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.1',
    chasEntPhysOperStatus => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.2',
    chasEntPhysPower => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.4',
    
    chasHardwareBoardTemp => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.4',
    chasTempThreshold => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.7',
    chasDangerTempThreshold => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.8',
    
    alaChasEntPhysFanStatus => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.11.1.2',
);

1;