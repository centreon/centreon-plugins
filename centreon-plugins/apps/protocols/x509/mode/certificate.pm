#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::protocols::x509::mode::certificate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Socket;
use IO::Socket::SSL;
use Net::SSLeay 1.42;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "Certificate for '%s' expires in '%d' days [%s] - Issuer: '%s'",
        $self->{result_values}->{subject}, $self->{result_values}->{expiration}, $self->{result_values}->{date},
        $self->{result_values}->{issuer}
    );
    if (defined($self->{result_values}->{alt_subjects}) && $self->{result_values}->{alt_subjects} ne '') {
        $self->{output}->output_add(long_msg => sprintf("Alternative subject names: %s.", $self->{result_values}->{alt_subjects}));
    }
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{subject} = $options{new_datas}->{$self->{instance} . '_subject'};
    $self->{result_values}->{issuer} = $options{new_datas}->{$self->{instance} . '_issuer'};
    $self->{result_values}->{expiration} = ($options{new_datas}->{$self->{instance} . '_expiration'} - time()) / 86400;
    $self->{result_values}->{date} = $options{new_datas}->{$self->{instance} . '_date'};
    $self->{result_values}->{alt_subjects} = $options{new_datas}->{$self->{instance} . '_alt_subjects'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'subject' }, { name => 'issuer' }, { name => 'expiration' },
                    { name => 'date' }, { name => 'alt_subjects' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'port:s'            => { name => 'port' },
        'servername:s'      => { name => 'servername' },
        'ssl-opt:s@'        => { name => 'ssl_opt' },
        'ssl-ignore-errors' => { name => 'ssl_ignore_errors' },
        'timeout:s'         => { name => 'timeout', default => '3' },
        'warning-status:s'  => { name => 'warning_status', default => '%{expiration} < 60' },
        'critical-status:s' => { name => 'critical_status', default => '%{expiration} < 30' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set --hostname option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{port}) || $self->{option_results}->{port} eq '') {
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

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
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
    eval { 
        $socket = IO::Socket::SSL->new(
            PeerHost => $self->{option_results}->{hostname},
            PeerPort => $self->{option_results}->{port},
            $self->{option_results}->{servername} ? ( SSL_hostname => $self->{option_results}->{servername} ) : (),
            $self->{option_results}->{timeout} ? ( Timeout => $self->{option_results}->{timeout} ) : (),
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

    my $subject = $socket->peer_certificate('commonName');
    my $issuer = $socket->peer_certificate('authority');

    my @subject_alt_names = $socket->peer_certificate('subjectAltNames');
    my $append = '';
    my $alt_subjects = '';
    for (my $i =  0; $i < $#subject_alt_names; $i += 2) {
        my ($type, $name) = ($subject_alt_names[$i], $subject_alt_names[$i + 1]);
        if ($type == GEN_IPADD) {
            $name = inet_ntoa($name);
        }
        $alt_subjects .= $append . $name;
        $append = ', ';
    }

    my $notafterdate = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($socket->peer_certificate()));
    $notafterdate =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z$/; # 2033-05-16T20:39:37Z
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);

    $self->{global} = {
        subject => $subject,
        issuer => $issuer,
        expiration => $dt->epoch,
        date => $notafterdate,
        alt_subjects => $alt_subjects
    };
}

1;

__END__

=head1 MODE

Check X509's certificate validity (for SMTPS, POPS, IMAPS, HTTPS)

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

=item B<--warning-status>

Set warning threshold for status. (Default: '%{expiration} < 60').
Can use special variables like: %{expiration}, %{subject}, %{issuer}, %{alt_subjects}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{expiration} < 30').
Can use special variables like: %{expiration}, %{subject}, %{issuer}, %{alt_subjects}.

Examples :

Raise a critical alarm if certificate expires in less than 30
days or does not cover alternative name 'my.app.com'
--critical-status='%{expiration} < 30 || %{alt_subjects} !~ /my.app.com/'

=back

=cut
