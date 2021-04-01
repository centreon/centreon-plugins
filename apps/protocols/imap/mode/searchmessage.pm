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

package apps::protocols::imap::mode::searchmessage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::protocols::imap::lib::imap;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s' => { name => 'hostname' },
        'port:s'     => { name => 'port', },
        'ssl'        => { name => 'use_ssl' },
        'ssl-opt:s@' => { name => 'ssl_opt' },
        'username:s' => { name => 'username' },
        'password:s' => { name => 'password' },
        'warning:s'  => { name => 'warning' },
        'critical:s' => { name => 'critical' },
        'timeout:s'  => { name => 'timeout', default => '30' },
        'search:s'   => { name => 'search' },
        'delete'     => { name => 'delete' },
        'folder:s'   => { name => 'folder', default => 'INBOX' }
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
        $self->{output}->add_option_msg(short_msg => 'Please set the --hostname option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{search})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the --search option');
        $self->{output}->option_exit();
    }

    my $append = '';
    $self->{ssl_options} = '';
    foreach (@{$self->{option_results}->{ssl_opt}}) {
        if ($_ ne '') {
            $self->{ssl_options} .= $append . $_;
            $append = ', ';
        }
    }
}

sub run {
    my ($self, %options) = @_;

    apps::protocols::imap::lib::imap::connect($self);    
    my ($num) = apps::protocols::imap::lib::imap::search($self);
    apps::protocols::imap::lib::imap::quit();

    my $exit = $self->{perfdata}->threshold_check(
        value => $num,
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf('%d message(s) found', $num)
    );
    $self->{output}->perfdata_add(
        label => 'numbers',
        value => $num,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check messages in a mailbox with IMAP filter.

=over 8

=item B<--hostname>

IP Addr/FQDN of the imap host

=item B<--port>

Port used

=item B<--ssl>

Use SSL connection.

=item B<--ssl-opt>

Set SSL options: --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE" --ssl-opt="SSL_version => 'TLSv1'"

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--search>

Set the search string (Required)

=item B<--delete>

Delete messages found

=item B<--folder>

Set IMAP folder (Default: 'INBOX')

=item B<--warning>

Threshold warning of number messages found

=item B<--critical>

Threshold critical of number message found

=back

=cut
