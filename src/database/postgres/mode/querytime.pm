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

package database::postgres::mode::querytime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::misc qw/is_excluded is_empty/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'           => { name => 'warning' },
        'critical:s'          => { name => 'critical' },
        'include-database:s'  => { name => 'include_database', default => '' },
        'exclude-database:s'  => { name => 'exclude_database', default => '' },
        'include:s'           => { name => 'include_database' },
        'exclude:s'           => { name => 'exclude_database' },
        'include-user:s'      => { name => 'include_user', default => '' },
        'exclude-user:s'      => { name => 'exclude_user', default => '' },
        'idle'                => { name => 'idle' }
    });

    return $self;
}

sub custom_long_output {
    my ($self, %options) = @_;

    my @output;
    foreach my $exit_code ('critical', 'warning', 'unknwon') {
        next unless $self->{result_values}->{code}->{$exit_code};

        my $val = $self->{result_values}->{code}->{$exit_code};
        push @output, sprintf(
            "%d request%s exceed %s threshold on database '%s'",
            $val, $val == 1 ? '' : 's', $exit_code, $self->{result_values}->{database}
        );
    }

    @output = ( sprintf("All queries time are ok on database '%s'",  $self->{result_values}->{database}) ) unless @output;

    return join ', ', @output;
}

sub custom_threshold_check {
    my ($self, %options) = @_;

    foreach my $exit_code ('critical', 'warning', 'unknwon') {
        return $exit_code if $self->{result_values}->{code}->{$exit_code};
    }

    return 'ok';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'longqueries', type => 1, message_multiple => 'All databases queries time are ok' },
    ];

    $self->{maps_counters}->{longqueries} = [
        { label => 'total', nlabel => 'database.longqueries.count', set => {
                key_values => [ { name => 'total' }, { name => 'database' }, {name => 'code' } ],
                #                threshold_use => 'total',
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_threshold_check => $self->can('custom_threshold_check'),
                output_template => "%s request exceed thresholds",
                perfdatas => [
                    { template => '%s', min => 0, unit => '', label_extra_instance => 1  },
                ],
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{output}->option_exit(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.")
      unless $self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning});

    $self->{output}->option_exit(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.")
      unless $self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical});
}


sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    my $query;
    if ($options{sql}->is_version_minimum(version => '9.2')) {
        $query = sprintf(
            q{
                SELECT pg_database.datname, pgsa.datid, pgsa.pid, pgsa.usename, pgsa.client_addr, pgsa.query AS current_query, pgsa.state AS state,
                    CASE WHEN pgsa.client_port < 0 THEN 0 ELSE pgsa.client_port END AS client_port,
                    COALESCE(ROUND(EXTRACT(epoch FROM now()-query_start)),0) AS seconds
                FROM pg_database LEFT JOIN pg_stat_activity pgsa ON pg_database.datname = pgsa.datname AND (pgsa.query_start IS NOT NULL AND (%s pgsa.state IS NULL))
                ORDER BY pgsa.query_start, pgsa.pid DESC
            },
            !defined($self->{option_results}->{idle}) ? "pgsa.state NOT LIKE 'idle%' OR" : ''
        );
    } else {
        $query = sprintf(
            q{
                SELECT pg_database.datname, pgsa.datid, pgsa.procpid, pgsa.usename, pgsa.client_addr, pgsa.current_query AS current_query, '' AS state, 
                    CASE WHEN pgsa.client_port < 0 THEN 0 ELSE pgsa.client_port END AS client_port,
                    COALESCE(ROUND(EXTRACT(epoch FROM now()-query_start)),0) AS seconds
                FROM pg_database LEFT JOIN pg_stat_activity pgsa ON pg_database.datname = pgsa.datname AND (pgsa.query_start IS NOT NULL %s)
                ORDER BY pgsa.query_start, pgsa.procpid DESC
            },
            !defined($self->{option_results}->{idle}) ? " AND current_query NOT LIKE '<IDLE>%'" : ''
        );
    }
    $options{sql}->query(query => $query);

    my $dbquery = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        $row->{usename} //= '';
        next if is_excluded($row->{datname}, $self->{option_results}->{include_database}, $self->{option_results}->{exclude_database});
        next if is_excluded($row->{usename}, $self->{option_results}->{include_user}, $self->{option_results}->{exclude_user});

        $dbquery->{ $row->{datname} } = { total => 0, code => {}, database => $row->{datname} }
            unless $dbquery->{$row->{datname}};

        next if is_empty($row->{datid}); # No joint

        my $exit_code = $self->{perfdata}->threshold_check(value => $row->{seconds},
                                                           threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "Request from client '%s' too long (%s sec) on database '%s': %s",
                    defined($row->{client_addr}) ? $row->{client_addr} : 'unknown',
                    defined($row->{seconds}) ? $row->{seconds} : '-',
                    defined($row->{datname}) ? $row->{datname} : '-',
                    defined($row->{current_query}) ? $row->{current_query} : '-'
                )
            );
            $dbquery->{ $row->{datname} }->{total}++;
            $dbquery->{ $row->{datname} }->{code}->{$exit_code}++;
        }
    }

    $self->{longqueries} = $dbquery;


    $self->{output}->output_add(short_msg => $self->{maps_counters_type}->[0]->{message_multiple})
        unless keys %$dbquery;
}

1;

__END__

=head1 MODE

Checks the time of running queries for one or more databases

=over 8

=item B<--warning>

Warning threshold in seconds.

=item B<--critical>

Critical threshold in seconds.

=item B<--include-database>

Filter databases using a regular expression.

=item B<--exclude-database>

Exclude databases using a regular expression.

=item B<--include-user>

Filter users a regular expression.

=item B<--exclude-user>

Exclude users a regular expression.

=item B<--idle>

Idle queries are counted.

=back

=cut
