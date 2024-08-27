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

package network::teldat::snmp::mode::uptime;

use base qw(snmp_standard::mode::uptime);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

1;

__END__

=head1 MODE

Check system uptime.

=over 8

=item B<--warning-uptime>

Threshold warning.

=item B<--critical-uptime>

Threshold critical.

=item B<--add-sysdesc>

Display system description.

=item B<--force-oid>

Can choose your OID (numeric format only).

=item B<--check-overload>

Uptime counter limit is 4294967296 and overflow.
With that option, we manage the counter going back. But there is a few chance we can miss a reboot.

=item B<--reboot-window>

To be used with check-overload option. Time in milliseconds (Default: 5000)
You increase the chance of not missing a reboot if you decrease that value.

=item B<--unit>

Select the unit for performance data and thresholds. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks.  Default is seconds

=back
