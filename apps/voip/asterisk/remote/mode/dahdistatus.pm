################################################################################
# Copyright 2005-2014 MERETHIS
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

package apps::voip::asterisk::remote::mode::dahdistatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use apps::voip::asterisk::remote::lib::ami;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

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
                                  "filter-name:s"     => { name => 'filter_name', },
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
}

sub manage_selection {
    my ($self, %options) = @_;
    my @result;
    
    $self->{asterisk_command} = 'dahdi show status';
    
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
    foreach my $line (@result) {
    	if ($line =~ /^Description /)
    	{
    		next;
    	}
        if ($line =~ /^(.{41})(\w*).*/)
        {
	        my $status;
	        my ($trunkname, $trunkstatus) = ($1, $2);
	        $trunkname =~ s/^\s+|\s+$//g;
	        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
	            $trunkname !~ /$self->{option_results}->{filter_name}/)
	        {
	            $self->{output}->output_add(long_msg => "Skipping trunk '" . $trunkname . "': no matching filter name");
	            next;
	        }
	        if ($trunkstatus eq 'Red' | $trunkstatus eq 'Yel' | $trunkstatus eq 'Blu')
	        {
	        	$status = 'CRITICAL';
	        }
	        elsif ($trunkstatus eq 'Unconfi')
	        {
	        	$status = 'WARNING';
	        }
	        $self->{result}->{$trunkname} = {name => $trunkname, status => $status, realstatus => $trunkstatus};
        }
        elsif ($line =~ /^Unable to connect .*/)
        {
        	$self->{result}->{$line} = {name => $line, status => 'CRITICAL'};
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $msg;
    my $old_status = 'ok';

    $self->manage_selection();
    
    # Send formated data to Centreon
    if (scalar keys %{$self->{result}} >= 1)
    {
    	$self->{output}->output_add(severity => 'OK',
                                short_msg => 'Everything is OK');
    }
    else
    {
    	$self->{output}->output_add(severity => 'Unknown',
                                short_msg => 'Nothing to be monitored');
    }

    foreach my $name (sort(keys %{$self->{result}})) {
        if (!$self->{output}->is_status(value => $self->{result}->{$name}->{status}, compare => 'ok', litteral => 1))
        {
            $msg = sprintf("Trunk: %s", $self->{result}->{$name}->{name});
            $self->{output}->output_add(severity => $self->{result}->{$name}->{status},
                                        short_msg => $msg);
        }
        $self->{output}->output_add(long_msg => sprintf("%s : %s", $self->{result}->{$name}->{name}, $self->{result}->{$name}->{realstatus}));
    }
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Show peers for different protocols.

=over 8

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

=item B<--filter-name>

Filter on trunkname (regexp can be used).

=back

=cut