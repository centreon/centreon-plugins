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

package apps::toshiba::storemate::sql::mode::posstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'state', type => 0, cb_prefix_output => 'prefix_state_output' },
        { name => 'merchandise', type => 0, cb_prefix_output => 'prefix_merchandise_output' },
        { name => 'transaction', type => 0, cb_prefix_output => 'prefix_transaction_output' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'online', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'online : %s',
                perfdatas => [
                    { label => 'online', value => 'online', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'offline', set => {
                key_values => [ { name => 'offline' } ],
                output_template => 'offline : %s',
                perfdatas => [
                    { label => 'offline', value => 'offline', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{state} = [
        { label => 'state-unknown', set => {
                key_values => [ { name => 'unknown' } ],
                output_template => 'unknown : %s',
                perfdatas => [
                    { label => 'state_unknown', value => 'unknown', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'state-signoff', set => {
                key_values => [ { name => 'signoff' } ],
                output_template => 'signed off : %s',
                perfdatas => [
                    { label => 'state_signoff', value => 'signoff', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'state-signon', set => {
                key_values => [ { name => 'signon' } ],
                output_template => 'signed on : %s',
                perfdatas => [
                    { label => 'state_signon', value => 'signon', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'state-closed', set => {
                key_values => [ { name => 'closed' } ],
                output_template => 'closed : %s',
                perfdatas => [
                    { label => 'state_closed', value => 'closed', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'state-paused', set => {
                key_values => [ { name => 'paused' } ],
                output_template => 'paused : %s',
                perfdatas => [
                    { label => 'state_paused', value => 'paused', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{merchandise} = [
        { label => 'merchandise-rep-unknown', set => {
                key_values => [ { name => 'unknown' } ],
                output_template => 'unknown : %s',
                perfdatas => [
                    { label => 'merchandise_rep_unknown', value => 'unknown', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'merchandise-rep-ok', set => {
                key_values => [ { name => 'ok' } ],
                output_template => 'ok : %s',
                perfdatas => [
                    { label => 'merchandise_rep_ok', value => 'ok', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'merchandise-rep-suspended', set => {
                key_values => [ { name => 'suspended' } ],
                output_template => 'suspended : %s',
                perfdatas => [
                    { label => 'merchandise_rep_suspended', value => 'suspended', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'merchandise-rep-error', set => {
                key_values => [ { name => 'error' } ],
                output_template => 'error : %s',
                perfdatas => [
                    { label => 'merchandise_rep_error', value => 'error', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{transaction} = [
        { label => 'transaction-rep-unknown', set => {
                key_values => [ { name => 'unknown' } ],
                output_template => 'unknown : %s',
                perfdatas => [
                    { label => 'transaction_rep_unknown', value => 'unknown', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'transaction-rep-ok', set => {
                key_values => [ { name => 'ok' } ],
                output_template => 'ok : %s',
                perfdatas => [
                    { label => 'transaction_rep_ok', value => 'ok', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'transaction-rep-suspended', set => {
                key_values => [ { name => 'suspended' } ],
                output_template => 'suspended : %s',
                perfdatas => [
                    { label => 'transaction_rep_suspended', value => 'suspended', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'transaction-rep-error', set => {
                key_values => [ { name => 'error' } ],
                output_template => 'error : %s',
                perfdatas => [
                    { label => 'transaction_rep_error', value => 'error', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Points of sale ";
}

sub prefix_state_output {
    my ($self, %options) = @_;

    return "State ";
}

sub prefix_merchandise_output {
    my ($self, %options) = @_;

    return "Merchandise replication ";
}

sub prefix_transaction_output {
    my ($self, %options) = @_;

    return "Transaction replication ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "database:s" => { name => 'database', default => 'Framework' },
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => "SELECT WORKSTATION_ID, ONLINE, FO_STATE, MERCHANDISE_REPLICATION, TRANSACTION_REPLICATION 
                                  FROM " . $self->{option_results}->{database} . ".dbo.WORKSTATION_STATUS");

    $self->{global} = { total => 0, online => 0, offline => 0 };
    $self->{state} = { unknown => 0, signoff => 0, signon => 0, closed => 0, paused => 0 };
    $self->{merchandise} = { unknown => 0, ok => 0, suspended => 0, error => 0 }; 
    $self->{transaction} = { unknown => 0, ok => 0, suspended => 0, error => 0 };

    my %map_status = (0 => 'offline', 1 => 'online');
    my %map_state = (0 => 'unknown', 1 => 'signoff', 2 => 'signon', 3 => 'closed', 4 => 'paused');
    my %map_merch_rep_status = (0 => 'unknown', 1 => 'ok', 2 => 'suspended', 3 => 'error');
    my %map_trans_rep_status = (0 => 'unknown', 1 => 'ok', 2 => 'suspended', 3 => 'error');

    while (my $row = $self->{sql}->fetchrow_hashref()) {
        $self->{global}->{total}++;
        $self->{global}->{$map_status{$row->{ONLINE}}}++
            if (defined($map_status{$row->{ONLINE}}));
        $self->{state}->{$map_state{$row->{FO_STATE}}}++
            if (defined($map_state{$row->{FO_STATE}}));
        $self->{merchandise}->{$map_merch_rep_status{$row->{MERCHANDISE_REPLICATION}}}++
            if (defined($map_merch_rep_status{$row->{MERCHANDISE_REPLICATION}}));
        $self->{transaction}->{$map_trans_rep_status{$row->{TRANSACTION_REPLICATION}}}++
            if (defined($map_trans_rep_status{$row->{TRANSACTION_REPLICATION}}));
    }
}

1;

__END__

=head1 MODE

Check points of sale status

=over 8

=item B<--database>

Database name (default: 'Framework').

=item B<--warning-*>

Threshold warning.
Can be: 'online, offline, state-unknown, state-signoff, state-signon, state-closed, state-paused, 
merchandise-rep-unknown, merchandise-rep-ok, merchandise-rep-suspended, merchandise-rep-error, 
transaction-rep-unknown, transaction-rep-ok, transaction-rep-suspended, transaction-rep-error'.

=item B<--critical-*>

Threshold critical.
Can be: 'online, offline, state-unknown, state-signoff, state-signon, state-closed, state-paused, 
merchandise-rep-unknown, merchandise-rep-ok, merchandise-rep-suspended, merchandise-rep-error, 
transaction-rep-unknown, transaction-rep-ok, transaction-rep-suspended, transaction-rep-error'.

=back

=cut

