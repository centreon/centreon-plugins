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

package apps::microsoft::hyperv::2012::local::mode::resources::types;

use strict;
use warnings;
use Exporter;

our $node_replication_state;
our $node_vm_integration_service_operational_status;
our $node_vm_state;
our $scvmm_vm_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $node_replication_state $node_vm_integration_service_operational_status
    $node_vm_state $scvmm_vm_status
);

$node_vm_state = {
    1 => 'Other',
    2 => 'Running', 
    3 => 'Off',
    4 => 'Stopping',
    6 => 'Saved',
    9 => 'Paused',
    10 => 'Starting',
    11 => 'Reset',
    32773 => 'Saving',
    32776 => 'Pausing',
    32777 => 'Resuming',
    32779 => 'FastSaved',
    32780 => 'FastSaving',
    32781 => 'ForceShutdown',
    32782 => 'ForceReboot',
    32783 => 'RunningCritical',
    32784 => 'OffCritical',
    32785 => 'StoppingCritical',
    32786 => 'SavedCritical',
    32787 => 'PausedCritical',
    32788 => 'StartingCritical',
    32789 => 'ResetCritical',
    32790 => 'SavingCritical',
    32791 => 'PausingCritical',
    32792 => 'ResumingCritical',
    32793 => 'FastSavedCritical',
    32794 => 'FastSavingCritical'
};

$node_replication_state = {
    0 => 'Disabled',
    1 => 'ReadyForInitialReplication',
    2 => 'InitialReplicationInProgress',
    3 => 'WaitingForInitialReplication',
    4 => 'Replicating',
    5 => 'PreparedForFailover',
    6 => 'FailedOverWaitingCompletion',
    7 => 'FailedOver',
    8 => 'Suspended',
    9 => 'Error',
    10 => 'WaitingForStartResynchronize',
    11 => 'Resynchronizing',
    12 => 'ResynchronizeSuspended',
    13 => 'RecoveryInProgress',
    14 => 'FailbackInProgress',
    15 => 'FailbackComplete',
    16 => 'WaitingForUpdateCompletion',
    17 => 'UpdateError',
    18 => 'WaitingForRepurposeCompletion',
    19 => 'PreparedForSyncReplication',
    20 => 'PreparedForGroupReverseReplication',
    21 => 'FiredrillInProgress'
};

$node_vm_integration_service_operational_status = {
    2 => 'Ok',
    3 => 'Degraded',
    6 => 'Error',
    7 => 'NonRecoverableError',
    12 => 'NoContact',
    13 => 'LostCommunication',
    32775 => 'ProtocolMismatch',
    32782 => 'ApplicationCritical',
    32783 => 'CommunicationTimedOut',
    32784 => 'CommunicationFailed',
    32896 => 'Disabled'
};

$scvmm_vm_status = {
    0 => 'Running',
    1 => 'PowerOff',
    2 => 'PoweringOff',
    3 => 'Saved',
    4 => 'Saving',
    5 => 'Restoring',
    6 => 'Paused',
    10 => 'DiscardSavedState',
    11 => 'Starting',
    12 => 'MergingDrives',
    13 => 'Deleting',
    14 => 'Reset',
    80 => 'DiscardingDrives',
    81 => 'Pausing',
    100 => 'UnderCreation',
    101 => 'CreationFailed',
    102 => 'Stored',
    103 => 'UnderTemplateCreation',
    104 => 'TemplateCreationFailed',
    105 => 'CustomizationFailed',
    106 => 'UnderUpdate',
    107 => 'UpdateFailed',
    108 => 'ReplacementFailed',
    109 => 'UnderReplacement',
    200 => 'UnderMigration',
    201 => 'MigrationFailed',
    210 => 'CreatingCheckpoint',
    211 => 'DeletingCheckpoint',
    212 => 'RecoveringCheckpoint',
    213 => 'CheckpointFailed',
    214 => 'InitializingCheckpointOperation',
    215 => 'FinishingCheckpointOperation',
    220 => 'Missing',
    221 => 'HostNotResponding',
    222 => 'Unsupported',
    223 => 'IncompleteVMConfig',
    224 => 'UnsupportedSharedFiles',
    225 => 'UnsupportedCluster',
    226 => 'UnderLiveCloning',
    227 => 'DbOnly',
    240 => 'P2VCreationFailed',
    250 => 'V2VCreationFailed'
};

1;
