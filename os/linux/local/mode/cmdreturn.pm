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

package os::linux::local::mode::cmdreturn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options' },
                                  "manage-returns:s"  => { name => 'manage_returns', default => '' },
                                });
    $self->{manage_returns} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{command})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify command option.");
       $self->{output}->option_exit();
    }
    
    foreach my $entry (split(/#/, $self->{option_results}->{manage_returns})) {
        next if (!($entry =~ /(.*?),(.*?),(.*)/));
        next if (!$self->{output}->is_litteral_status(status => $2));
        if ($1 ne '') {
            $self->{manage_returns}->{$1} = {return => $2, msg => $3};
        } else {
            $self->{manage_returns}->{default} = {return => $2, msg => $3};
        }
    }
    if ($self->{option_results}->{manage_returns} eq '' || scalar(keys %{$self->{manage_returns}}) == 0) {
       $self->{output}->add_option_msg(short_msg => "Need to specify manage-returns option correctly.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(output => $self->{output},
                                                                options => $self->{option_results},
                                                                sudo => $self->{option_results}->{sudo},
                                                                command => $self->{option_results}->{command},
                                                                command_path => $self->{option_results}->{command_path},
                                                                command_options => $self->{option_results}->{command_options},
                                                                no_quit => 1);
    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);
    
    if (defined($self->{manage_returns}->{$exit_code})) {
        $self->{output}->output_add(severity => $self->{manage_returns}->{$exit_code}->{return}, 
                                    short_msg => $self->{manage_returns}->{$exit_code}->{msg});
    } elsif (defined($self->{manage_returns}->{default})) {
        $self->{output}->output_add(severity => $self->{manage_returns}->{default}->{return}, 
                                    short_msg => $self->{manage_returns}->{default}->{msg});
    } else {
        $self->{output}->output_add(severity => 'UNKNWON', 
                                    short_msg => 'Exit code from command');
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check command returns.

=over 8

=item B<--manage-returns>

Set action according command exit code.
Example: 0,OK,File xxx exist#1,CRITICAL,File xxx not exist#,UNKNOWN,Command problem

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to test (Default: none).
You can use 'sh' to use '&&' or '||'.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=back

=cut
