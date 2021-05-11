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

package storage::huawei::oceanstor::snmp::mode::resources;

use strict;
use warnings;
use Exporter;

our $health_status;
our $running_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($health_status $running_status);

$health_status = {
    0 => '--', 1 => 'Normal',
    2 => 'Fault', 3 => 'Pre-Fail',
    4 => 'Partially Broken', 5 => 'Degraded',
    6 => 'Bad Sectors Found', 7 => 'Bit Errors Found',
    8 => 'Consistent', 9 => 'Inconsistent',
    10 => 'Busy', 11 => 'No Input',
    12 => 'Low Battery', 13 => 'Single Link Fault',
    14 => 'Invalid', 15 => 'Write Protect'
};

$running_status = {
    0 => '--', 1 => 'Normal', 2 => 'Running',
    3 => 'Not running', 4 => 'Not existed',
    5 => 'Sleep in high temperature', 6 => 'Starting',
    7 => 'Power failure rotection', 8 => 'Sping down',
    9 => 'Started',  10 => 'Link Up', 11 => 'Link Down',
    12 => 'Powering on', 13 => 'Powered off', 14 => 'Pre-copy',
    15 => 'Copyback', 16 => 'Reconstruction', 17 => 'Expansion',
    18 => 'Unformatted', 19 => 'Formatting', 20 => 'Unmapped',
    21 => 'Initial synchronizing', 22 => 'Consistent',
    23 => 'Synchronizing', 24 => 'Synchronized',
    25 => 'Unsynchronized', 26 => 'Split', 27 => 'Online',
    28 => 'Offline', 29 => 'Locked', 30 => 'Enabled',
    31 => 'Disabled', 32 => 'Balancing', 33 => 'To be recovered',
    34 => 'Interrupted', 35 => 'Invalid', 36 => 'Not start',
    37 => 'Queuing', 38 => 'Stopped', 39 => 'Copying',
    40 => 'Completed', 41 => 'Paused', 42 => 'Reverse synchronizing',
    43 => 'Activated', 44 => 'Restore', 45 => 'Inactive',
    46 => 'Idle', 47 => 'Powering off', 48 => 'Charging',
    49 => 'Charging completed', 50 => 'Discharging',
    51 => 'Upgrading', 52 => 'Power Lost', 53 => 'Initializing',
    54 => 'Apply change', 55 => 'Online disable', 56 => 'Offline disable',
    57 => 'Online frozen', 58 => 'Offline frozen', 59 => 'Closed',
    60 => 'Removing', 61 => 'In service', 62 => 'Out of service',
    63 => 'Running normal', 64 => 'Running fail', 65 => 'Running success',
    66 => 'Running success', 67 => 'Running failed', 68 => 'Waiting',
    69 => 'Canceling', 70 => 'Canceled', 71 => 'About to synchronize',
    72 => 'Synchronizing data', 73 => 'Failed to synchronize',
    74 => 'Fault', 75 => 'Migrating', 76 => 'Migrated',
    77 => 'Activating', 78 => 'Deactivating', 79 => 'Start failed',
    80 => 'Stop failed', 81 => 'Decommissioning', 82 => 'Decommissioned',
    83 => 'Recommissioning', 84 => 'Replacing node', 85 => 'Scheduling',
    86 => 'Pausing', 87 => 'Suspending', 88 => 'Suspended', 89 => 'Overload',
    90 => 'To be switch', 91 => 'Switching', 92 => 'To be cleanup',
    93 => 'Forced start', 94 => 'Error', 95 => 'Job completed',
    96 => 'Partition Migrating', 97 => 'Mount', 98 => 'Umount',
    99 => 'INSTALLING', 100 => 'To Be Synchronized', 101 => 'Connecting',
    102 => 'Service Switching', 103 => 'Power-on failed', 104 => 'REPAIRING',
    105 => 'abnormal', 106 => 'Deleting', 107 => 'Modifying',
    108 => 'Running(clearing data)', 109 => 'Running(synchronizing data)'
};

1;
