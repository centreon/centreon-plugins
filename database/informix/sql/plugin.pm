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

package database::informix::sql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);
use File::Temp qw(tempfile);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'archivelevel0'    => 'database::informix::sql::mode::archivelevel0',
        'checkpoints'      => 'database::informix::sql::mode::checkpoints',
        'chunkstates'      => 'database::informix::sql::mode::chunkstates',
        'connection-time'  => 'centreon::common::protocols::sql::mode::connectiontime',
        'global-cache'     => 'database::informix::sql::mode::globalcache',
        'list-dbspaces'    => 'database::informix::sql::mode::listdbspaces',
        'list-databases'   => 'database::informix::sql::mode::listdatabases',
        'lockoverflow'     => 'database::informix::sql::mode::lockoverflow',
        'longtxs'          => 'database::informix::sql::mode::longtxs',
        'dbspace-usage'    => 'database::informix::sql::mode::dbspacesusage',
        'logfile-usage'    => 'database::informix::sql::mode::logfilesusage',
        'sessions'         => 'database::informix::sql::mode::sessions',
        'table-locks'      => 'database::informix::sql::mode::tablelocks',
        'sql'              => 'centreon::common::protocols::sql::mode::sql',
    );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
        arguments => {
            'host:s@'      => { name => 'db_host' },
            'port:s@'      => { name => 'db_port' },
            'instance:s@'  => { name => 'db_instance' },
        }
    );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();
    
    if (defined($options_result->{db_host})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{db_host}}); $i++) {
            if (!defined($options_result->{db_instance}[$i])) {
                $self->{output}->add_option_msg(short_msg => "Need to specify instance argument.");
                $self->{output}->option_exit();
            }
            if (!defined($options_result->{db_port}[$i])) {
                $self->{output}->add_option_msg(short_msg => "Need to specify port argument.");
                $self->{output}->option_exit();
            }

            my ($handle, $path) = tempfile("sqlhosts_" . $options_result->{db_instance}[$i] . "\_XXXXX", UNLINK => 1, TMPDIR => 1);
            print $handle $options_result->{db_instance}[$i] . " onsoctcp " . $options_result->{db_host}[$i] . " " . $options_result->{db_port}[$i] . "\n";
            close($handle);
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Informix:sysmaster@' . $options_result->{db_instance}[$i], 
                                               env => { INFORMIXSQLHOSTS => File::Spec->rel2abs($path),
                                                        INFORMIXSERVER   => $options_result->{db_instance}[$i] } };
        }
    }

    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Informix Server.

=over 8

You need to specify the following options.

=item B<--host>

Hostname to query.

=item B<--port>

Database Server Port.

=item B<--instance>

Database Instance Name.

=back

=cut
