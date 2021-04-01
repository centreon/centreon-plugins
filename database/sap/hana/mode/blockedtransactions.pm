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

package database::sap::hana::mode::blockedtransactions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'blocked-transactions', nlabel => 'transactions.blocked.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Current Total Blocked Transactions : %s',
                perfdatas => [
                    { label => 'total_blocked_transactions', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{sql}->connect();

    my $query = q{
        SELECT COUNT(*) AS total FROM M_BLOCKED_TRANSACTIONS
    };
    $options{sql}->query(query => $query);

    $self->{global} = { total => 0 };
    if (my $row = $options{sql}->fetchrow_hashref()) {
        $self->{global}->{total} = $row->{total} if (defined($row->{total}));
    }
}
    
1;

__END__

=head1 MODE

Check total blocked transactions.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'blocked-transactions'.

=item B<--critical-*>

Threshold critical.
Can be: 'blocked-transactions'.

=back

=cut