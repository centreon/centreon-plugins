################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package database::informix::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);
use File::Temp qw(tempfile);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'archivelevel0'    => 'database::informix::mode::archivelevel0',
                         'checkpoints'      => 'database::informix::mode::checkpoints',
                         'chunkstates'      => 'database::informix::mode::chunkstates',
                         'connection-time'  => 'centreon::common::protocols::sql::mode::connectiontime',
                         'global-cache'     => 'database::informix::mode::globalcache',
                         'list-dbspaces'    => 'database::informix::mode::listdbspaces',
                         'list-databases'   => 'database::informix::mode::listdatabases',
                         'lockoverflow'     => 'database::informix::mode::lockoverflow',
                         'longtxs'          => 'database::informix::mode::longtxs',
                         'dbspace-usage'    => 'database::informix::mode::dbspacesusage',
                         'logfile-usage'    => 'database::informix::mode::logfilesusage',
                         'sessions'         => 'database::informix::mode::sessions',
                         'table-locks'      => 'database::informix::mode::tablelocks',
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
