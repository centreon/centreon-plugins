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

package database::mssql::mode::resources::types;

use strict;
use warnings;
use Exporter;

our $database_state;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($database_state);

$database_state = {
    0 => 'online',
    1 => 'restoring',
    2 => 'recovering',
    3 => 'recoveringPending',
    4 => 'suspect',
    5 => 'emergency',
    6 => 'offline',
    7 => 'copying',
    10 => 'offlineSecondary'
};

1;
