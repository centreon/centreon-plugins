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

package apps::protocols::ldap::mode::login;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::common::protocols::ldap::lib::ldap;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'               => { name => 'hostname' },
        'ldap-connect-options:s@'  => { name => 'ldap_connect_options' },
        'ldap-starttls-options:s@' => { name => 'ldap_starttls_options' },
        'ldap-bind-options:s@'     => { name => 'ldap_bind_options' },
        'tls'                      => { name => 'use_tls' },
        'username:s'   => { name => 'username' },
        'password:s'   => { name => 'password' },
        'warning:s'    => { name => 'warning' },
        'critical:s'   => { name => 'critical' },
        'timeout:s'    => { name => 'timeout', default => '30' },
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
        $self->{output}->add_option_msg(short_msg => 'Please set the hostname option');
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' &&
        !defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set --password option.");
        $self->{output}->option_exit();
    }
}

sub run {
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
    if ($code == 1) {
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => $err_msg);
        $self->{output}->display();
        $self->{output}->exit();
    }
    centreon::common::protocols::ldap::lib::ldap::quit(ldap_handle => $ldap_handle);

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf('Response time %.3f second(s)', $timeelapsed));
    $self->{output}->perfdata_add(label => 'time', unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Connection (also login) to an LDAP Server.
LDAP Control are not still managed.

=over 8

=item B<--hostname>

IP Addr/FQDN of the ldap host

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

=item B<--username>

Specify username for authentification (can be a DN)

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
