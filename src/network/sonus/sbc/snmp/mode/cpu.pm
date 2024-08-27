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

package network::sonus::sbc::snmp::mode::cpu;

use base qw(snmp_standard::mode::cpu);

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

Check system CPU.
(The average, over the last minute, of the percentage
of time that this processor was not idle)

=over 8

=item B<--use-ucd>

Use UCD MIB for CPU average.

=item B<--warning-average>

Warning threshold average CPU utilization. 

=item B<--critical-average>

Critical  threshold average CPU utilization.

=item B<--warning-core>

Warning thresholds for each CPU core

=item B<--critical-core>

Critical thresholds for each CPU core

=back

=cut
