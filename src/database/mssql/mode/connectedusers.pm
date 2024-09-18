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

package database::mssql::mode::connectedusers;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'database-name:s' => { name => 'database_name' },
        'uniq-users'      => { name => 'uniq_users' }
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'connected_user', type => 0 },
    ];

    $self->{maps_counters}->{connected_user} = [
        { label => 'connected-user', nlabel => 'mssql.users.connected.count', set => {
                key_values => [ { name => 'value' } ],
                output_template => '%s connected user(s)',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT DB_NAME(dbid) as dbname, loginame FROM master..sysprocesses WHERE spid >= '51'});
    my $results = $options{sql}->fetchall_arrayref();

    $self->{connected_user} = { value => 0 };
    my %logins = ();
    foreach my $row (@$results) {
        $row->[0] = '' if (!defined($row->[0]));

        next if (defined($self->{option_results}->{database_name}) && $self->{option_results}->{database_name} ne '' && 
            $row->[0] !~ /$self->{option_results}->{database_name}/);
        next if (defined($self->{option_results}->{uniq_users}) && defined($logins{ $row->[1] }));
        $logins{ $row->[1] } = 1;
        $self->{connected_user}->{value}++;
    }
}

1;

__END__

=head1 MODE

Check MSSQL connected users.

=over 8

=item B<--database-name>

Filter connected users by database name (can be a regexp).

=item B<--uniq-name>

Count users with the same login name once.

=item B<--warning-connected-user>

Warning threshold.

=item B<--critical-connected-user>

Critical threshold.

=back

=cut
