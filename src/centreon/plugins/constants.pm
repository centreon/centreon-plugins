#
# Copyright 2025 Centreon (http://www.centreon.com/)
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
#

package centreon::plugins::constants;

use strict;
use warnings;
use Exporter qw(import);

use constant {
    BUFFER_CREATION => -1,
    NO_VALUE => -10,

    MSG_JSON_DECODE_ERROR => 'Cannot decode response (add --debug option to display returned content)'
};

our %EXPORT_TAGS = (
    values => [ qw(NO_VALUE BUFFER_CREATION) ],
    messages => [ qw(MSG_JSON_DECODE_ERROR) ]
);
$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;
