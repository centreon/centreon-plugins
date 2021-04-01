#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::common::protocols::ldap::lib::ldap;

use strict;
use warnings;
use Net::LDAP;

sub quit {
    my (%options) = @_;

    if (defined($options{ldap_handle})) {
        $options{ldap_handle}->unbind();
    }
}

sub search {
    my (%options) = @_;
    my %ldap_search_options = ();
    
    $ldap_search_options{base} = $options{search_base};
    $ldap_search_options{filter} = $options{search_filter};
    my $attrs;
    foreach my $option (@{$options{ldap_search_options}}) {
        next if ($option !~ /^\s*(.+?)\s*=(.+)$/);
        if ($1 eq 'attrs') {
            $attrs = [] if (!defined($attrs));
            push @$attrs, $2;
        } else {
            $ldap_search_options{$1} = $2;
        }
    }
    $ldap_search_options{attrs} = $attrs if (defined($attrs));
    my $search_result = $options{ldap_handle}->search(%ldap_search_options);
    if ($search_result->code) {
        return ($search_result, 1, 'Search operation error: ' . $search_result->error);
    }
    
    return ($search_result, 0);
}

sub connect {
    my (%options) = @_;
    my %ldap_connect_options = ();
    my %ldap_bind_options = ();

    $ldap_connect_options{timeout} = $options{timeout} if (defined($options{timeout}));
    foreach my $option (@{$options{ldap_connect_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $ldap_connect_options{$1} = $2;
    }
    
    my $ldap_handle = Net::LDAP->new($options{hostname}, %ldap_connect_options);

    if (!defined($ldap_handle)) {
        return (undef, 1, 'Unable to connect to LDAP: ' . $@);
    }
    
    # TLS Process
    if (defined($options{use_tls})) {
        my %ldap_starttls_options = ();
        
        foreach my $option (@{$options{ldap_starttls_options}}) {
            next if ($option !~ /^(.+?)=(.+)$/);
            $ldap_starttls_options{$1} = $2;
        }
        
        my $tls_result = $ldap_handle->start_tls(%ldap_starttls_options);
        if ($tls_result->code) {
            return ($ldap_handle, 1, 'Start TLS operation error: ' . $tls_result->error);
        }
    }
    
    # Bind process
    my $username;
    if (defined($options{username}) && $options{username} ne '') {
        $ldap_bind_options{password} = $options{password};
        $username = $options{username};
    }
    
    foreach my $option (@{$options{ldap_bind_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $ldap_bind_options{$1} = $2;
    }
    
    my $bind_result = $ldap_handle->bind($username, %ldap_bind_options);
    if ($bind_result->code) {
        return ($ldap_handle, 1, 'Bind operation error: ' . $bind_result->error);
    }
    
    return ($ldap_handle, 0);
}

1;
