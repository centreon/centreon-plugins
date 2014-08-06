###############################################################################
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
# Author : Simon BOMM <sbomm@merethis.com>
#
####################################################################################

package apps::protocols::smtp::lib::smtp;

use strict;
use warnings;
use centreon::plugins::misc;
use Email::Send::SMTP::Gmail;

my $smtp_handle;
my $connected = 0;

sub quit {
    if ($connected == 1) {
        $smtp_handle->bye;
    }
}

sub message {
    my ($self, %options) = @_;
    my %smtp_options = ();
    
    foreach my $option (@{$self->{option_results}->{smtp_send_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $smtp_options{-$1} = $2;
    }
    
    my $result;
    eval {
            local $SIG{ALRM} = sub { die 'timeout' };
            alarm($self->{option_results}->{timeout});
            $result = $smtp_handle->send(-to => $self->{option_results}->{smtp_to},
                                         -from => $self->{option_results}->{smtp_from},
                                         %smtp_options);
    
            alarm(0);
    };
    if ($@) {
        $self->{output}->output_add(severity => 'unknown',
                                    short_msg => 'Unable to send message: ' . $@);
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($result == -1) {
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => 'Unable to send message.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(severity => 'ok',
                                short_msg => 'Message sent');
}

sub connect {
    my ($self, %options) = @_;
    my %smtp_options = ();
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    
    $smtp_options{-auth} = 'none';
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        $smtp_options{-login} = $self->{option_results}->{username};
        delete $smtp_options{-auth};
    }
    if (defined($self->{option_results}->{username}) && defined($self->{option_results}->{password})) {
        $smtp_options{-pass} = $self->{option_results}->{password};
    }
    
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $smtp_options{-port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    foreach my $option (@{$self->{option_results}->{smtp_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $smtp_options{-$1} = $2;
    }
    
    my ($stdout);
    {
        eval {
            local $SIG{ALRM} = sub { die 'timeout' };
            local *STDOUT;
            open STDOUT, '>', \$stdout;
            alarm($self->{option_results}->{timeout});
            $smtp_handle = Email::Send::SMTP::Gmail->new(-smtp=> $self->{option_results}->{hostname},
                                                        %smtp_options);
            alarm(0);
        };
    }

    if ($@) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to SMTP: ' . $@);
        $self->{output}->display();
        $self->{output}->exit();
    }
    if (defined($stdout) && $smtp_handle == -1) {
        chomp $stdout;
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to SMTP: ' . $stdout);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $connected = 1;
}

1;
