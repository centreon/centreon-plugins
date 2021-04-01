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

package apps::backup::veeam::local::mode::resources::types;

use strict;
use warnings;
use Exporter;

our $job_type;
our $job_result;
our $job_tape_type;
our $job_tape_result;
our $job_tape_state;
our $license_type;
our $license_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $job_type $job_result $job_tape_type $job_tape_result $job_tape_state
    $license_type $license_status
);

$job_type = {
    0 => 'Backup', 1 => 'Replica', 2 => 'Copy',
    3 => 'DRV', 4 => 'RestoreVm', 5 => 'RestoreVmFiles',
    6 => 'RestoreFiles', 7 => 'Failover', 8 => 'QuickMigration',
    9 => 'UndoFailover', 10 => 'FileLevelRestore',
    11 => 'LinuxFileLevelRestore', 12 => 'InstantRecovery',
    13 => 'RestoreHdd', 14 => 'Failback', 15 => 'PermanentFailover',
    16 => 'UndoFailback', 17 => 'CommitFailback', 18 => 'ShellRun',
    19 => 'VolumesDiscover', 20 => 'HvCtpRescan',
    21 => 'CatCleanup', 22 => 'SanRescan', 23 => 'CreateSanSnapshot',
    24 => 'FileTapeBackup', 25 => 'FileTapeRestore',
    26 => 'TapeValidate', 27 => 'TapeInventory', 28 => 'VmTapeBackup',
    29 => 'VmTapeRestore', 30 => 'SanMonitor', 31 => 'DeleteSanSnapshot',
    32 => 'TapeErase', 33 => 'TapeEject', 34 => 'TapeExport',
    35 => 'TapeImport', 36 => 'TapeCatalog', 37 => 'TapeLibrariesDiscover',
    38 => 'PowerShellScript', 39 => 'VmReconfig', 40 => 'VmStart',
    41 => 'VcdVAppRestore', 42 => 'VcdVmRestore', 46 => 'HierarchyScan',
    47 => 'ViVmConsolidation', 48 => 'ApplicationLevelRestore',
    50 => 'RemoteReplica', 51 => 'BackupSync', 52 => 'SqlLogBackup',
    53 => 'LicenseAutoUpdate', 54 => 'OracleLogBackup',
    55 => 'TapeMarkAsFree', 56 => 'TapeDeleteFromLibrary',
    57 => 'TapeMoveToMediaPool', 58 => 'TapeCatalogueDecrypted',
    63 => 'SimpleBackupCopyWorker', 64 => 'QuickMigrationCheck',
    100 => 'ConfBackup', 101 => 'ConfRestore', 102 => 'ConfResynchronize',
    103 => 'WaGlobalDedupFill', 104 => 'DatabaseMaintenance',
    105 => 'RepositoryMaintenance', 106 => 'InfrastructureRescan',
    200 => 'HvLabDeploy', 201 => 'HvLabDelete', 202 => 'FailoverPlan',
    203 => 'UndoFailoverPlan', 204 => 'FailoverPlanTask',
    205 => 'UndoFailoverPlanTask', 206 => 'PlannedFailover',
    207 => 'ViLabDeploy', 208 => 'ViLabDelete', 209 => 'ViLabStart',
    300 => 'Cloud', 301 => 'CloudApplDeploy',
    302 => 'HardwareQuotasProcessing', 303 => 'ReconnectVpn',
    304 => 'DisconnectVpn', 305 => 'OrchestratedTask',
    306 => 'ViReplicaRescan', 307 => 'ExternalRepositoryMaintenance',
    308 => 'DeleteBackup', 309 => 'CloudProviderRescan',
    401 => 'AzureApplDeploy', 500 => 'TapeTenantRestore',
    666 => 'Unknown', 4000 => 'EndpointBackup',
    4005 => 'EndpointRestore', 4010 => 'BackupCacheSync',
    4020 => 'EndpointSqlLogBackup', 4021 => 'EndpointOracleLogBackup',
    4030 => 'OracleRMANBackup', 4031 => 'SapBackintBackup',
    5000 => 'CloudBackup', 6000 => 'RestoreVirtualDisks',
    6001 => 'RestoreAgentVolumes',  7000 => 'InfraItemSave',
    7001 => 'InfraItemUpgrade', 7002 => 'InfraItemDelete',
    7003 => 'AzureWinProxySave', 8000 => 'FileLevelRestoreByEnterprise',
    9000 => 'RepositoryEvacuate', 10000 => 'LogsExport',
    10001 => 'InfraStatistic', 11000 => 'AzureVmRestore',
    12000 => 'EpAgentManagement', 12001 => 'EpAgentDiscoveryObsolete',
    12002 => 'EpAgentPolicy', 12003 => 'EpAgentBackup',
    12004 => 'EpAgentTestCreds', 12005 => 'EpAgentDiscovery',
    12006 => 'EpAgentDeletedRetention', 13000 => 'NasBackup',
    13001 => 'NasBackupBrowse', 13002 => 'NasRestore',
    14000 => 'VmbApiPolicyTempJob', 15000 => 'ExternalInfrastructureRescan',
    16000 => 'AmazonRestore', 17000 => 'StagedRestore',
    18000 => 'ArchiveBackup', 18001 => 'ArchiveRehydration',
    18002 => 'ArchiveDownload', 19000 => 'HvStagedRestore',
    20000 => 'VbkExport', 21000 => 'GuestScriptingConnect'
};

$job_result = {
    0 => 'Success',
    1 => 'Warning',
    2 => 'Failed',
    -1 => 'None'
};

$job_tape_type = {
    0 => 'BackupToTape', 1 => 'FileToTape',
    2 => 'TapeCatalog', 3 => 'TapeEject',
    4 => 'TapeErase', 5 => 'TapeExport',
    6 => 'TapeImport', 7 => 'TapeInventory',
    8 => 'TapeRescan', 9 => 'Backup',
    10 => 'BackupSync', 11 => 'EndpointBackup',
    12 => 'ConfigurationBackup'
};

$job_tape_result = {
    0 => 'None', 1 => 'Success', 2 => 'Warning', 3 => 'Failed'
};

$job_tape_state = {
    0 => 'Stopped', 1 => 'Starting', 2 => 'Stopping',
    3 => 'Working', 4 => 'Pausing', 5 => 'Resuming',
    6 => 'WaitingTape', 7 => 'Idle', 8 => 'Postprocessing',
    9 => 'WaitingRepository', 10 => 'Pending'
};

$license_type = {
    0 => 'rental', 1 => 'perpetual',
    2 => 'subscription', 3 => 'evaluation',
    4 => 'free', 5 => 'NFR', 6 => 'empty'
};

$license_status = {
    0 => 'valid', 1 => 'expired', 2 => 'invalid'
};

1;
