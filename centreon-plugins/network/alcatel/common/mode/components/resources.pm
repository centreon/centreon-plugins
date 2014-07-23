################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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