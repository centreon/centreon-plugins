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

package hardware::devices::camera::avigilon::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (by default if no --add-* option is set).

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--check-metrics>

If the expression is true, metrics are checked (default: '%{opstatus} eq "up"').

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast', 'in-bcast', 'in-mcast', 'out-ucast', 'out-bcast', 'out-mcast',
'speed' (b/s).

=item B<--units-traffic>

Units of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--units-errors>

Units of thresholds for errors/discards (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--units-cast>

Units of thresholds for communication types (default: 'percent_delta') ('percent_delta', 'percent', 'delta', 'deltaps', 'counter').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with NagVis widget.

=item B<--interface>

Set the interface (number expected) example: 1,2,... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option --interface) by name instead of OID index. The name matching mode supports regular expressions.

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--map-speed-dsl>

Get interface speed configuration for interface type 'ADSL' and 'VDSL2'.

Syntax: --map-speed-dsl=interface-src-name,interface-dsl-name

E.g: --map-speed-dsl=Et0.835,Et0-vdsl2

=item B<--force-counters64>

Force to use 64 bits counters only. Can be used to improve performance.

=item B<--force-counters32>

Force to use 32 bits counters (even in SNMP version 2c and version 3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Define the OID to be used to filter interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding --display-transform-src='eth' --display-transform-dst='ens'  will replace all occurrences of 'eth' with 'ens'

=item B<--show-cache>

Display cache interface data.

=back

=cut
