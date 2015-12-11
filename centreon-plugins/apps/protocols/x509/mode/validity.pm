#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package apps::protocols::x509::mode::validity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket::SSL;
use Net::SSLeay;
use Date::Manip;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.3';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"        => { name => 'hostname' },
         "port:s"            => { name => 'port', default => 443 },
         "validity-mode:s"   => { name => 'validity_mode' },
         "warning-date:s"    => { name => 'warning' },
         "critical-date:s"   => { name => 'critical' },
         "subjectname:s"     => { name => 'subjectname', default => '' },
         "issuername:s"      => { name => 'issuername', default => '' },
         "timeout:s"         => { name => 'timeout', default => 5 },
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
    if (!defined($self->{option_results}->{port})) {
        $self->{output}->add_option_msg(short_msg => "Please set the port option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{validity_mode}) || $self->{option_results}->{validity_mode} !~ /^expiration|subject|issuer$/) {
        $self->{output}->add_option_msg(short_msg => "Please set the validity-mode option (issuer, subject or expiration)");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    #Global variables
    my ($connection, $ctx, $ssl, $cert);

    #Create Socket connection
    $connection = IO::Socket::INET->new(PeerAddr => $self->{option_results}->{hostname},
                                        PeerPort => $self->{option_results}->{port},
                                        Timeout => $self->{option_results}->{timeout},
                                       );
    if (!defined($connection)) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("%s", $!));
	    $self->{output}->display();
	    $self->{output}->exit();
    } else {
        #Create SSL context
        eval { $ctx = Net::SSLeay::CTX_new() };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf ("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        }

        #Create SSL connection
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);

        eval { $ssl = Net::SSLeay::new($ctx) };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        }

        eval { Net::SSLeay::set_fd($ssl, fileno($connection)) };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        }

        eval { Net::SSLeay::connect($ssl) };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        }

        #Retrieve Certificat
        $cert = Net::SSLeay::get_peer_certificate($ssl);

        #Expiration Date
        if ($self->{option_results}->{validity_mode} eq 'expiration') {
            (my $notafterdate = Net::SSLeay::P_ASN1_UTCTIME_put2string(Net::SSLeay::X509_get_notAfter($cert))) =~ s/ GMT//;
            my $daysbefore = int((&UnixDate(&ParseDate($notafterdate),"%s") - time) / 86400);
            my $exit = $self->{perfdata}->threshold_check(value => $daysbefore,
                                                          threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Certificate expiration days: %s - Validity Date: %s", $daysbefore, $notafterdate));

            $self->{output}->display();
            $self->{output}->exit()

        #Subject Name
        } elsif ($self->{option_results}->{validity_mode} eq 'subject') {
            my $subject_name = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($cert));
            if ($subject_name =~ /$self->{option_results}->{subjectname}/mi) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => sprintf("Subject Name '%s' is present in Certificate: %s", $self->{option_results}->{subjectname}, $subject_name));
            } else {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Subject Name '%s' is not present in Certificate: %s", $self->{option_results}->{subjectname}, $subject_name));
            }

            $self->{output}->display();
            $self->{output}->exit()

        #Issuer Name
        } elsif ($self->{option_results}->{validity_mode} eq 'issuer') {
            my $issuer_name = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($cert));
            if ($issuer_name =~ /$self->{option_results}->{issuername}/mi) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => sprintf("Issuer Name '%s' is present in Certificate: %s", $self->{option_results}->{issuername}, $issuer_name));
            } else {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Issuer Name '%s' is not present in Certificate: %s", $self->{option_results}->{issuername}, $issuer_name));
            }

            $self->{output}->display();
            $self->{output}->exit()
        }
    }
}

1;

__END__

=head1 MODE

Check X509's certificate validity

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--port>

Port used by Server (Default: '443')

=item B<--validity-mode>

Validity mode.
Can be : 'expiration' or 'subject' or 'issuer'

=item B<--warning-date>

Threshold warning in days (Days before expiration, eg: '60:' for 60 days before)

=item B<--critical-date>

Threshold critical in days (Days before expiration, eg: '30:' for 30 days before)

=item B<--subjectname>

Subject Name pattern

=item B<--issuername>

Issuer Name pattern

=back

=cut
