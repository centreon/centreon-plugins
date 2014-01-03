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

package hardware::server::sun::sfxxk::mode::boards;

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
                                  "sudo-pasv"              => { name => 'sudo_pasv' },
                                  "command-pasv:s"         => { name => 'command_pasv', default => 'showfailover' },
                                  "command-path-pasv:s"    => { name => 'command_path_pasv', default => '/opt/SUNWSMS/bin' },
                                  "command-options-pasv:s" => { name => 'command_options_pasv', default => '-r 2>&1' },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'showboards' },
                                  "command-path:s"    => { name => 'command_path', default => '/opt/SUNWSMS/bin' },
                                  "command-options:s" => { name => 'command_options', default => '2>&1' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $stdout;
    
    $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                               options => $self->{option_results},
                                               sudo => $self->{option_results}->{sudo_pasv},
                                               command => $self->{option_results}->{command_pasv},
                                               command_path => $self->{option_results}->{command_path_pasv},
                                               command_options => $self->{option_results}->{command_options_pasv});
    if ($stdout !~ /MAIN/i) {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "System Controller is in spare mode.");
        $self->{output}->display();
        $self->{output}->exit();
    }

    $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                               options => $self->{option_results},
                                               sudo => $self->{option_results}->{sudo},
                                               command => $self->{option_results}->{command},
                                               command_path => $self->{option_results}->{command_path},
                                               command_options => $self->{option_results}->{command_options});
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");
    if ($stdout =~ /^Location(.*)/ims) {
        #Location    Pwr    Type of Board   Board Status  Test Status   Domain
        #--------    ---    -------------   ------------  -----------   ------
        #SB0         Off    V3CPU           Assigned      Unknown       B
        #SB1         Off    V3CPU           Assigned      Unknown       A
        #SB2         Off    V3CPU           Available     Unknown       Isolated
        #IO11        Off    HPCI            Assigned      Failed        engB
        my @content = split(/\n/, $1);
        shift @content;
        foreach my $line (@content) {
            
            next if ($line =~ /^---/);
            next if ($line !~ /^\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)\s{2}\s*(.*?)(\s{2}|$)/);
            my ($location, $pwr, $type_board, $board_status, $test_status, $domain) = ($1, $2, $3, $4, $5, $6);

            if ($test_status =~ /Failed|Degraded/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Error on board '$location' ($type_board) with test status '$test_status'");
            }
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun 'sfxxk' boards.

=over 8

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

=item B<--sudo-pasv>

Use 'sudo' to execute the command pasv.

=item B<--command-pasv>

Command to know if system controller is 'active' (Default: 'showfailover').

=item B<--command-path-pasv>

Command pasv path (Default: '/opt/SUNWSMS/bin').

=item B<--command-options-pasv>

Command pasv options (Default: '-r 2>&1').

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'showboards').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/opt/SUNWSMS/bin').

=item B<--command-options>

Command options (Default: '2>&1').

=back

=cut
