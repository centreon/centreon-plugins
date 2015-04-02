################################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an executable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting executable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

package apps::voip::asterisk::remote::mode::externalcalls;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use apps::voip::asterisk::remote::lib::ami;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';

    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "port:s"            => { name => 'port', default => 5038 },
                                  "username:s"        => { name => 'username' },
                                  "password:s"        => { name => 'password' },
                                  "remote:s"          => { name => 'remote', default => 'ssh' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "command:s"         => { name => 'command', default => 'asterisk_sendcommand.pm' },
                                  "command-path:s"    => { name => 'command_path', default => '/home/centreon/bin' },
                                  "protocol:s"        => { name => 'protocol', },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the --hostname option");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{remote} eq 'ami')
    {
    	if (!defined($self->{option_results}->{username})) {
	        $self->{output}->add_option_msg(short_msg => "Please set the --username option");
	        $self->{output}->option_exit();
	    }

	    if (!defined($self->{option_results}->{password})) {
	        $self->{output}->add_option_msg(short_msg => "Please set the --password option");
	        $self->{output}->option_exit();
	    }
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    my @result;

    $self->{asterisk_command} = 'core show channels';

    if ($self->{option_results}->{remote} eq 'ami')
    {
    	apps::voip::asterisk::remote::lib::ami::connect($self);
        @result = apps::voip::asterisk::remote::lib::ami::action($self);
        apps::voip::asterisk::remote::lib::ami::quit();
    }
    else
    {
    	my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => "'".$self->{asterisk_command}."'",
                                                  );
        @result = split /\n/, $stdout;
    }

    # Compute data
    $self->{option_results}->{extcallcounter} = '0';
    foreach my $line (@result) {
        if ($line =~ /Outgoing Line/m)
        {
            $self->{option_results}->{extcallcounter}++;
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $msg;
    my $old_status = 'ok';

    $self->manage_selection();

    # Send formated data to Centreon
    my $exit_code = $self->{perfdata}->threshold_check(value => $self->{option_results}->{extcallcounter},
                              threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->perfdata_add(label => 'External Calls',
                                  value => $self->{option_results}->{extcallcounter},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Current external calls: %s", $self->{option_results}->{extcallcounter})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Show number of current external calls

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--remote>

Execute command remotely; can be 'ami' or 'ssh' (default: ssh).

=item B<--hostname>

Hostname to query (need --remote option).

=item B<--port>

AMI remote port (default: 5038).

=item B<--username>

AMI username.

=item B<--password>

AMI password.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'asterisk_sendcommand.pm').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: /home/centreon/bin).

=back

=cut
