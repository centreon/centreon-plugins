#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package database::elasticsearch::restapi::mode::query;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/slurp_file/;

sub custom_result_output {
    my ($self, %options) = @_;
    return "Result #".$self->{result_values}->{index}.": '".$self->{result_values}->{value} . "'";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'query_results', type => 1, message_multiple => 'All values are OK', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'query.match.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Result count: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    $self->{maps_counters}->{query_results} = [
        {   label => 'value', type => 2,
            set => {
                key_values => [ { name => 'value' }, { name => 'index' } ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_output => $self->can('custom_result_output'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'query:s'     => { name => 'query', default => '' },
        'index:s'     => { name => 'index', default => '' },
        'lookup:s'    => { name => 'lookup', default => '$.hits.hits[*]._id' }
    });

    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'JSON::Path::Evaluator',
                                               error_msg => "Cannot load module 'JSON::Path::Evaluator'.");

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = $self->{option_results}->{$_} for qw/query index lookup/;

    $self->{output}->option_exit(short_msg => 'Please set --query option.')
        if $self->{query} eq '';

    # query parameter points to a file when starting with '@'
    if ($self->{query} =~ /[\t\s]*@(.+)/) {
        my $file = $1;
        $self->{output}->option_exit(short_msg => "Invalid query parameter: '$file' is not a valid file.")
            unless -f $file;
        $self->{output}->output_add(long_msg => "Reading query from file '$file'.", debug => 1);
        $self->{query} = slurp_file(file => $file);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->search( index => $self->{index},
                                           query => $self->{query} );
    my @data;

    eval {
      @data = JSON::Path::Evaluator::evaluate_jsonpath($result, $self->{lookup});
    };

    # display only first line of error message
    $self->{output}->option_exit(exit_litteral => 'critical', short_msg => "Invalud lookup parameter '$self->{lookup}': ".($@ =~ /^(.*)$/ && $1))
        if $@;

    $self->{global} = {
        count => @data || 0
    };

    for (0..$#data) {
        $self->{query_results}->{$_} = { "index" => $_,
                                         "value" => $data[$_] }
    }
}

1;

__END__

=head1 MODE

Perform queries against the Elasticsearch API

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^count$'

=item B<--query>

Set query to execute (required).

Please refer to https://www.elastic.co/docs/api/doc/elasticsearch/group/endpoint-search for more information about query syntax.

If the query starts with '@', it is considered as a file name to read the query from.

Values returned by the query are displayed when C<--verbose> is set.

=item B<--index>

Specify the index to query. Defaults to '' (searches all index).

=item B<--lookup>

Set the JSONPath expression to extract values from the query result. (default: '$.hits.hits[*]._id')

You might have to adjust the lookup value depending on the query.

C<count> and C<value> metrics are based on values extracted using this expression.

Please refer to https://goessner.net/articles/JsonPath/ for more information about JSONPath syntax.

=item B<--warning-count>

Threshold on the number of results.

=item B<--critical-count>

Threshold on the number of results.

=item B<--warning-value>

Threshold.
Define the warning threshold based on values.
Variables %{index} and %{value} can be used.
Example: --warning-value='%{value} !~ /OK/'

=item B<--critical-value>

Threshold.
Define the critical threshold based on values.
Variables %{index} and %{value} can be used.
Example: --critical-value='%{value} =~ /FAILED/'

=back

=cut
