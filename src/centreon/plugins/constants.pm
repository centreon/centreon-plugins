#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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
    RUN_OK          =>  0, # value present
    BUFFER_CREATION => -1, # cache creation, check will be done next time
    NOT_PROCESSED   => -2, # no result processed
    NO_VALUE        => -10, # contains no value

    # Define the scope of a couunter
    COUNTER_TYPE_GLOBAL   => 0, # global counter
    COUNTER_TYPE_INSTANCE => 1, # counter defined per instance
    COUNTER_TYPE_GROUP    => 2, # group of counters
    COUNTER_TYPE_MULTIPLE => 3, # multiple group of counters

    # Only used with COUNTER_TYPE_MULTIPLE counters
    COUNTER_MULTIPLE_INSTANCE    => 0, # counter global to the instance
    COUNTER_MULTIPLE_SUBINSTANCE => 1, # counter defined per subinstance

    # Define the nature of a counter ( numeric or text )
    COUNTER_KIND_METRIC  => 1, # numeric counter with thesholds and perfdata
    COUNTER_KIND_TEXT    => 2, # text counter with status check and no perfdata

    MSG_JSON_DECODE_ERROR => 'Cannot decode response (add --debug option to display returned content)'
};

our %EXPORT_TAGS = (
    values                 => [ qw(NO_VALUE BUFFER_CREATION RUN_OK NOT_PROCESSED) ],
    counter_types          => [ qw(COUNTER_TYPE_GLOBAL COUNTER_TYPE_INSTANCE COUNTER_TYPE_GROUP COUNTER_TYPE_MULTIPLE) ],
    counter_multiple_types => [ qw(COUNTER_MULTIPLE_INSTANCE COUNTER_MULTIPLE_SUBINSTANCE) ],
    counter_kinds          => [ qw(COUNTER_KIND_METRIC COUNTER_KIND_TEXT) ],
    messages               => [ qw(MSG_JSON_DECODE_ERROR) ]
);
$EXPORT_TAGS{counters} = [ @{$EXPORT_TAGS{counter_types}}, @{$EXPORT_TAGS{counter_multiple_types}}, @{$EXPORT_TAGS{counter_kinds}} ];
$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;
