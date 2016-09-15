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

package apps::protocols::ldap::mode::search;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use apps::protocols::ldap::lib::ldap;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"               => { name => 'hostname' },
         "search-base:s"            => { name => 'search_base' },
         "search-filter:s"          => { name => 'search_filter' },
         "ldap-connect-options:s@"  => { name => 'ldap_connect_options' },
         "ldap-starttls-options:s@" => { name => 'ldap_starttls_options' },
         "ldap-bind-options:s@"     => { name => 'ldap_bind_options' },
         "ldap-search-options:s@"   => { name => 'ldap_search_options' },
         "tls"                      => { name => 'use_tls' },
         "username:s"   => { name => 'username' },
         "password:s"   => { name => 'password' },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '30' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{search_base})) {
        $self->{output}->add_option_msg(short_msg => "Please set the search-base option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{search_filter})) {
        $self->{output}->add_option_msg(short_msg => "Please set the search-filter option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    apps::protocols::ldap::lib::ldap::connect($self);
    my $search_result = apps::protocols::ldap::lib::ldap::search($self);  
    apps::protocols::ldap::lib::ldap::quit();

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $num_entries = scalar($search_result->entries);
    my $exit = $self->{perfdata}->threshold_check(value => $num_entries,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Number of results returned: %s", $num_entries));
                                
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  min => 0);
    $self->{output}->perfdata_add(label => "entries",
                                  value => $num_entries,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
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

=item B<--username>

Specify username for authentification (can be a DN)

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning (number of results)

=item B<--critical>

Threshold critical (number of results)

=back

=cut
