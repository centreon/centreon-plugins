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

package network::mrv::optiswitch::snmp::mode::memory;

use base qw(snmp_standard::mode::memory);

use strict;
use warnings;

sub memory_calc {
    my ($self, %options) = @_;

    my $available = ($options{result}->{memTotalFree}) ? $options{result}->{memTotalFree} * 1024 : 0;
    my $total = ($options{result}->{memTotalReal}) ? $options{result}->{memTotalReal} * 1024 : 0;
    my $buffer = ($options{result}->{memBuffer}) ? $options{result}->{memBuffer} * 1024 : 0;
    my $cached = ($options{result}->{memCached}) ? $options{result}->{memCached} * 1024 : 0;
    my ($used, $free, $prct_used, $prct_free) = (0, 0, 0, 0);

    if ($total != 0) {
        $used = $total - $available - $buffer - $cached;
        $free = $total - $used;
        $prct_used = $used * 100 / $total;
        $prct_free = 100 - $prct_used;
    }
    
    $self->{ram} = {
        total => $total,
        used => $used,
        free => $free,
        prct_used => $prct_used,
        prct_free => $prct_free,
        memShared => ($options{result}->{memShared}) ? $options{result}->{memShared} * 1024 : 0,
        memBuffer => $buffer,
        memCached => $cached,
    };
}

1;

__END__

=head1 MODE

Check memory usage (UCD-SNMP-MIB).

=over 8

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free space left.

=item B<--swap>

Check swap also.

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'swap', 'buffer' (absolute),
'cached' (absolute), 'shared' (absolute).

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'swap', 'buffer' (absolute),
'cached' (absolute), 'shared' (absolute).

=back

=cut
