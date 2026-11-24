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

package storage::ibm::flashsystem::restapi::mode::systemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;

sub custom_canisters_output {
    my ($self, %options) = @_;

    return sprintf('canisters online: %s/%s', $self->{result_values}->{canisters_online}, $self->{result_values}->{canisters_total});
}

sub custom_pools_output {
    my ($self, %options) = @_;

    return sprintf('pools online: %s/%s', $self->{result_values}->{pools_online}, $self->{result_values}->{pools_total});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Array ', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'canisters-online', nlabel => 'system.canisters.online.count', critical_default => '1:', set => {
                key_values => [ { name => 'canisters_online' }, { name => 'canisters_total' } ],
                closure_custom_output => $self->can('custom_canisters_output'),
                perfdatas => [ { template => '%s', min => 0, max => 'canisters_total' } ]
            }
        },
        { label => 'pools-online', nlabel => 'system.pools.online.count', critical_default => '1:', set => {
                key_values => [ { name => 'pools_online' }, { name => 'pools_total' } ],
                closure_custom_output => $self->can('custom_pools_output'),
                perfdatas => [ { template => '%s', min => 0, max => 'pools_total' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    foreach my $object (['canisters', 'lsnodecanister'], ['pools', 'lsmdiskgrp']) {
        my ($name, $command) = @$object;
        my ($total, $online) = (0, 0);
        foreach my $entry (@{ $options{custom}->request(command => $command) }) {
            next if (ref($entry) ne 'HASH');
            $total++;
            $online++ if (($entry->{status} // '') =~ /^online$/i);
        }
        # Nothing reported: the counter is skipped rather than seen as 0 online.
        next if ($total == 0);

        $self->{global}->{$name . '_total'} = $total;
        $self->{global}->{$name . '_online'} = $online;
    }
}

1;

__END__

=head1 MODE

Check that the array is serving: number of node canisters and of storage pools
online (C<lsnodecanister>, C<lsmdiskgrp>).

By default, the check is CRITICAL when no canister or no pool is online. It
can be used as the host check command: a failed power supply, a dead drive or
a degraded partition do not alter it, they are reported by the other modes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='canisters'>

=item B<--warning-canisters-online>

Threshold on the number of node canisters online.

=item B<--critical-canisters-online>

Threshold on the number of node canisters online (default: C<1:>).

=item B<--warning-pools-online>

Threshold on the number of storage pools online.

=item B<--critical-pools-online>

Threshold on the number of storage pools online (default: C<1:>).

=back

=cut
