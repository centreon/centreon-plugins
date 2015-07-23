###############################################################################
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
# Authors : Stéphane Duret <sduret@merethis.com>
#
####################################################################################

package apps::kayako::sql::plugin;

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
        'list-department'	=> 'apps::kayako::sql::mode::listdepartment',
        'list-priority'		=> 'apps::kayako::sql::mode::listpriority',
        'list-staff'		=> 'apps::kayako::sql::mode::liststaff',
        'list-status'		=> 'apps::kayako::sql::mode::liststatus',
        'ticket-count'		=> 'apps::kayako::sql::mode::ticketcount',
    );
    $self->{sql_modes}{psqlcmd} = 'database::postgres::psqlcmd';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
                                   arguments => {
                                                'host:s@'       => { name => 'db_host' },
                                                'port:s@'   	=> { name => 'db_port' },
                                                'database:s@'   => { name => 'db_name' },
                                                }
                                  );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{db_host})) {
        @{$self->{sqldefault}->{dbi}} = ();
        @{$self->{sqldefault}->{mysqlcmd}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{db_host}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'mysql:host=' . $options_result->{db_host}[$i] };
            $self->{sqldefault}->{mysqlcmd}[$i] = { host => $options_result->{db_host}[$i] };
            if (defined($options_result->{db_port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{db_port}[$i];
                $self->{sqldefault}->{mysqlcmd}[$i]->{port} = $options_result->{db_port}[$i];
            }
	    if (!defined($options_result->{db_name}[$i]) || $options_result->{db_name}[$i] eq '') {
		$self->{output}->add_option_msg(short_msg => "Need to specify '--database' option.");
        	$self->{output}->option_exit();
    	    }else{
            	$self->{sqldefault}->{dbi}[$i]->{data_source} .= ';database=' . $options_result->{db_name}[$i];
            	$self->{sqldefault}->{psqlcmd}[$i]->{dbname} = $options_result->{db_name}[$i];
	    }
        }
    }

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kayako with MySQL Server.

=item B<--host>

Hostname to query.

=item B<--port>

Database Server Port.

=item B<--database>

Database Name.

=back

=cut
