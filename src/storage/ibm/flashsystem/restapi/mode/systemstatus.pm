#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# HOST check: is the array still working?
#
# This mode is designed for the host check command, not for a service. It
# therefore only returns two verdicts - OK (host UP) or CRITICAL (host DOWN) -
# and never WARNING nor UNKNOWN, whose interpretation by the engine is
# ambiguous.
#
# The criterion is narrow on purpose: DOWN means "the array stopped working",
# not "something is wrong". Taking a host DOWN makes ALL its services
# UNREACHABLE and silences them; a failed power supply, a dead drive or a
# degraded partition must therefore never lead there - the hardware,
# replication and eventlog services carry those, and they need to be heard
# precisely at such moments.
#
# Three facts, and three only, mean the service is down:
#   - the array does not answer at all;
#   - no canister is online, so nothing processes I/O any more;
#   - no pool is online, so no volume is served any more.
#
# An API that answers but refuses to serve us - expired token, 429,
# certificate - is NOT a dead array: it is our monitoring that has an issue.
# The host stays UP, with the reason in the output.
#

package storage::ibm::flashsystem::restapi::mode::systemstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        # On a single-controller system or during planned maintenance, one may
        # want to disable one of the two functional criteria.
        'skip-canisters' => { name => 'skip_canisters' },
        'skip-pools'     => { name => 'skip_pools' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub count_online {
    my (%options) = @_;

    my ($total, $online) = (0, 0);
    foreach my $entry (@{ $options{entries} }) {
        next unless (ref $entry eq 'HASH');
        $total++;
        $online++ if (defined($entry->{status}) && $entry->{status} =~ /^online$/i);
    }

    return ($total, $online);
}

sub run {
    my ($self, %options) = @_;

    my ($state, $detail) = $options{custom}->reachability();

    if ($state eq 'unreachable') {
        $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => 'Array is not answering: ' . $detail
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($state eq 'degraded') {
        # The device answers: it is not the one that is dead. Say so without
        # taking the host down, or all its monitoring would go silent.
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'Array is answering but the API refused the call, '
                . 'host left UP: ' . $detail
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my @reasons;
    my @facts;

    if (!defined($self->{option_results}->{skip_canisters})) {
        my ($total, $online) = count_online(
            entries => $options{custom}->request_optional(command => 'lsnodecanister')
        );
        push @facts, sprintf('canisters %s/%s online', $online, $total);
        push @reasons, 'no canister online' if ($total > 0 && $online == 0);
    }

    if (!defined($self->{option_results}->{skip_pools})) {
        my ($total, $online) = count_online(
            entries => $options{custom}->request_optional(command => 'lsmdiskgrp')
        );
        push @facts, sprintf('pools %s/%s online', $online, $total);
        push @reasons, 'no pool online' if ($total > 0 && $online == 0);
    }

    if (@reasons) {
        $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => 'Array has stopped serving: ' . join(', ', @reasons)
                . ' [' . join(', ', @facts) . ']'
        );
    } else {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'Array is serving: ' . join(', ', @facts)
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Host check: whether the array is still working.

This mode is meant for the B<host check command>, not for a service. It returns
only OK (host UP) or CRITICAL (host DOWN) — never WARNING or UNKNOWN, whose
meaning for a host check is ambiguous.

The criterion is deliberately narrow. DOWN means "the array has stopped
working", not "something is wrong". Marking a host DOWN turns B<all> its
services UNREACHABLE and silences them, so a failed power supply, a dead drive
or a degraded partition must never lead there — the C<hardware>, C<replication>
and C<eventlog> services carry those, and they are exactly what you need to hear
at that moment.

Three facts, and only three, count as a stopped array:

=over 4

=item *

the array does not answer at all;

=item *

no canister is online, so nothing processes I/O any more;

=item *

no pool is online, so no volume is served any more.

=back

An API that answers but refuses the call — expired token, 429, certificate —
is B<not> a dead array: it is our own monitoring having trouble. The host stays
UP and the reason is printed.

Used as a host check command:

    $CENTREONPLUGINS$/centreon_ibm_flashsystem_restapi.pl \
      --plugin=storage::ibm::flashsystem::restapi::plugin --mode=system-status \
      --hostname='$HOSTADDRESS$' --api-username='$_HOSTIBMAPIUSERNAME$' \
      --api-password='$_HOSTIBMAPIPASSWORD$' --port='$_HOSTIBMAPIPORT$' \
      $_HOSTEXTRAOPTIONS$

=over 8

=item B<--skip-canisters>

Do not treat "no canister online" as a stopped array. Useful on a
single-controller model.

=item B<--skip-pools>

Do not treat "no pool online" as a stopped array, for instance during a planned
migration where pools are deliberately taken offline.

=back

=cut
