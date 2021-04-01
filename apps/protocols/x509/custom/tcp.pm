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

package apps::protocols::x509::custom::tcp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Socket;
use IO::Socket::INET;
use IO::Socket::SSL;
use Net::SSLeay 1.42;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
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
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'servername:s'      => { name => 'servername' },
            'ssl-opt:s@'        => { name => 'ssl_opt' },
            'ssl-ignore-errors' => { name => 'ssl_ignore_errors' },
            'timeout:s'         => { name => 'timeout', default => 3 },
            'starttls:s'        => { name => 'starttls' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM TCP OPTIONS', once => 1);

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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}     = (defined($self->{option_results}->{port})) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : '';
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 3;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{port} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set --port option");
        $self->{output}->option_exit();
    }

    my $append = '';
    foreach (@{$self->{option_results}->{ssl_opt}}) {
        if ($_ ne '') {
            $self->{ssl_context} .= $append . $_;
            $append = ', ';
        }
    }

    return 0;
}

sub connect_ssl {
    my ($self, %options) = @_;

    my $socket;
    eval { 
        $socket = IO::Socket::SSL->new(
            PeerHost => $self->{option_results}->{hostname},
            PeerPort => $self->{option_results}->{port},
            $self->{option_results}->{servername} ? ( SSL_hostname => $self->{option_results}->{servername} ) : (),
            $self->{option_results}->{timeout} ? ( Timeout => $self->{option_results}->{timeout} ) : ()
        );
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => sprintf("%s", $@));
        $self->{output}->option_exit();
    }
    if (!defined($socket)) {
        $self->{output}->add_option_msg(short_msg => "Error creating SSL socket: $!, SSL error: $SSL_ERROR");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{ssl_ignore_errors}) && defined($SSL_ERROR)) {
        $self->{output}->add_option_msg(short_msg => "SSL error: $SSL_ERROR");
        $self->{output}->option_exit();
    }

    return $socket;
}

sub smtp_plain_com {
    my ($self, %options) = @_;

    my $buffer;
    $options{socket}->recv($buffer, 1024);

    $options{socket}->send("HELO\r\n");
    $options{socket}->recv($buffer, 1024);

    $options{socket}->send("STARTTLS\r\n");
    $options{socket}->recv($buffer, 1024);
    if ($buffer !~ /^220\s/) {
        $self->{output}->add_option_msg(short_msg => "Cannot starttls: $buffer");
        $self->{output}->option_exit();
    }
}

sub ftp_plain_com {
    my ($self, %options) = @_;

    my $buffer;
    $options{socket}->recv($buffer, 1024);

    $options{socket}->send("AUTH TLS\r\n");
    $options{socket}->recv($buffer, 1024);
    if ($buffer !~ /^234\s/) {
        $self->{output}->add_option_msg(short_msg => "Cannot starttls: $buffer");
        $self->{output}->option_exit();
    }
}

sub connect_starttls {
    my ($self, %options) = @_;

    my $socket = IO::Socket::INET->new(
        PeerHost => $self->{option_results}->{hostname},
        PeerPort => $self->{option_results}->{port},
        $self->{option_results}->{timeout} ? ( Timeout => $self->{option_results}->{timeout} ) : ()
    );
    if (!defined($socket)) {
        $self->{output}->add_option_msg(short_msg => "Error creating socket: $!");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{starttls} eq 'smtp') {
        $self->smtp_plain_com(socket => $socket);
    } elsif ($self->{option_results}->{starttls} eq 'ftp') {
        $self->ftp_plain_com(socket => $socket);
    }
    
    my $rv = IO::Socket::SSL->start_SSL(
        $socket,
        $self->{option_results}->{servername} ? ( SSL_hostname => $self->{option_results}->{servername} ) : ()
    );
    if (!defined($self->{option_results}->{ssl_ignore_errors}) && !$rv) {
        $self->{output}->add_option_msg(short_msg => "SSL error: $SSL_ERROR");
        $self->{output}->option_exit();
    }

    return $socket;
}

sub get_certificate_informations {
    my ($self, %options) = @_;

    if (defined($self->{ssl_context}) && $self->{ssl_context} ne '') {
        my $context = new IO::Socket::SSL::SSL_Context(eval $self->{ssl_context});
        eval { IO::Socket::SSL::set_default_context($context) };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => sprintf("Error setting SSL context: %s", $@));
            $self->{output}->option_exit();
        }
    }

    my $socket;
    if (defined($self->{option_results}->{starttls})) {
        $socket = $self->connect_starttls();
    } else {
        $socket = $self->connect_ssl();
    }

    my $cert_infos = {};

    $cert_infos->{subject} = $socket->peer_certificate('commonName');
    $cert_infos->{issuer} = $socket->peer_certificate('authority');

    my @subject_alt_names = $socket->peer_certificate('subjectAltNames');
    my $append = '';
    $cert_infos->{alt_subjects} = '';
    for (my $i =  0; $i < $#subject_alt_names; $i += 2) {
        my ($type, $name) = ($subject_alt_names[$i], $subject_alt_names[$i + 1]);
        if ($type == GEN_IPADD) {
            $name = inet_ntoa($name);
        }
        $cert_infos->{alt_subjects} .= $append . $name;
        $append = ', ';
    }

    $cert_infos->{expiration_date} = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($socket->peer_certificate()));
    $cert_infos->{expiration_date} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z$/; # 2033-05-16T20:39:37Z
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
    $cert_infos->{expiration} = $dt->epoch();

    return $cert_infos;
}

1;

__END__

=head1 NAME

tcp ssl connections

=head1 CUSTOM TCP OPTIONS

tcp ssl connection

=over 8

=item B<--hostname>

IP Addr/FQDN of the host.

=item B<--port>

Port used by host.

=item B<--servername>

Servername of the host for SNI support (only with IO::Socket::SSL >= 1.56) (eg: foo.bar.com).

=item B<--ssl-opt>

Set SSL options.

Examples:

Do not verify certificate: --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE"

Verify certificate: --ssl-opt="SSL_verify_mode => SSL_VERIFY_PEER" --ssl-opt="SSL_version => TLSv1"

=item B<--ssl-ignore-errors>

Ignore SSL handshake errors. For example: 'SSL error: SSL wants a read first'.

=item B<--timeout>

Set timeout in seconds for SSL connection (Default: '3') (only with IO::Socket::SSL >= 1.984).

=item B<--starttls>

Init plaintext connection and start_SSL after. Can be: 'smtp', 'ftp'.

=back

=head1 DESCRIPTION

B<custom>.

=cut
