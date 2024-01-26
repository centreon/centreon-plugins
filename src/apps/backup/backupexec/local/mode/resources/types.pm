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

package apps::backup::backupexec::local::mode::resources::types;

use strict;
use warnings;
use Exporter;

our $job_status;
our $job_substatus;
our $job_type;
our $storage_type;
our $alert_severity;
our $alert_source;
our $alert_category;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $job_status $job_substatus $job_type
    $storage_type
    $alert_severity $alert_source $alert_category
);

$job_status = {
    0 => 'unknown', 1 => 'Canceled',
    2 => 'completed', 3 => 'succeededWithExceptions',
    4 => 'onHold', 5 => 'error', 6 => 'missed',
    7 => 'recovered', 8 => 'resumed', 9 => 'succeeded',
    10 => 'thresholdAbort', 11 => 'dispatched',
    12 => 'dispatchFailed', 13 => 'invalidSchedule',
    14 => 'invalidTimeWindow', 15 => 'notInTimeWindow',
    16 => 'queued', 17 => 'disabled',
    18 => 'active', 19 => 'ready',
    20 => 'scheduled', 21 => 'superseded',
    22 => 'toBeScheduled', 23 => 'linked',
    24 => 'ruleBlocked',
};

$job_substatus = {
    0 => 'unknown', 1 => 'ok', 2 => 'internalError', 3 => 'invalidInput',
    4 => 'InvalidStorageDevice', 5 => 'invalidJob', 6 => 'destinationCannotBeABackupExecServer',
    7 => 'storageCannotBeStorageDevicePool', 8 => 'noBackupExecServersAvailable',
    9 => 'notReadyDiscoveringStorageDevices', 10 => 'incompatibleResumes',
    11 => 'serverLicenseNotAvailable', 12 => 'multiServerLicenseNotAvailable',
    13 => 'advancedOpenFileOptionLicenseNotAvailable', 14 => 'sqlAgentLicenseNotAvailable',
    15 => 'exchangeAgentLicenseNotAvailable', 16 => 'windows2000LicenseNotAvailable',
    17 => 'netwareLicenseNotAvailable', 18 => 'noWindowsNT4Server', 19 => 'noWindows2000Server',
    20 => 'noNetwareServer', 21 => 'localBackupExecServerRequired', 22 => 'lotusNotesLicenseNotAvailable',
    23 => 'oracleAgentLicenseNotAvailable', 24 => 'lotusDominoAgentLicenseNotAvailable', 25 => 'sharepointAgentLicenseNotAvailable',
    26 => 'noServersInBackupExecServerPool', 27 => 'localServerNotBackupExecServer', 28 => 'destinationServerNotInBackupExecServerPool',
    29 => 'storageDeviceNotOnLocalBackupExecServer', 30 => 'storageNotConfiguredForBackupExecServer',
    31 => 'unixAgentLicenseNotAvailable', 32 => 'macintoshAgentLicenseNotAvailable',
    33 => 'noIdleDevicesAvailable', 34 => 'cascadedPoolNotAllowed', 35 => 'cascadedPoolIsEmpty',
    36 => 'storageDevicePoolIsEmpty', 37 => 'noDevicesInCascadedPoolAreAvailable', 38 => 'noEligibleDevicesAvailableInStorageDevicePool',
    39 => 'willRunAfterBlockingJobCompletes', 40 => 'jobQueueOnHold', 41 => 'backupExecServerNotAvailable',
    42 => 'oracleOnLinuxAgentLicenseNotAvailable', 43 => 'blockedByActiveLinkedJob',
    44 => 'db2AgentLicenseNotAvailable', 45 => 'microsoftVirtualServerAgentLicenseNotAvailable',
    46 => 'vmwareAgentLicenseNotAvailable', 47 => 'noBackupExecServersWithDeduplicationOptionLicenseAvailable',
    48 => 'no64BitBackupExecServersAvailableForExchangeResources', 49 => 'enterpriseVaultLicenseNotAvailable',
    50 => 'storageCannotBeVault', 51 => 'storageCannotBeStorageArray', 52 => 'invalidManagedBackupExecServer',
    53 => 'noIdleDevicesOnTargetBackupExecServerAvailable', 54 => 'noIdleDeviceInStoragePoolAvailable',
    55 => 'noCompatibleBackupExecServersAvailable', 56 => 'storageRequiresRestrictedSelection',
    57 => 'preferredBackupExecCatalogServerNotAvailable'
};

$job_type = {
    0 => 'unknown', 1 => 'backup',
    2 => 'restore', 3 => 'verify',
    4 => 'catalog', 5 => 'utility',
    6 => 'report', 7 => 'duplicate',
    8 => 'testRun', 9 => 'resourceDiscovery',
    10 => 'copyJob', 11 => 'install',
    12 => 'convertToVirtual', 13 => 'recoverVM',
    14 => 'removeVM', 15 => 'validateVM'
};

$storage_type = {
    0 => 'diskStorageDevicePool', 1 => 'tapeStorageDevicePool',
    2 => 'diskCartridgeStorageDevicePool', 3 => 'tapeDriveDevice',
    4 => 'diskStorageDevice', 5 => 'deduplicationDiskStorageDevice',
    6 => 'diskCartridgeDevice', 7 => 'roboticLibraryDevice',
    8 => 'roboticLibraryPartition', 9 => 'roboticLibrarySlot',
    10 => 'storageArrayDevice', 11 => 'virtualDiskDevice',
    12 => 'legacyBackupToDiskFolderDevice', 13 => 'cloudStorageDevice',
    14 => 'openStorageDevice', 15 => 'remoteMediaAgentForLinux',
    16 => 'ndmpServer'
};

$alert_severity = {
    0 => 'none', 1 => 'information',
    2 => 'question', 3 => 'warning',
    4 => 'error'
};

$alert_source = {
    0 => 'system', 1 => 'media',
    2 => 'device', 3 => 'job'
};

$alert_category = {
    0 => 'none', 1 => 'jobWarning', 2 => 'jobSuccess',
    3 => 'jobFailure', 4 => 'jobCancellation',  5 => 'catalogError',
    6 => 'softwareUpdateInformation', 7 => 'softwareUpdateWarning',
    8 => 'softwareUpdateError', 9 => 'installInformation',
    10 => 'installWarning', 11 => 'generalInformation',
    12 => 'databaseMaintenanceInformation', 13 => 'databaseMaintenanceFailure',
    14 => 'backupExecRetrieveUrlUpdateInformation',
    15 => 'backupExecRetrieveUrlUpdateFailure', 16 => 'idrCopyFailed',
    17 => 'idrFullBackupSuccess', 18 => 'backupJobContainsNoData',
    19 => 'jobCompletedWithExceptions', 20 => 'jobStart',
    21 => 'serviceStart', 22 => 'serviceStop', 23 => 'deviceError',
    24 => 'deviceWarning', 25 => 'deviceInformation',
    26 => 'deviceIntervention', 27 => 'mediaError',
    28 => 'mediaWarning', 29 => 'mediaInformation',
    30 => 'mediaIntervention', 31 => 'mediaInsert',
    32 => 'mediaOverwrite', 33 => 'mediaRemove',
    34 => 'libraryInsert', 35 => 'tapeAlertInformation',
    36 => 'tapeAlertWarning', 37 => 'tapeAlertError',
    38 => 'idrFullBackupSuccessWarning', 39 => 'licenseAndMaintenanceWarning'
};

1;
