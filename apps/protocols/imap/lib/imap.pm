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

package apps::protocols::imap::lib::imap;

use strict;
use warnings;
use centreon::plugins::misc;
use Net::IMAP::Simple;

my $imap_handle;

sub quit {
    $imap_handle->quit;
}

sub search {
    my ($self, %options) = @_;
    
    if (!defined($imap_handle->select($self->{option_results}->{folder}))) {
        my $output = $imap_handle->errstr;
        $output =~ s/\r//g;
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Folder Select Error: ' . $output);
        quit();
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my @ids = $imap_handle->search($self->{option_results}->{search});
    
    if (defined($self->{option_results}->{delete})) {
        foreach my $msg_num (@ids) {
            $imap_handle->delete($msg_num);
        }
        $imap_handle->expunge_mailbox();
    }
    
    return scalar(@ids);
}

sub connect {
    my ($self, %options) = @_;
    my %imap_options = ();
    
    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $imap_options{port} = $self->{option_results}->{port} if (defined($self->{option_results}->{port}));
    $imap_options{use_ssl} = 1 if (defined($self->{option_results}->{use_ssl}));
    $imap_options{timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    
    $imap_handle = Net::IMAP::Simple->new($self->{option_results}->{hostname},
        %imap_options
    );
    
    
    if (!defined($imap_handle)) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to IMAP: ' . $Net::IMAP::Simple::errstr);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        if (!$imap_handle->login($self->{option_results}->{username}, $self->{option_results}->{password})) {
            # Exchange put '\r'...
            my $output = $imap_handle->errstr;
            $output =~ s/\r//g;
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Login failed: ' . $output);
            quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
}

1;
