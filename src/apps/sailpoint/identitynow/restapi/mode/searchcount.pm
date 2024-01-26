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

package apps::sailpoint::identitynow::restapi::mode::searchcount;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'results-count', nlabel => 'query.results.count', set => {
                key_values => [ { name => 'count' } ],
                closure_custom_output => $self->can('custom_status_output'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = $self->{instance_mode}->{option_results}->{output};
    while ($msg =~ /%\{(.*?)\}/g) {
        my $key = $1;
        if (defined($self->{result_values}->{$key})) {
            $msg =~ s/%\{$key\}/$self->{result_values}->{$key}/g;
        }
    }

    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'query:s'   => { name => 'query' },
        'output:s'  => { name => 'output', default => 'Number of results: %{count}' },
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{count} = $options{custom}->search_count(query => $self->{option_results}->{query});
}

1;

__END__

=head1 MODE

Performs a search with a provided query and returns the
count of results.

More information on 'https://developer.sailpoint.com/idn/api/v3/search-count/'.

=over 8

=item B<--query>

Query parameters used to construct an Elasticsearch query
object (see documentation).

=item B<--output>

Output to print after retrieving the count of results
(default: "Number of results: %{count}").

=item B<--warning-results-count> B<--critical-results-count>

Thresholds on count of results.

=back

=cut
