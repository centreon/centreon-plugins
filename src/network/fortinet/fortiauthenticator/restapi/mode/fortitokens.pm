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

package network::fortinet::fortiauthenticator::restapi::mode::fortitokens;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;
use POSIX qw/floor/;

sub custom_output {
    my ($self, %options) = @_;

    sprintf("[Tokens] total:%s - assigned:%s(%.2f%%) - available:%s(%.2f%%) - pending:%s(%.2f%%)",
                $self->{result_values}->{total},
                $self->{result_values}->{assigned},
                $self->{result_values}->{assigned_prct},
                $self->{result_values}->{available},
                $self->{result_values}->{available_prct},
                $self->{result_values}->{pending},
                $self->{result_values}->{pending_prct}
   )
}

my @values = ( { name => 'total' }, { name => 'pending' },
               { name => 'assigned' }, { name => 'available' },
               { name => 'pending_prct'}, { name => 'assigned_prct' },
               { name => 'available_prct' } );

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'fortitokens', type => 0 }
    ];

    $self->{maps_counters}->{fortitokens} = [
        {   label => 'total', nlabel => 'tokens.total.count',
            set => {
                key_values => \@values,
                threshold_use => 'total',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        {   label => 'assigned', nlabel => 'tokens.assigned.count', display_ok => 0,
            set => {
                key_values => \@values,
                threshold_use => 'pending',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        {   label => 'pending', nlabel => 'tokens.pending.count', display_ok => 0,
            set => {
                key_values => \@values,
                threshold_use => 'assigned',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        {   label => 'available', nlabel => 'tokens.available.count', display_ok => 0,
            set => {
                key_values => \@values,
                threshold_use => 'available',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        {   label => 'assigned-prct', nlabel => 'tokens.assigned.percentage', display_ok => 0, set => {
                key_values => \@values,
                threshold_use => 'assigned_prct',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ]
            }
        },
        {   label => 'pending-prct', nlabel => 'tokens.pending.percentage', display_ok => 0, set => {
                key_values => \@values,
                threshold_use => 'pending_prct',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ]
            }
        },
        {   label => 'available-prct', nlabel => 'tokens.available.percentage', display_ok => 0, set => {
                key_values => \@values,
                threshold_use => 'available_prct',
                closure_custom_output => $self->can('custom_output'),
                perfdatas => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-type:s' => { name => 'include_type', default => '' },
        'exclude-type:s' => { name => 'exclude_type', default => '' },
    });

    return $self;
}

sub manage_selection { 
    my ($self, %options) = @_;

    my $results = $options{custom}->fortiauthentificator_list_tokens();

    $self->{fortitokens}->{$_} = 0
        foreach qw/total available assigned pending/;

    foreach my $token (@{$results}) {
        next if is_excluded($token->{type}, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type});

        next unless $token->{serial} && $token->{status} && $token->{status} =~ /^(?:available|pending|assigned)$/;

        $self->{fortitokens}->{total}++;
        $self->{fortitokens}->{ $token->{status} }++;
    }

    $self->{output}->option_exit(short_msg => "No tokens found.")
        unless $self->{fortitokens}->{total};

    $self->{fortitokens}->{ $_.'_prct' } = $self->{fortitokens}->{ $_ } * 100 / $self->{fortitokens}->{total}
        foreach qw/available assigned pending/;
}

1;

__END__

=head1 MODE

Check FortiTokens.

=over 8

=item B<--include-type>

Filter by token type (can be a regexp).
Value can be C<ftk> or C<ftm>.

=item B<--exclude-type>

Exclude by token type (can be a regexp).
Value can be C<ftk> or C<ftm>.

=item B<--warning-assigned>

Threshold.

=item B<--critical-assigned>

Threshold.

=item B<--warning-assigned-prct>

Threshold in percentage.

=item B<--critical-assigned-prct>

Threshold in percentage.

=item B<--warning-available>

Threshold.

=item B<--critical-available>

Threshold.

=item B<--warning-available-prct>

Threshold in percentage.

=item B<--critical-available-prct>

Threshold in percentage.

=item B<--warning-pending>

Threshold.

=item B<--critical-pending>

Threshold.

=item B<--warning-pending-prct>

Threshold in percentage.

=item B<--critical-pending-prct>

Threshold in percentage.

=item B<--warning-total>

Threshold.

=item B<--critical-total>

Threshold.

=back

=cut
