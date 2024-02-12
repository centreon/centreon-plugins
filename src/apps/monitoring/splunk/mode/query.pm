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

package apps::monitoring::splunk::mode::query;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'query-matches', nlabel => 'splunk.query.matches.count', set => {
                key_values => [ { name => 'query_matches' } ],
                output_template => 'query matches: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'query:s'     => { name => 'query' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --query option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query_count = $options{custom}->query_count(
        query => $self->{option_results}->{query},
        timeframe => $self->{option_results}->{timeframe}
    );

    $self->{global} = {
        query_matches => $query_count
    };
}

1;

__END__

=head1 MODE

Check number of results for a query. 

=over 8

=item B<--query>

Specify a query to be made and check matching number. 

Query has to start with "search ".
Example: --query='search host="prod-server" "ERROR" earliest=-150000min'

=item B<--warning-query-matches> 

Warning threshold for query matches.

Example: --warning-query-matches=5

=item B<--critical-query-matches>

Critical threshold for query matches.

Example: --critical-query-matches=15

=back

=cut
