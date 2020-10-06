#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::postgres::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'backends'         => 'database::postgres::mode::backends',
        'connection-time'  => 'centreon::common::protocols::sql::mode::connectiontime',
        'database-size'    => 'database::postgres::mode::databasesize',
        'hitratio'         => 'database::postgres::mode::hitratio',
        'locks'            => 'database::postgres::mode::locks',
        'list-databases'   => 'database::postgres::mode::listdatabases',
        'query-time'       => 'database::postgres::mode::querytime',
        'sql'              => 'centreon::common::protocols::sql::mode::sql',
        'sql-string'       => 'centreon::common::protocols::sql::mode::sqlstring',
        'statistics'       => 'database::postgres::mode::statistics',
        'tablespace'       => 'database::postgres::mode::tablespace',
        'timesync'         => 'database::postgres::mode::timesync',
        'vacuum'           => 'database::postgres::mode::vacuum',
    );

    $self->{sql_modes}->{psqlcmd} = 'database::postgres::psqlcmd';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'host:s@'      => { name => 'db_host' },
            'port:s@'      => { name => 'db_port' },
            'database:s@'  => { name => 'db_name' }
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{db_host})) {
        @{$self->{sqldefault}->{dbi}} = ();
        @{$self->{sqldefault}->{psqlcmd}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{db_host}}); $i++) {
            $self->{sqldefault}->{dbi}->[$i] = { data_source => 'Pg:host=' . $options_result->{db_host}->[$i] };
            $self->{sqldefault}->{psqlcmd}->[$i] = { host => $options_result->{db_host}->[$i] };
            if (defined($options_result->{db_port}->[$i])) {
                $self->{sqldefault}->{dbi}->[$i]->{data_source} .= ';port=' . $options_result->{db_port}->[$i];
                $self->{sqldefault}->{psqlcmd}->[$i]->{port} = $options_result->{db_port}->[$i];
            }
            $options_result->{db_name}->[$i] = (defined($options_result->{db_name}[$i]) && $options_result->{db_name}->[$i] ne '') ? $options_result->{db_name}->[$i] : 'postgres';
            $self->{sqldefault}->{dbi}->[$i]->{data_source} .= ';database=' . $options_result->{db_name}->[$i];
            $self->{sqldefault}->{psqlcmd}->[$i]->{dbname} = $options_result->{db_name}->[$i];
        }
    }

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Postgres Server.

=over 8

You can use following options or options from 'sqlmode' directly.

=item B<--host>

Hostname to query.

=item B<--port>

Database Server Port.

=item B<--database>

Database Name. (default: postgres)

=back

=cut
