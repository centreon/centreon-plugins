#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package database::mssql::mode::queries;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_queries_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Query with session ID '%s' started since '%s' for %s (CPU time: %s, wait time: %s) [status: %s] [command: %s]",
        $self->{result_values}->{session_id},
        $self->{result_values}->{start_time},
        $self->{result_values}->{duration_human},
        $self->{result_values}->{cpu_time_human},
        $self->{result_values}->{wait_time_human},
        $self->{result_values}->{status},
        $self->{result_values}->{command}
    );

    return $msg;
}

sub custom_queries_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{session_id} = $options{new_datas}->{$self->{instance} . '_session_id'};
    $self->{result_values}->{start_time} = $options{new_datas}->{$self->{instance} . '_start_time'};
    $self->{result_values}->{duration} = $options{new_datas}->{$self->{instance} . '_duration_ms'};
    $self->{result_values}->{duration_human} = centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration} / 1000);
    $self->{result_values}->{cpu_time} = $options{new_datas}->{$self->{instance} . '_cpu_time_ms'};
    $self->{result_values}->{cpu_time_human} = centreon::plugins::misc::change_seconds(value => $self->{result_values}->{cpu_time} / 1000);
    $self->{result_values}->{wait_time} = $options{new_datas}->{$self->{instance} . '_wait_time_ms'};
    # When query is multi-threaded, wait time can be < 0 (because cpu time > duration)
    # https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-slow-running-queries#parallel-queries---runner-or-waiter
    $self->{result_values}->{wait_time} = 0 if ($self->{result_values}->{wait_time} < 0); 
    $self->{result_values}->{wait_time_human} = centreon::plugins::misc::change_seconds(value => $self->{result_values}->{wait_time} / 1000);
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{command} = $options{new_datas}->{$self->{instance} . '_command'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'queries', type => 2, display_counter_problem => { nlabel => 'mssql.queries.problem.count', min => 0 },
          group => [ { name => 'problem', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'queries-total', nlabel => 'mssql.queries.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of queries: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{problem} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'session_id' }, { name => 'start_time' }, { name => 'duration_ms' },
                    { name => 'cpu_time_ms' }, { name => 'wait_time_ms' }, { name => 'status' }, { name => 'command' } ],
                closure_custom_calc => $self->can('custom_queries_calc'),
                closure_custom_output => $self->can('custom_queries_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-status:s"   => { name => 'filter_status' },
        "filter-command:s"  => { name => 'filter_command' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{queries}->{global} = { problem => {} };

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT 
            session_id
            , start_time
            , total_elapsed_time AS duration_ms
            , cpu_time AS cpu_time_ms
            , total_elapsed_time - cpu_time AS wait_time_ms
            , status
            , command
        FROM sys.dm_exec_requests
        WHERE session_id != @@SPID;
    });

    while ((my $row = $options{sql}->fetchrow_hashref())) {
        next if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne ''
            && $row->{status} !~ /$self->{option_results}->{filter_status}/);
        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne ''
            && $row->{command} !~ /$self->{option_results}->{filter_command}/);
        $self->{queries}->{global}->{problem}->{$row->{session_id}} = $row;
    }
    
    $self->{global} = { total => scalar(keys %{$self->{queries}->{global}->{problem}}) };
}

1;

__END__

=head1 MODE

Check MSSQL queries in execution (sys.dm_exec_requests) and set status
thresholds on queries information to detect problems.

See https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-requests-transact-sql

Inspired by https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-slow-running-queries

=over 8

=item B<--filter-status>

Filter the status of the queries with a regular expression.

=item B<--filter-command>

Filter the type of command that is being processed by the queries
with a regular expression.

=item B<--warning-queries-total>

Warning threshold on the total number of queries after filtering.

=item B<--critical-queries-total>

Critical threshold on the total number of queries after filtering.

=item B<--warning-status>

Define the conditions to match for the querie to be considered WARNING (default: '')

You can use the following variables: %{session_id}, %{start_time}, %{duration},
%{cpu_time}, %{wait_time}, %{status}, %{command}

Example:

--warning-status='%{status} =~ /running/ && %{wait_time} > 20000'

=item B<--critical-status>

Define the conditions to match for the querie to be considered CRITICAL (default: '').

You can use the following variables: %{session_id}, %{start_time}, %{duration} (ms),
%{cpu_time} (ms), %{wait_time} (ms), %{status}, %{command}

Example:

--critical-status='%{status} !~ /sleeping|background|suspended/ && %{duration} > 30000'

=back

=cut