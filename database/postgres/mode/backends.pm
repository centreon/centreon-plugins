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

package database::postgres::mode::backends;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "exclude:s"               => { name => 'exclude', },
                                  "noidle"                  => { name => 'noidle', },
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
    
    my $noidle = '';
    if (defined($self->{option_results}->{noidle})) {
        if ($self->{sql}->is_version_minimum(version => '9.2')) {
            $noidle = " AND state <> 'idle'";
        } else {
            $noidle = " AND current_query <> '<IDLE>'";
        }
    }

    my $query = "SELECT COUNT(datid) AS current,
  (SELECT setting AS mc FROM pg_settings WHERE name = 'max_connections') AS mc,
  d.datname
FROM pg_database d
LEFT JOIN pg_stat_activity s ON (s.datid = d.oid $noidle)
GROUP BY d.datname
ORDER BY d.datname";
    $self->{sql}->query(query => $query);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All client database connections are ok.");

    my $database_check = 0;
    my $result = $self->{sql}->fetchall_arrayref();
    
    foreach my $row (@{$result}) {
        if (defined($self->{option_results}->{exclude}) && $$row[2] !~ /$self->{option_results}->{exclude}/) {
            $self->{output}->output_add(long_msg => "Skipping database '" . $$row[2] . '"');
            next;
        }       
        
        $database_check++;
        my $used = $$row[0];
        my $max_connections = $$row[1];
        my $database_name = $$row[2];
        
        my $prct_used = ($used * 100) / $max_connections;
        my $exit_code = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("Database '%s': %.2f%% client connections limit reached (%d of max. %d)",
                                                    $database_name, $prct_used, $used, $max_connections));
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Database '%s': %.2f%% client connections limit reached (%d of max. %d)",
                                                    $database_name, $prct_used, $used, $max_connections));
        }
        
        $self->{output}->perfdata_add(label => 'connections_' . $database_name,
                                      value => $used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $max_connections, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $max_connections, cast_int => 1),
                                      min => 0, max => $max_connections);
    }
    if ($database_check == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'No database checked. (permission or a wrong exclude filter)');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the current number of connections for one or more databases

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--exclude>

Filter databases.

=item B<--noidle>

Idle connections are not counted.

=back

=cut
