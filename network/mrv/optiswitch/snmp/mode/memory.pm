#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_memTotalReal'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_memTotalFree'};
    $self->{result_values}->{buffer} = $options{new_datas}->{$self->{instance} . '_memBuffer'};
    $self->{result_values}->{cached} = $options{new_datas}->{$self->{instance} . '_memCached'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{physical_used} = $self->{result_values}->{total} - $self->{result_values}->{free};
        $self->{result_values}->{used} = $self->{result_values}->{physical_used} - $self->{result_values}->{buffer} - $self->{result_values}->{cached};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    } else {
        $self->{result_values}->{used} = '0';
        $self->{result_values}->{prct_used} = '0';
    }

    return 0;
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
