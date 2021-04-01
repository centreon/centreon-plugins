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

package database::postgres::mode::querytime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "warning:s"               => { name => 'warning', },
        "critical:s"              => { name => 'critical', },
        "exclude:s"               => { name => 'exclude', },
        "exclude-user:s"          => { name => 'exclude_user', },
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
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my $query;
    if ($self->{sql}->is_version_minimum(version => '9.2')) {
        $query = q{
SELECT pg_database.datname, pgsa.datid, pgsa.pid, pgsa.usename, pgsa.client_addr, pgsa.query AS current_query, pgsa.state AS state,
       CASE WHEN pgsa.client_port < 0 THEN 0 ELSE pgsa.client_port END AS client_port,
       COALESCE(ROUND(EXTRACT(epoch FROM now()-query_start)),0) AS seconds
FROM pg_database LEFT JOIN pg_stat_activity pgsa ON pg_database.datname = pgsa.datname AND (pgsa.query_start IS NOT NULL AND (pgsa.state NOT LIKE 'idle%' OR pgsa.state IS NULL))
ORDER BY pgsa.query_start, pgsa.pid DESC
};
    } else {
        $query = q{
SELECT pg_database.datname, pgsa.datid, pgsa.procpid, pgsa.usename, pgsa.client_addr, pgsa.current_query AS current_query, '' AS state,
       CASE WHEN pgsa.client_port < 0 THEN 0 ELSE pgsa.client_port END AS client_port,
       COALESCE(ROUND(EXTRACT(epoch FROM now()-query_start)),0) AS seconds
FROM pg_database LEFT JOIN pg_stat_activity pgsa ON pg_database.datname = pgsa.datname AND (pgsa.query_start IS NOT NULL AND current_query NOT LIKE '<IDLE>%')
ORDER BY pgsa.query_start, pgsa.procpid DESC
};
    }
    
    $self->{sql}->query(query => $query);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All databases queries time are ok.");
    my $dbquery = {};
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (!defined($dbquery->{$row->{datname}})) {
            $dbquery->{$row->{datname}} = { total => 0, code => {} };
        }
        next if (!defined($row->{datid}) || $row->{datid} eq ''); # No joint
        
        if (defined($self->{option_results}->{exclude}) && $row->{datname} !~ /$self->{option_results}->{exclude}/) {
            next;
        }
        if (defined($self->{option_results}->{exclude_user}) && $row->{usename} !~ /$self->{option_results}->{exclude_user}/) {
            next;
        }
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $row->{seconds}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(long_msg => sprintf("Request from client '%s' too long (%d sec) on database '%s': %s",
                                                            $row->{client_addr}, $row->{seconds}, $row->{datname}, $row->{current_query}));
            $dbquery->{$row->{datname}}->{total}++;
            $dbquery->{$row->{datname}}->{code}->{$exit_code}++;
        }
    }
    
    foreach my $dbname (keys %$dbquery) {
        $self->{output}->perfdata_add(label => $dbname . '_qtime_num',
                                      value => $dbquery->{$dbname}->{total},
                                      min => 0);
        foreach my $exit_code (keys %{$dbquery->{$dbname}->{code}}) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("%d request exceed " . lc($exit_code) . " threshold on database '%s'",
                                                             $dbquery->{$dbname}->{code}->{$exit_code}, $dbname));
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

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--exclude>

Filter databases.

=item B<--exclude-user>

Filter users.

=back

=cut
