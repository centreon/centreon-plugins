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

package storage::hp::3par::7000::mode::wsapi;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"              => { name => 'hostname' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "no-wsapi:s"              => { name => 'no_wsapi' },
                                });
    $self->{no_wsapi} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
        $self->{output}->option_exit(); 
    }
    
    if (defined($self->{option_results}->{no_wsapi})) {
        if ($self->{option_results}->{no_wsapi} ne '') {
            $self->{no_wsapi} = $self->{option_results}->{no_wsapi};
        } else {
            $self->{no_wsapi} = 'critical';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{remote} = 1;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => "showwsapi",
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});


    my @results = split("\n",$stdout);
    my $total_wsapi = 0;
    foreach my $result (@results) {
        if ($result =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+\S+/) {
            $total_wsapi++;
            my $serviceStatus = $1;
            my $serviceState = $2;
            my $httpState = $3;
            my $httpPort = $4;
            my $httpsState = $5;
            my $httpsPort = $6;

            $self->{output}->output_add(long_msg => sprintf("WSAPI service is '%s' and '%s' [HTTP on port %d is %s] [HTTPS on port %d is %s]",
                                        $serviceStatus, $serviceState, $httpPort, $httpState, $httpsPort ,$httpsState));
            if ((lc($serviceStatus) ne 'enabled') || (lc($serviceState) ne 'active')){
                $self->{output}->output_add(severity => 'critical',
                                            short_msg => sprintf("WSAPI service is '%s' and '%s' [HTTP on port %d is %s] [HTTPS on port %d is %s]",
                                        $serviceStatus, $serviceState, $httpPort, $httpState, $httpsPort ,$httpsState));
            }
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'WSAPI service is ok.');
    
    if (defined($self->{option_results}->{no_wsapi}) && $total_wsapi == 0) {
        $self->{output}->output_add(severity => $self->{no_wsapi},
                                    short_msg => 'No WSAPI service is checked.');
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check WSAPI service status.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh').

=item B<--sudo>

Use sudo.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--no-wsapi>

Return an error if no WSAPI are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut