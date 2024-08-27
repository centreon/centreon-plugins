#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::protocols::imap::custom::imapclient;

use strict;
use warnings;
use Mail::IMAPClient;
use IO::Socket::SSL;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'ssl'        => { name => 'use_ssl' },
            'ssl-opt:s@' => { name => 'ssl_opt' },
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'insecure'   => { name => 'insecure' },
            'timeout:s'  => { name => 'timeout' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'IMAP OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '' ? $self->{option_results}->{hostname} : '';
    $self->{port} = defined($self->{option_results}->{port}) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : '';
    $self->{username} = defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '' ? $self->{option_results}->{username} : '';
    $self->{password} = defined($self->{option_results}->{password}) && $self->{option_results}->{password} ne '' ? $self->{option_results}->{password} : '';
    $self->{timeout} = defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 30;
    $self->{insecure} = defined($self->{option_results}->{insecure}) ? 1 : 0;
    $self->{use_ssl} = defined($self->{option_results}->{use_ssl}) ? 1 : 0;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{username} ne '' && $self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --password option.');
        $self->{output}->option_exit();
    }

    $self->{ssl_context} = centreon::plugins::misc::eval_ssl_options(
        output => $self->{output},
        ssl_opt => $self->{option_results}->{ssl_opt}
    );
    if ($self->{insecure} == 1) {
        $self->{ssl_context}->{SSL_verify_mode} = SSL_VERIFY_NONE;
    }

    return 0;
}

sub disconnect {
    my ($self, %options) = @_;

    $self->{imap}->disconnect();
}

sub connect {
    my ($self, %options) = @_;

    my $connection_exit = defined($options{connection_exit}) ? $options{connection_exit} : 'unknown';

    $self->{imap} = Mail::IMAPClient->new();
    $self->{imap}->Server($self->{hostname});
    $self->{imap}->Ssl(1) if ($self->{use_ssl} == 1);
    $self->{imap}->Port($self->{port}) if ($self->{port} ne '');
    $self->{imap}->Timeout($self->{timeout}) if ($self->{timeout} ne '');
    if ($self->{output}->is_debug()) {
        $self->{imap}->Debug(1);
    }

    my $sslargs = [];
    if ($self->{use_ssl} == 1) {
        foreach (keys %{$self->{ssl_context}}) {
            push @$sslargs, $_, $self->{ssl_context}->{$_};
        }
    }
    my $rv;
    if (scalar(@$sslargs) > 0) {
        $rv = $self->{imap}->connect(Ssl => $sslargs);
    } else {
        $rv = $self->{imap}->connect();
    }
    if (!defined($rv)) {
        $self->{output}->output_add(
            severity => $connection_exit,
            short_msg => 'Unable to connect to IMAP: ' . $@
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($self->{username} ne '') {
        $self->{imap}->User($self->{username});
        $self->{imap}->Password($self->{password});
        $rv = $self->{imap}->login();
        if (!defined($rv)) {
            $self->{output}->output_add(
                severity => $connection_exit,
                short_msg => "Login failed: $@"
            );
            $self->disconnect();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }

    #my $oauth_sign = encode_base64("user=". $username ."\x01auth=Bearer ". $oauth_token ."\x01\x01", '');
    #$imap->authenticate('XOAUTH2', sub { return $oauth_sign }) or die("Auth error: ". $imap->LastError);
    # detail: https://developers.google.com/google-apps/gmail/xoauth2_protocol
}

sub search {
    my ($self, %options) = @_;

    if (!defined($self->{imap}->select($options{folder}))) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Folder select failed: $@"
        );
        $self->disconnect();
        $self->{output}->display();
        $self->{output}->exit();
    }

    my @ids = $self->{imap}->search($options{search});

    if (defined($options{delete})) {
        foreach my $msg_num (@ids) {
            $self->{imap}->delete_message($msg_num);
        }
        $self->{imap}->expunge($options{folder});
    }

    return scalar(@ids);
}

1;

__END__

=head1 NAME

protocol imap.

=head1 SYNOPSIS

protocol imap.

=head1 IMAP OPTIONS

=over 8

=item B<--hostname>

IP Addr/FQDN of the imap host

=item B<--port>

Port used (default: 143).

=item B<--ssl>

Use SSL connection.

=item B<--ssl-opt>

Set SSL options: --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE" --ssl-opt="SSL_version => 'TLSv1'"

=item B<--insecure>

Allow insecure TLS connection by skipping cert validation (since redis-cli 6.2.0).

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (default: 30)

=back

=head1 DESCRIPTION

B<custom>.

=cut
