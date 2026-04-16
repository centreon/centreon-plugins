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

package centreon::common::huawei::standard::snmp::functions;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw/get_serial_string/;

sub get_serial_string($) {
    # Get the raw OCTET STRING value for the serial number.
    # It may contain both ASCII and binary data.
    my ($raw_bytes) = @_;

    # Extract the first 4 bytes and interpret them as ASCII characters.
    # Example: '52 43 4D 47' => 'RCMG'
    my $ascii_part = substr($raw_bytes, 0, 4);

    # Extract the last 4 bytes, convert them to an uppercase hex string.
    # Example: '1A 98 0E 53' => '1A980E53'
    my $hex_part = uc(unpack("H*", substr($raw_bytes, 4, 4)));

    # Format the final output string, combining name, serial number, and state.
    # The serial number is shown as: [first 4 bytes as ASCII][last 4 bytes as HEX].
    # Example: RCMG1A980E53
    return "$ascii_part$hex_part";
}

1;

__END__

=head1 DESCRIPTION

Huawei SNMP common functions.

=cut
