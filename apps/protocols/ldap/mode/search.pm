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

package apps::protocols::ldap::mode::search;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::common::protocols::ldap::lib::ldap;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'entries', nlabel => 'ldap.request.entries.count', set => {
                key_values => [ { name => 'entries' } ],
                output_template => 'Number of results returned: %s',
                perfdatas => [
                    { value => 'entries', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'time', display_ok => 0, nlabel => 'ldap.request.time.second', set => {
                key_values => [ { name => 'time' } ],
                output_template => 'Response time : %.3fs',
                perfdatas => [
                    { label => 'time', value => 'time', template => '%.3f', min => 0, unit => 's' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'hostname:s'               => { name => 'hostname' },
         'search-base:s'            => { name => 'search_base' },
         'search-filter:s'          => { name => 'search_filter' },
         'ldap-connect-options:s@'  => { name => 'ldap_connect_options' },
         'ldap-starttls-options:s@' => { name => 'ldap_starttls_options' },
         'ldap-bind-options:s@'     => { name => 'ldap_bind_options' },
         'ldap-search-options:s@'   => { name => 'ldap_search_options' },
         'tls'                      => { name => 'use_tls' },
         'username:s'       => { name => 'username' },
         'password:s'       => { name => 'password' },
         'timeout:s'        => { name => 'timeout', default => '30' },
         'display-entry:s'  => { name => 'display_entry' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the hostname option');
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{search_base})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the search-base option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{search_filter})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the search-filter option');
        $self->{output}->option_exit();
    }

    $self->{option_results}->{ldap_search_options} = [] if (!defined($self->{option_results}->{ldap_search_options}));

    if (defined($self->{option_results}->{display_entry}) && $self->{option_results}->{display_entry} ne '') {
        while ($self->{option_results}->{display_entry} =~ /%\{(.*?)\}/g) {
            push @{$self->{option_results}->{ldap_search_options}}, 'attrs=' . $1;
        }
    }
}

sub ldap_error {
    my ($self, %options) = @_;
    
    if ($options{code} == 1) {
        $self->{output}->output_add(
            severity => 'unknown',
            short_msg => $options{err_msg}
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub display_entries {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{display_entry}) || $self->{option_results}->{display_entry} eq '');

    foreach my $entry ($options{result}->entries()) {
        my $display = $self->{option_results}->{display_entry};
        while ($display =~ /%\{(.*?)\}/g) {
            my $attr = $1;
            my $value = $entry->get_value($attr);
            $value = '' if (!defined($value));
            $display =~ s/%\{$attr\}/$value/g;
        }

        $self->{output}->output_add(long_msg => $display);
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    my ($ldap_handle, $code, $err_msg) = centreon::common::protocols::ldap::lib::ldap::connect(
        hostname => $self->{option_results}->{hostname},
        username => $self->{option_results}->{username},
        password => $self->{option_results}->{password},
        timeout => $self->{option_results}->{timeout},
        ldap_connect_options => $self->{option_results}->{ldap_connect_options},
        use_tls => $self->{option_results}->{use_tls},
        ldap_starttls_options => $self->{option_results}->{ldap_starttls_options},
        ldap_bind_options => $self->{option_results}->{ldap_bind_options},
    );
    $self->ldap_error(code => $code, err_msg => $err_msg);
    (my $search_result, $code, $err_msg) = centreon::common::protocols::ldap::lib::ldap::search(
        ldap_handle => $ldap_handle,
        search_base => $self->{option_results}->{search_base},
        search_filter => $self->{option_results}->{search_filter},
        ldap_search_options => $self->{option_results}->{ldap_search_options},
    );
    $self->ldap_error(code => $code, err_msg => $err_msg);
    centreon::common::protocols::ldap::lib::ldap::quit(ldap_handle => $ldap_handle);

    $self->{global} = {
        time => tv_interval($timing0, [gettimeofday]),
        entries => scalar($search_result->entries)
    };

    $self->display_entries(result => $search_result);
}

1;

__END__

=head1 MODE

Check search results (by default it uses the scope 'sub').
LDAP Control are not still managed. 
Example: 
centreon_plugins.pl --plugin=apps::protocols::ldap::plugin --mode=search --hostname='xxx.xxx.xxx.xxx' 
--username='cn=Manager,dc=merethis,dc=com' --password='secret' --search-base='dc=merethis,dc=com' --search-filter='(objectclass=organizationalunit)'

=over 8

=item B<--hostname>

IP Addr/FQDN of the ldap host (required).

=item B<--search-base>

Set the DN that is the base object entry relative to which the 
search is to be performed (required).

=item B<--search-filter>

Set filter that defines the conditions an entry in the directory 
must meet in order for it to be returned by the search (required).

=item B<--ldap-connect-options>

Add custom ldap connect options:

=over 16

=item B<Set SSL connection>

--ldap-connect-options='scheme=ldaps'

=item B<Set LDAP version 2>

--ldap-connect-options='version=2'

=back

=item B<--ldap-starttls-options>

Add custom start tls options (need --tls option):

=over 16

=item B<An example>

--ldap-starttls-options='verify=none'

=back

=item B<--ldap-bind-options>

Add custom bind options (can force noauth) (not really useful now).

=item B<--ldap-search-options>

Add custom search options (can change the scope for example).

=item B<--display-entry>

Display ldap entries (with --verbose option) (Example: '%{cn} account locked')

=item B<--username>

Specify username for authentification (can be a DN)

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning-time>

Threshold warning in seconds

=item B<--critical-time>

Threshold critical in seconds

=item B<--warning-entries>

Threshold warning (number of results)

=item B<--critical-entries>

Threshold critical (number of results)

=back

=cut
