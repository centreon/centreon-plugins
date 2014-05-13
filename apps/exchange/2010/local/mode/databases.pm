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

package apps::exchange::2010::local::mode::databases;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::common::powershell::exchange::2010::databases;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
								  "no-ps"         	  => { name => 'no_ps', },
								  "no-mailflow"    	  => { name => 'no_mailflow', },
								  "no-mapi"       	  => { name => 'no_mapi', },
                                  "timeout:s"         => { name => 'timeout', default => 50 },
								  "command:s"         => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
	
	my $ps = centreon::common::powershell::exchange::2010::databases::get_powershell(no_mailflow => $self->{option_results}->{no_mailflow},
																					 no_ps => $self->{option_results}->{no_ps},
																					 no_mapi => $self->{option_results}->{no_mapi});
	$self->{option_results}->{command_options} .= " " . $ps . " 2>&1";
	my $stdout = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                          timeout => $self->{option_results}->{timeout},
                                                          command => $self->{option_results}->{command},
														  command_path => $self->{option_results}->{command_path},
														  command_options => $self->{option_results}->{command_options});
	centreon::common::powershell::exchange::2010::databases::check($self, stdout => $stdout);
	
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check: Exchange Databases are Mounted, Mapi/Mailflow Connectivity to all databases are working.

=over 8

=item B<--no-mailflow>

Don't check mailflow connectivity.

=item B<--no-mapi>

Don't check mapi connectivity.

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=back

=cut