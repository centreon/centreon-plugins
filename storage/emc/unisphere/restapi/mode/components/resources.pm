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

package storage::emc::unisphere::restapi::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $health_status;
our $replication_status;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($health_status $replication_status);

$health_status = {
    0 => 'unknown',
    5 => 'ok',
    7 => 'ok_but',
    10 => 'degraded',
    15 => 'minor',
    20 => 'major',
    25 => 'critical',
    30 => 'non_recoverable'
};

$replication_status = {
    0 => 'manual_syncing',
    1 => 'auto_syncing',
    2 => 'idle',
    100 => 'unknown',
    101 => 'out_of_sync',
    102 => 'in_sync',
    103 => 'consistent',
    104 => 'syncing',
    105 => 'inconsistent'
};

1;
