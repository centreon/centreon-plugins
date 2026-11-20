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

package database::db2::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'collection'       => 'centreon::common::protocols::sql::mode::collection',
        'connection-time'  => 'centreon::common::protocols::sql::mode::connectiontime',
        'connected-users'  => 'database::db2::mode::connectedusers',
        'database-logs'    => 'database::db2::mode::databaselogs',
        'database-usage'   => 'database::db2::mode::databaseusage',
        'hadr'             => 'database::db2::mode::hadr',
        'list-tablespaces' => 'database::db2::mode::listtablespaces',
        'sql'              => 'centreon::common::protocols::sql::mode::sql',
        'sql-string'       => 'centreon::common::protocols::sql::mode::sqlstring',
        'tablespaces'      => 'database::db2::mode::tablespaces'
    };

    $self->{sql_modes}->{dbi} = 'database::db2::dbi';

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'server:s@'  => { name => 'server' },
            'port:s@'    => { name => 'port' },
            'database:s' => { name => 'database' }
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{server})) {
        $self->{sqldefault}->{dbi} = [];
        for (my $i = 0; $i < scalar(@{$options_result->{server}}); $i++) {
            next if ($options_result->{server}->[$i] eq '');

            $self->{sqldefault}->{dbi}->[$i] = { data_source => 'DB2:PROTOCOL=TCPIP;HOSTNAME=' . $options_result->{server}->[$i] };
            if (!defined($options_result->{database}) || $options_result->{database} eq '') {
                $self->{output}->add_option_msg(short_msg => 'Need to specify --database option');
                $self->{output}->option_exit();
            }
            if (!defined($options_result->{port}->[$i]) || $options_result->{port}->[$i] eq '') {
                $self->{output}->add_option_msg(short_msg => 'Need to specify --port option');
                $self->{output}->option_exit();
            }
            $self->{sqldefault}->{dbi}->[$i]->{data_source}  .= ';PORT=' . $options_result->{port}->[$i];
            $self->{sqldefault}->{dbi}->[$i]->{data_source}  .= ';DATABASE=' . $options_result->{database} . ';';
        }
    } elsif (defined($options_result->{database}) && $options_result->{database} ne '') {
        $self->{sqldefault}->{dbi} = [ { data_source => 'DB2;' . $options_result->{database} } ];
    }

    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check DB2 Server.

=over 8

=item B<--server>

Domain name or IP address of the Db2 database system (Uncataloged database connections)

=item B<--port>

TCP/IP server port number that is assigned to the Db2 database system

=item B<--database>

Name for the Db2 database system. If --server is not set, it's a cataloged connection (database alias).

=back

=cut
