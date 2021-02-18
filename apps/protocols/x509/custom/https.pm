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

package apps::protocols::x509::custom::https;

use strict;
use warnings;
use centreon::plugins::http;
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'  => { name => 'hostname' },
            'port:s'      => { name => 'port', },
            'method:s'    => { name => 'method' },
            'urlpath:s'   => { name => 'url_path' },
            'timeout:s'   => { name => 'timeout' },
            'header:s@'   => { name => 'header' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM HTTPS OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{option_results}->{proto} = 'https';
    $self->{option_results}->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 5;
 
    if ($self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});

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
        $self->{output}->add_option_msg(short_msg => "Cannot write certificate: $!");
        $self->{output}->option_exit();
    }
    my $x509 = Net::SSLeay::PEM_read_bio_X509($bio_cert);
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
            $name = inet_ntoa($name);
        }
        $cert_infos->{alt_subjects} .= $append . $name;
        $append = ', ';
    }

    $cert_infos->{expiration_date} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z$/; # 2033-05-16T20:39:37Z
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
    $cert_infos->{expiration} = $dt->epoch();

    return $cert_infos;
}

sub socket_type {
    my ($self, %options) = @_;

    my $cert_infos = {};
    $cert_infos->{subject} = $options{socket}->peer_certificate('commonName');
    $cert_infos->{issuer} = $options{socket}->peer_certificate('authority');

    my @subject_alt_names = $options{socket}->peer_certificate('subjectAltNames');
    my $append = '';
    $cert_infos->{alt_subjects} = '';
    for (my $i =  0; $i < $#subject_alt_names; $i += 2) {
        my ($type, $name) = ($subject_alt_names[$i], $subject_alt_names[$i + 1]);
        if ($type == &Net::SSLeay::GEN_IPADD) {
            $name = inet_ntoa($name);
        }
        $cert_infos->{alt_subjects} .= $append . $name;
        $append = ', ';
    }

    $cert_infos->{expiration_date} = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($options{socket}->peer_certificate()));
    $cert_infos->{expiration_date} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z$/; # 2033-05-16T20:39:37Z
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
    $cert_infos->{expiration} = $dt->epoch();

    return $cert_infos;
}

sub get_certificate_informations {
    my ($self, %options) = @_;

    $self->{http}->request(
        certinfo => 1,
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my ($type, $cert) = $self->{http}->get_certificate();
    if (!defined($cert)) {
        $self->{output}->add_option_msg(short_msg => $self->{http}->get_message());
        $self->{output}->option_exit();
    }

    my $cert_infos;
    if ($type eq 'pem') {
        $cert_infos = $self->pem_type(cert => $cert);
    } elsif ($type eq 'socket') {
        $cert_infos = $self->socket_type(socket => $cert);
    }

    return $cert_infos;
}

1;

__END__

=head1 NAME

http connection

=head1 CUSTOM HTTPS OPTIONS

http connection

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Webserver (Default: 443)

=item B<--method>

Specify http method used (Default: 'GET')

=item B<--urlpath>

Set path to get webpage (Default: '/')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--header>

Set HTTP headers (Multiple option)

=back

=head1 DESCRIPTION

B<custom>.

=cut
