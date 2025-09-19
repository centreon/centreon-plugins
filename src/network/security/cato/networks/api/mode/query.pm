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

package network::security::cato::networks::api::mode::query;

use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng catalog_status_threshold);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
            "operation:s"  => { name => 'operation' },
            "query:s"      => { name => 'query' },
            "argument:s@"  => { name => 'argument', default => [] },
            "lookup:s@"    => { name => 'lookup', default => [] },
    });

    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'JSON::Path::Evaluator',
                                               error_msg => "Cannot load module 'JSON::Path::Evaluator'.");

    return $self;
}

sub custom_result_output {
    my ($self, %options) = @_;
    return sprintf("Result %d: %s", $self->{result_values}->{index}, $self->{result_values}->{result});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'results', type => 1, message_multiple => 'All results are ok', }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'results.count',
            set => {
                key_values => [ { name => 'count' } ],
                perfdatas => [ { template => '%d', min => 0 } ]
            },
        },
    ];
    $self->{maps_counters}->{results} = [
        {   label => 'result', type => 2,
            set => {
                closure_custom_output => $self->can('custom_result_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                key_values => [ { name => 'result' }, { name => 'index' } ],
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    foreach my $opt (qw/query operation/) {
        $self->{$opt} = $self->{option_results}->{$opt};

        $self->{output}->option_exit(short_msg => "Need to specify a --".($opt=~s/_/-/gr)." option.")
            unless $self->{$opt};
    }

    # argument and lookup are comma separated list which can be provided multiple times
    $self->{arguments} = [ map { split ',' } @{$self->{option_results}->{argument}} ];
    $self->{lookups} = [ map { split ',' } @{$self->{option_results}->{lookup}} ];

    $self->{output}->option_exit(short_msg => "Need to specify lookups in --lookup option.")
        unless @{$self->{lookups}};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->send_custom_query(accound_id => $self->{account_id},
                                                       operation => $self->{operation},
                                                       query => $self->{query},
                                                       arguments => $self->{arguments});

    my @result;
    foreach my $lookup (@{$self->{lookups}}) {
        eval {
            push @result, JSON::Path::Evaluator::evaluate_jsonpath($response, $lookup);
        };
        $self->{output}->option_exit(short_msg => "'$lookup' parameter is invalid".($@=~/(.*)/ && ": $1"))
            if $@;
    }

    $self->{global} = { count => scalar(@result) };

    for (0..$#result) {
        $self->{results}->{$_} = { result => $result[$_],
                                   index => $_ };
    }
}

1;

__END__

=head1 MODE

Launch custom queries to retrieve values from the Cato Neworks API

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='result'

=item B<--operation>

Define the name of the operation to be passed to the API.
Example: C<accoundSnapshot>, C<accountlookups>
Refer to Cato API documentation for more information about supported operations.

=item B<--argument>

Define the optional arguments to be passed to the specified operation.
Those arguments varies according to the operation.
This option can be used multiple times and multiple values can be passed as a comma separated list.
Refer to Cato API documentation for more information about supported arguments.

=item B<--query>

Define the data structure to retrieve from the API.

For example using these perameters C<--accoundID=XX --operation=accountMetrics
--argument='timeFrame: "last.PT5M"' --argument="groupInterfaces: true" --query='from to'>
will produce the following query (in its unexpanded form):

    {
      accountMetrics(
        accountID: XX,
        timeFrame: "last.PT5M",
        groupInterfaces: true
      ) {
        from
        to
      }
    }

=item B<--lookup>

What to lookup in JSON response (JSON XPath string).
This option can be used multiple times and multiple values can be passed as a comma separated list.

Considering the following returned data:

    {
      "sites": [
        {
          "id": "1001",
          "connectivityStatus": "Connected",
          "info": {
            "name": "Paris",
          }
        },
        {
          "id": "1002",
          "connectivityStatus": "Degraded",
          "info": {
            "name": "Toulouse",
          }
        }
      ]
    }

Using those lookups will return:

--lookup='$.sites[1].info.name'  will return 'Toulouse'
--lookup='$.sites[?(@.id=1001)].info.name'  will return 'Paris'
--lookup='$.sites[?(@connectivityStatus=Degraded)].id' will return '1002'

Refer to http://goessner.net/articles/JsonPath/ for more information.

=item B<--warning-count>

Threshold.
Returned results count.

=item B<--critical-count>

Threshold.
Returned results count.

=item B<--warning-result>

Threshold.
%{index} represents the result position and %{result} is the result value.

=item B<--critical-result>

Threshold.
%{index} represents the result position and %{result} is the result value.

String value example: --critical-result='%{result} =~ /fail/i'
Numeric value example: --critical-result='%{result} > 100'
