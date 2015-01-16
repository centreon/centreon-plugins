###############################################################################
# Copyright 2005-2015 MERETHIS
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
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that
# MERETHIS also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Author : Mathieu Cinquin <mcinquin@merethis.com>
#
####################################################################################

package apps::voip::asterisk::remote::lib::ami;

use strict;
use warnings;
use Net::Telnet;
use Data::Dumper;

my $ami_handle;
my $line;
my @lines;
my @result;

sub quit {
    $ami_handle->print("Action: logoff");
    $ami_handle->print("");
    $ami_handle->close();
}

sub connect {
    my ($self, %options) = @_;

    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';

    $ami_handle = new Net::Telnet (Telnetmode => 0,
                                   Timeout => $self->{option_results}->{timeout},
				   Errmode => 'return',		
    );

    $ami_handle->open(Host => $self->{option_results}->{hostname},
                      Port => $self->{option_results}->{port},
    );

    if ($ami_handle->errmsg) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to AMI: ' . $ami_handle->errmsg);
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Check connection message.
    $line = $ami_handle->getline;
    if ($line !~ /^Asterisk/) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to AMI: ' . $line);
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Authentication.
    $ami_handle->print("Action: login");
    $ami_handle->print("Username: $self->{option_results}->{username}");
    $ami_handle->print("Secret: $self->{option_results}->{password}");
    $ami_handle->print("Events: off");
    $ami_handle->print("");

    # Check authentication message (second message).
    $line = $ami_handle->getline;
    $line = $ami_handle->getline;
    if ($line !~ /^Message: Authentication accepted/) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to AMI: ' . $line);
        $self->{output}->display();
        $self->{output}->exit();
    }

}

sub action {
   my ($self) = @_;

   $ami_handle->print("Action: command");
   $ami_handle->print("Command: $self->{asterisk_command}");
   $ami_handle->print("");
   
   
   my @return;
   while (my $line = $ami_handle->getline(Timeout => 1)) {
 	push(@return,$line);
	next if ($line !~ /END COMMAND/o);
   }   
   return @return;
}

1;
