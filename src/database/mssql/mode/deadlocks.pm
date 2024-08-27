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

package database::mssql::mode::deadlocks;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'deadlocks', type => 0 },
    ];

    $self->{maps_counters}->{deadlocks} = [
        { label => 'deadlocks', nlabel => 'mssql.deadlocks.count', set => {
                key_values => [ { name => 'value' } ],
                output_template => '%.2f dead locks/s',
                perfdatas => [
                    { template => '%.2f', min => 0 },
                ],
            }
        },
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-database:s" => { name => 'filter_database' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT 
            instance_name, cntr_value
        FROM
            sys.dm_os_performance_counters
        WHERE
            object_name = 'SQLServer:Locks'
        AND
            counter_name = 'Number of Deadlocks/sec%'
    });

    my $query_result = $options{sql}->fetchall_arrayref();
    $self->{deadlocks}->{value} = 0;

    foreach my $row (@{$query_result}) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne ''
                    && $$row[0] !~ /$self->{option_results}->{filter_database}/);
        $self->{deadlocks}->{value} += $$row[1];
    }
}

1;

__END__

=head1 MODE

Check MSSQL dead locks per second

=over 8

=item B<--warning-deadlocks>

Warning threshold number of dead locks per second.

=item B<--critical-deadlocks>

Critical threshold number of dead locks per second.

=item B<--filter-database>

Filter the databases to monitor with a regular expression.

=back

=cut
