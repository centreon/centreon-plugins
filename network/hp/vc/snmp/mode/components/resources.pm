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

package network::hp::vc::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_managed_status;
our $map_reason_code;
our $map_moduleport_loop_status;
our $map_moduleport_protection_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_managed_status $map_reason_code $map_moduleport_loop_status $map_moduleport_protection_status);

$map_managed_status = {
    1 => 'unknown', 
    2 => 'normal',
    3 => 'warning',
    4 => 'minor',
    5 => 'major',
    6 => 'critical',
    7 => 'disabled',
    8 => 'info',
};

$map_reason_code = {
    100 => 'vcNetworkOk',
    101 => 'vcNetworkUnknown',
    102 => 'vcNetworkDisabled',
    104 => 'vcNetworkAbnormal',
    105 => 'vcNetworkFailed',
    106 => 'vcNetworkDegraded',
    109 => 'vcNetworkNoPortsAssignedToPrivateNetwork',
    200 => 'vcFabricOk', 
    202 => 'vcFabricNoPortsConfigured',
    203 => 'vcFabricSomePortsAbnormal',
    204 => 'vcFabricAllPortsAbnormal',
    205 => 'vcFabricWwnMismatch',
    206 => 'vcFabricUnknown',
    300 => 'vcProfileOk',
    301 => 'vcProfileServerAbnormal',
    304 => 'vcProfileAllConnectionsFailed',
    309 => 'vcProfileSomeConnectionsUnmapped',
    310 => 'vcProfileAllConnectionsAbnormal',
    311 => 'vcProfileSomeConnectionsAbnormal',
    312 => 'vcProfileUEFIBootmodeIncompatibleWithServer',
    313 => 'vcProfileUnknown',
    400 => 'vcEnetmoduleOk',
    401 => 'vcEnetmoduleEnclosureDown',
    402 => 'vcEnetmoduleModuleMissing',
    404 => 'vcEnetmodulePortprotect',
    405 => 'vcEnetmoduleIncompatible',
    406 => 'vcEnetmoduleHwDegraded',
    407 => 'vcEnetmoduleUnknown',
    408 => 'vcFcmoduleOk',
    409 => 'vcFcmoduleEnclosureDown',
    410 => 'vcFcmoduleModuleMissing',
    412 => 'vcFcmoduleHwDegraded',
    413 => 'vcFcmoduleIncompatible',
    414 => 'vcFcmoduleUnknown',
    500 => 'vcPhysicalServerOk',
    501 => 'vcPhysicalServerEnclosureDown',
    502 => 'vcPhysicalServerFailed',
    503 => 'vcPhysicalServerDegraded',
    504 => 'vcPhysicalServerUnknown',
    600 => 'vcEnclosureOk',
    601 => 'vcEnclosureAllEnetModulesFailed',
    602 => 'vcEnclosureSomeEnetModulesAbnormal',
    603 => 'vcEnclosureSomeModulesOrServersIncompatible',
    604 => 'vcEnclosureSomeFcModulesAbnormal',
    605 => 'vcEnclosureSomeServersAbnormal',
    606 => 'vcEnclosureUnknown',
    700 => 'vcDomainOk',
    701 => 'vcDomainAbnormalEnclosuresAndProfiles',
    702 => 'vcDomainSomeEnclosuresAbnormal',
    703 => 'vcDomainUnmappedProfileConnections',
    706 => 'vcDomainStackingFailed',
    707 => 'vcDomainStackingNotRedundant',
    709 => 'vcDomainSomeProfilesAbnormal',
    712 => 'vcDomainUnknown',
    713 => 'vcDomainOverProvisioned',
    801 => 'vcDomainSflowIndirectlyDisabled',
    802 => 'vcDomainSflowFailed',
    803 => 'vcDomainSflowDegraded',
    901 => 'vcDomainPortMonitorIndirectlyDisabled',
};

$map_moduleport_protection_status = {
    1 => 'ok',
    2 => 'pause-flood-detected',
    3 => 'in-pause-condition',
};

$map_moduleport_loop_status = {
    1 => 'ok',
    2 => 'loop-dectected',
};

1;