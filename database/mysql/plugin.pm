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

package database::mysql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'connection-time'           => 'centreon::common::protocols::sql::mode::connectiontime',
        'databases-size'            => 'database::mysql::mode::databasessize',
        'innodb-bufferpool-hitrate' => 'database::mysql::mode::innodbbufferpoolhitrate',
        'long-queries'              => 'database::mysql::mode::longqueries',
        'myisam-keycache-hitrate'   => 'database::mysql::mode::myisamkeycachehitrate',
        'open-files'                => 'database::mysql::mode::openfiles',
        'qcache-hitrate'            => 'database::mysql::mode::qcachehitrate',
        'queries'                   => 'database::mysql::mode::queries',
        'replication'               => 'database::mysql::mode::replication',
        'slow-queries'              => 'database::mysql::mode::slowqueries',
        'sql'                       => 'centreon::common::protocols::sql::mode::sql',
        'sql-string'                => 'centreon::common::protocols::sql::mode::sqlstring',
        'threads-connected'         => 'database::mysql::mode::threadsconnected',
        'uptime'                    => 'database::mysql::mode::uptime'
    );

    $self->{sql_modes}->{dbi} = 'database::mysql::dbi';
    $self->{sql_modes}->{mysqlcmd} = 'database::mysql::mysqlcmd';

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'host:s@'   => { name => 'db_host' },
            'port:s@'   => { name => 'db_port' },
            'socket:s@' => { name => 'db_socket' }
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{db_host})) {
        @{$self->{sqldefault}->{dbi}} = ();
        @{$self->{sqldefault}->{mysqlcmd}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{db_host}}); $i++) {
            $self->{sqldefault}->{dbi}->[$i] = { data_source => 'mysql:host=' . $options_result->{db_host}[$i] };
            $self->{sqldefault}->{mysqlcmd}->[$i] = { host => $options_result->{db_host}[$i] };
            if (defined($options_result->{db_port}[$i])) {
                $self->{sqldefault}->{dbi}->[$i]->{data_source} .= ';port=' . $options_result->{db_port}[$i];
                $self->{sqldefault}->{mysqlcmd}->[$i]->{port} = $options_result->{db_port}[$i];
            }
            if (defined($options_result->{db_socket}[$i])) {
                $self->{sqldefault}->{dbi}->[$i]->{data_source} .= ';mysql_socket=' . $options_result->{db_socket}[$i];
                $self->{sqldefault}->{mysqlcmd}->[$i]->{socket} = $options_result->{db_socket}[$i];
            }
        }
    }

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check MySQL Server.

=over 8

You can use following options or options from 'sqlmode' directly.

=item B<--host>

Hostname to query.

=item B<--port>

Database Server Port.

=back

=cut
