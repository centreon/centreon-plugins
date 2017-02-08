#
# Copyright 2017 Centreon (http://www.centreon.com/)
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
