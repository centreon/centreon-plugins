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

package apps::protocols::x509::custom::opensslcli;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;
use Net::SSLeay 1.42;
use DateTime;
use Socket;

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
            'ssh-hostname:s' => { name => 'ssh_hostname' },
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OPENSSL CLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{sslhost} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}     = (defined($self->{option_results}->{port})) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : '';
    $self->{ssh_hostname} = defined($self->{option_results}->{ssh_hostname}) && $self->{option_results}->{ssh_hostname} ne '' ? $self->{option_results}->{ssh_hostname} : '';

    if ($self->{sslhost} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{port} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set --port option");
        $self->{output}->option_exit();
    }

    if ($self->{ssh_hostname} ne '') {
        $self->{option_results}->{hostname} = $self->{ssh_hostname};
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    return 0;
}

sub pem_type {
    my ($self, %options) = @_;

    my $bio_cert = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
    if (!$bio_cert) {
        $self->{output}->add_option_msg(short_msg => "Cannot init Net::SSLeay: $!");
        $self->{output}->option_exit();
    }
    if (Net::SSLeay::BIO_write($bio_cert, $options{cert}) < 0) {
        Net::SSLeay::BIO_free($bio_cert);
        $self->{output}->add_option_msg(short_msg => "Cannot write certificate: $!");
        $self->{output}->option_exit();
    }
    my $x509 = Net::SSLeay::PEM_read_bio_X509($bio_cert);
    Net::SSLeay::BIO_free($bio_cert);
    if (!$x509) {
        $self->{output}->add_option_msg(short_msg => "Cannot read certificate: $!");
        $self->{output}->option_exit();
    }

    my $cert_infos = {};
    $cert_infos->{issuer} = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($x509));
    $cert_infos->{expiration_date} = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($x509));
    my $subject = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($x509));
    if ($subject =~ /CN=(.*?)(?:\/(?:C|ST|L|O)=|\Z)/) {
        $cert_infos->{subject} = $1;
    }

    my @subject_alt_names = Net::SSLeay::X509_get_subjectAltNames($x509);
    my $append = '';
    $cert_infos->{alt_subjects} = '';
    for (my $i =  0; $i < $#subject_alt_names; $i += 2) {
        my ($type, $name) = ($subject_alt_names[$i], $subject_alt_names[$i + 1]);
        if ($type == &Net::SSLeay::GEN_IPADD) {
            $name = Socket::inet_ntop(length($name) > 4 ? Socket::AF_INET6 : Socket::AF_INET, $name);
        }
        $cert_infos->{alt_subjects} .= $append . $name;
        $append = ', ';
    }

    $cert_infos->{expiration_date} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z$/; # 2033-05-16T20:39:37Z
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
    $cert_infos->{expiration} = $dt->epoch();

    return $cert_infos;
}

sub get_certificate_informations {
    my ($self, %options) = @_;

    my $timeout = 30;

    my ($stdout, $exit_code);
    if ($self->{ssh_hostname} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{ssh_hostname},
            command => 'openssl',
            command_options => "s_client -connect '" . $self->{sslhost} . ':' . $self->{port} . "'",
            timeout => $timeout,
            no_quit => 1
        );
    } else {
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            sudo => $self->{option_results}->{sudo},
            options => { timeout => $timeout },
            command => 'openssl',
            command_options => "s_client -connect '" . $self->{sslhost} . ':' . $self->{port} . "'",
            no_quit => 1
        );
    }

    $self->{output}->output_add(long_msg => "command response: $stdout", debug => 1);

    if ($stdout !~ /^(-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)/ms) {
        $self->{output}->add_option_msg(short_msg => "cannot find the server certificate");
        $self->{output}->option_exit();
    }

    my $cert = $1;
    my $cert_infos = $self->pem_type(cert => $cert);

    return $cert_infos;
}

1;

__END__

=head1 NAME

openssl connections

=head1 OPENSSL CLI OPTIONS

openssl connection

=over 8

=item B<--hostname>

IP Addr/FQDN of the host.

=item B<--port>

Port used by host.

=back

=head1 DESCRIPTION

B<custom>.

=cut
