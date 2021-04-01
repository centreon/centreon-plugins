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

package database::mssql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'backup-age'           => 'database::mssql::mode::backupage',
        'blocked-processes'    => 'database::mssql::mode::blockedprocesses',
        'cache-hitratio'       => 'database::mssql::mode::cachehitratio',
        'connected-users'      => 'database::mssql::mode::connectedusers',
        'connection-time'      => 'centreon::common::protocols::sql::mode::connectiontime',
        'dead-locks'           => 'database::mssql::mode::deadlocks',
        'databases-size'       => 'database::mssql::mode::databasessize',
        'failed-jobs'          => 'database::mssql::mode::failedjobs',
        'list-databases'       => 'database::mssql::mode::listdatabases',
        'locks-waits'          => 'database::mssql::mode::lockswaits',
        'page-life-expectancy' => 'database::mssql::mode::pagelifeexpectancy',
        'sql'                  => 'centreon::common::protocols::sql::mode::sql',
        'sql-string'           => 'centreon::common::protocols::sql::mode::sqlstring',
        'tables'               => 'database::mssql::mode::tables',
        'transactions'         => 'database::mssql::mode::transactions'
    };

    $self->{sql_modes}->{dbi} = 'database::mssql::dbi';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'hostname:s@'       => { name => 'hostname' },
            'port:s@'           => { name => 'port' },
            'server:s@'         => { name => 'server' },
            'database:s'        => { name => 'database' },
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{server})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{server}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Sybase:server=' . $options_result->{server}[$i] };
            if ((defined($options_result->{database})) && ($options_result->{database} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';database=' . $options_result->{database};
            }
        }
    }

    if (defined($options_result->{hostname})) {
        @{$self->{sqldefault}->{dbi}} = ();

        for (my $i = 0; $i < scalar(@{$options_result->{hostname}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Sybase:host=' . $options_result->{hostname}[$i] };
            if (defined($options_result->{port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{port}[$i];
            }
            if ((defined($options_result->{database})) && ($options_result->{database} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';database=' . $options_result->{database};
            }
        }
    }

    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check MSSQL Server.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

Database Server Port.

=item B<--server>

An alternative to hostname+port. <server> will be looked up in the file freetds.conf.

=item B<--database>

Select database .

=back

=cut
