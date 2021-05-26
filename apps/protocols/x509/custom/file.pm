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

package apps::protocols::x509::custom::file;

use strict;
use warnings;
use centreon::plugins::http;
use Socket;
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
            'certificate:s' => { name => 'certificate' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM FILE OPTIONS', once => 1);

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

    $self->{option_results}->{certificate} = (defined($self->{option_results}->{certificate})) ? $self->{option_results}->{certificate} : '';

    if ($self->{option_results}->{certificate} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify certificate option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub read_pem {
    my ($self, %options) = @_;

    my $bio_cert = Net::SSLeay::BIO_new_file($self->{option_results}->{certificate}, 'rb');
    if (!$bio_cert) {
        return (undef, 'Cannot read file');
    }
    my $x509 = Net::SSLeay::PEM_read_bio_X509($bio_cert);
    if (!$x509) {
        return (undef, 'Cannot read certificate');
    }
    Net::SSLeay::BIO_free($bio_cert);
    return $x509;
}

sub read_der {
    my ($self, %options) = @_;

    my $bio_cert = Net::SSLeay::BIO_new_file($self->{option_results}->{certificate}, 'rb');
    if (!$bio_cert) {
        return (undef, 'Cannot read file');
    }
    my $x509 = Net::SSLeay::d2i_X509_bio($bio_cert);
    if (!$x509) {
        return (undef, 'Cannot read certificate');
    }
    Net::SSLeay::BIO_free($bio_cert);
    return $x509;
}

sub read_certificate {
    my ($self, %options) = @_;

    my ($x509, $message) = $self->read_pem();
    if (!defined($x509)) {
        ($x509, $message) = $self->read_der();
    }
    if (!defined($x509)) {
        $self->{output}->output_add(long_msg => Net::SSLeay::print_errs(), debug => 1);
        $self->{output}->add_option_msg(short_msg => $message);
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

    if (! -r $self->{option_results}->{certificate}) {
        $self->{output}->add_option_msg(short_msg => "Cannot read file '$self->{option_results}->{certificate}': $!");
        $self->{output}->option_exit();
    }

    my $cert_infos = $self->read_certificate();
    return $cert_infos;
}

1;

__END__

=head1 NAME

certificate file

=head1 CUSTOM FILE OPTIONS

certificate file

=over 8

=item B<--certificate>

Certificate file (PEM or DER).

=back

=head1 DESCRIPTION

B<custom>.

=cut
