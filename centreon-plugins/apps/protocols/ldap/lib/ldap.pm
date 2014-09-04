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

package apps::protocols::ldap::lib::ldap;

use strict;
use warnings;
use Net::LDAP;

my $ldap_handle;
my $connected = 0;

sub quit {
    if ($connected == 1) {
        $ldap_handle->unbind;
    }
}

sub search {
    my ($self, %options) = @_;
    my %ldap_search_options = ();
    
    $ldap_search_options{base} = $self->{option_results}->{search_base};
    $ldap_search_options{filter} = $self->{option_results}->{search_filter};
    my $attrs;
    foreach my $option (@{$self->{option_results}->{ldap_search_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        if ($1 =~ /attrs/) {
            $attrs = [] if (!defined($attrs));
            push @$attrs, $2; 
        } else {
            $ldap_search_options{$1} = $2;
        }
    }
    $ldap_search_options{attrs} = $attrs if (defined($attrs));
    my $search_result = $ldap_handle->search(%ldap_search_options);
    if ($search_result->code) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Search operation error: ' . $search_result->error);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return $search_result;
}

sub connect {
    my ($self, %options) = @_;
    my %ldap_connect_options = ();
    my %ldap_bind_options = ();
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }

    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';
    $ldap_connect_options{timeout} = $self->{option_results}->{timeout} if (defined($self->{option_results}->{timeout}));
    foreach my $option (@{$self->{option_results}->{ldap_connect_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $ldap_connect_options{$1} = $2;
    }
    
    $ldap_handle = Net::LDAP->new($self->{option_results}->{hostname}, %ldap_connect_options);

    if (!defined($ldap_handle)) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Unable to connect to LDAP: ' . $@);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    # TLS Process
    if (defined($self->{option_results}->{use_tls})) {
        my %ldap_starttls_options = ();
        
        foreach my $option (@{$self->{option_results}->{ldap_starttls_options}}) {
            next if ($option !~ /^(.+?)=(.+)$/);
            $ldap_starttls_options{$1} = $2;
        }
        
        my $tls_result = $ldap_handle->start_tls(%ldap_starttls_options);
        if ($tls_result->code) {
            $self->{output}->output_add(severity => $connection_exit,
                                        short_msg => 'Start TLS operation error: ' . $tls_result->error);
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    
    # Bind process
    my $username;
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        $ldap_bind_options{password} = $self->{option_results}->{password};
        $username = $self->{option_results}->{username};
    }
    
    foreach my $option (@{$self->{option_results}->{ldap_bind_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $ldap_bind_options{$1} = $2;
    }
    
    my $bind_result = $ldap_handle->bind($username, %ldap_bind_options);
    if ($bind_result->code) {
        $self->{output}->output_add(severity => $connection_exit,
                                    short_msg => 'Bind operation error: ' . $bind_result->error);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $connected = 1;
}

1;
