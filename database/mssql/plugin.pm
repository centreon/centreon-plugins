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

package database::mssql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'blocked-processes'    => 'database::mssql::mode::blockedprocesses',
                         'cache-hitratio'       => 'database::mssql::mode::cachehitratio',
                         'connected-users'      => 'database::mssql::mode::connectedusers',
                         'connection-time'      => 'centreon::common::protocols::sql::mode::connectiontime',
                         'databases-size'       => 'database::mssql::mode::databasessize',
                         'locks-waits'          => 'database::mssql::mode::lockswaits',
                         'transactions'         => 'database::mssql::mode::transactions',
                         'failed-jobs'          => 'database::mssql::mode::failedjobs',
                         'dead-locks'           => 'database::mssql::mode::deadlocks',
                         'backup-age'           => 'database::mssql::mode::backupage',
                         'sql'                  => 'centreon::common::protocols::sql::mode::sql',
                         );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
                                   arguments => {
                                                'hostname:s@'       => { name => 'hostname' },
                                                'port:s@'           => { name => 'port' },
                                                'database:s'        => { name => 'database' },
                                                }
                                  );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

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

=back

=cut
