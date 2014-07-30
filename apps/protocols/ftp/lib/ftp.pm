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

package apps::protocols::ftp::lib::ftp;

use strict;
use warnings;
use centreon::plugins::misc;
use Net::FTP;

my $ftp_handle;

sub quit {
    $ftp_handle->quit;
}

sub connect {
    my ($self, %options) = @_;
    my %ftp_options = ();
    
    my $ftp_class = 'Net::FTP'; 
    if (defined($self->{option_results}->{use_ssl})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Net::FTPSSL',
                                               error_msg => "Cannot load module 'Net::FTPSSL'.");
        $ftp_class = 'Net::FTPSSL'; 
    }
    
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $ftp_options{Port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    $ftp_options{Timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    foreach my $option (@{$self->{option_results}->{ftp_options}}) {
        my ($key, $value) = split /=/, $option;
        if (defined($key) && defined($value)) {
            $ftp_options{$key} = $value;
        }
    }
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    
    $ftp_handle = $ftp_class->new($self->{option_results}->{hostname},
        %ftp_options
    );
    
    
    if (!defined($ftp_handle)) {
        if (defined($self->{option_results}->{use_ssl})) {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Unable to connect to FTP: ' . $Net::FTPSSL::ERRSTR);
        } else {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Unable to connect to FTP: ' . $@);
        }
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        if (!$ftp_handle->login($self->{option_results}->{username}, $self->{option_results}->{password})) {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Login failed: ' . $ftp_handle->message);
            quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
}

1;
