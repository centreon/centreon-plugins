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

package network::security::cato::networks::api::misc;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(mk_timeframe);

# Supported timeframes format (x = integer):
# last.PTxM: last x minutes
# last.PTxH: last x hours
# last.PxD: last x days
# last.PxM: last x months
# last.PxY: last x years
our %_timeframe_units = (
    'm' => 'last.PT%dM',
    'h' => 'last.PT%dH',
    'd' => 'last.P%dD',
    'M' => 'last.P%dM',
    'Y' => 'last.P%dY'
);

# make a timeframe argument
# value is a numeric value and unit points to the above private hash %_timeframe_units
sub mk_timeframe($$) {
    my ($value, $unit) = @_;
    $unit //= 'M';

    return undef unless exists $_timeframe_units{$unit};

    return sprintf($_timeframe_units{$unit}, $value);
}

1;

__END__
