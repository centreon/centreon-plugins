#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::voip::asterisk::remote::lib::ami;

use strict;
use warnings;
use Net::Telnet;

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
