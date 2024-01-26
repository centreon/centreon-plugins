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

package database::postgres::mode::querytime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'      => { name => 'warning' },
        'critical:s'     => { name => 'critical' },
        'exclude:s'      => { name => 'exclude' },
        'exclude-user:s' => { name => 'exclude_user' },
        'idle'           => { name => 'idle' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
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

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'All databases queries time are ok.'
    );
    my $dbquery = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        next if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} ne '' && $row->{datname} =~ /$self->{option_results}->{exclude}/);

        if (!defined($dbquery->{$row->{datname}})) {
            $dbquery->{ $row->{datname} } = { total => 0, code => {} };
        }
        next if (!defined($row->{datid}) || $row->{datid} eq ''); # No joint

        next if (defined($self->{option_results}->{exclude_user}) && $self->{option_results}->{exclude_user} ne '' && $row->{usename} =~ /$self->{option_results}->{exclude_user}/);

        my $exit_code = $self->{perfdata}->threshold_check(value => $row->{seconds}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
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

    foreach my $dbname (keys %$dbquery) {
        $self->{output}->perfdata_add(
            nlabel => 'database.longqueries.count',
            instances => $dbname,
            value => $dbquery->{$dbname}->{total},
            min => 0
        );
        foreach my $exit_code (keys %{$dbquery->{$dbname}->{code}}) {
            $self->{output}->output_add(
                severity => $exit_code,
                short_msg => sprintf(
                    "%d request exceed " . lc($exit_code) . " threshold on database '%s'",
                    $dbquery->{$dbname}->{code}->{$exit_code}, $dbname
                )
            );
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
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

=item B<--exclude>

Filter databases.

=item B<--exclude-user>

Filter users.

=item B<--idle>

Idle queries are counted.

=back

=cut
