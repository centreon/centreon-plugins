#
# Copyright 2015 Centreon (http://www.centreon.com/)
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
