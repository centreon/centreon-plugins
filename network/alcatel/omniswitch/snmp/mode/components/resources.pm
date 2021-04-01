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

package network::alcatel::omniswitch::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our %physical_class;
our %phys_oper_status;
our %phys_admin_status;
our %oids;
our $mapping;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%physical_class %phys_oper_status %phys_admin_status %oids $mapping);

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
    10 => 'pwrsave',
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
    10 => 'vcTakeover',
    11 => 'resetVcAll',
);

%oids = (
    common => {
        entPhysicalDescr => '.1.3.6.1.2.1.47.1.1.1.1.2',
        entPhysicalClass => '.1.3.6.1.2.1.47.1.1.1.1.5',
        entPhysicalName => '.1.3.6.1.2.1.47.1.1.1.1.7',
    },
    aos6 => {
        entreprise_alcatel_base => '.1.3.6.1.4.1.6486.800',
        
        chasEntPhysAdminStatus => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.1',
        chasEntPhysOperStatus => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.2',
        chasEntPhysPower => '.1.3.6.1.4.1.6486.800.1.1.1.1.1.1.1.4',
    
        chasHardwareBoardTemp => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.4',
        chasTempThreshold => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.7',
        chasDangerTempThreshold => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.8',
    
        alaChasEntPhysFanStatus => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.11.1.2',
    },
    aos7 => {
        entreprise_alcatel_base => '.1.3.6.1.4.1.6486.801',
        
        chasEntPhysAdminStatus => '.1.3.6.1.4.1.6486.801.1.1.1.1.1.1.1.1',
        chasEntPhysOperStatus => '.1.3.6.1.4.1.6486.801.1.1.1.1.1.1.1.2',
        chasEntPhysPower => '.1.3.6.1.4.1.6486.801.1.1.1.1.1.1.1.3',
    
        chasTempThreshold => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.5',
        chasDangerTempThreshold => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.6',
        
        alaChasEntPhysFanStatus => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.11.1.2',
    },
);

$mapping = {
    aos6 => {
        entPhysicalDescr        => { oid => $oids{common}->{entPhysicalDescr} },
        entPhysicalName         => { oid => $oids{common}->{entPhysicalName} },
        chasEntPhysAdminStatus  => { oid => $oids{aos6}->{chasEntPhysAdminStatus}, map => \%phys_admin_status, default => 'unknown' },
        chasEntPhysOperStatus   => { oid => $oids{aos6}->{chasEntPhysOperStatus}, map => \%phys_oper_status, default => 'unknown' },
        chasEntPhysPower        => { oid => $oids{aos6}->{chasEntPhysPower}, default => -1 },
    },
    aos7 => {
        entPhysicalDescr        => { oid => $oids{common}->{entPhysicalDescr} },
        entPhysicalName         => { oid => $oids{common}->{entPhysicalName} },
        chasEntPhysAdminStatus  => { oid => $oids{aos7}->{chasEntPhysAdminStatus}, map => \%phys_admin_status, default => 'unknown' },
        chasEntPhysOperStatus   => { oid => $oids{aos7}->{chasEntPhysOperStatus}, map => \%phys_oper_status, default => 'unknown' },
        chasEntPhysPower        => { oid => $oids{aos7}->{chasEntPhysPower}, default => -1 },
    },
};

1;
