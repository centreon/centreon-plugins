###############################################################################
# Copyright 2005-2015 CENTREON
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation ; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.
#
# Linking this program statically or dynamically with other modules is making a
# combined work based on this program. Thus, the terms and conditions of the GNU
# General Public License cover the whole combination.
#
# As a special exception, the copyright holders of this program give MERETHIS
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that
# MERETHIS also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Author : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

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

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"        => { name => 'hostname' },
         "port:s"            => { name => 'port' },
         "validity-mode:s"   => { name => 'validity_mode' },
         "warning-date:s"    => { name => 'warning' },
         "critical-date:s"   => { name => 'critical' },
         "subjectname:s"     => { name => 'subjectname' },
         "issuername:s"      => { name => 'issuername' },
         "timeout:s"         => { name => 'timeout', default => '3' },
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
    if (!defined($self->{option_results}->{validity_mode})) {
        $self->{output}->add_option_msg(short_msg => "Please set the validity-mode option");
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
        };

        #Create SSL connection
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);

        eval { $ssl = Net::SSLeay::new($ctx) };
       if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        };

        eval { Net::SSLeay::set_fd($ssl, fileno($connection)) };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        };

        eval { Net::SSLeay::connect($ssl) };
        if ($@) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%s", $!));

            $self->{output}->display();
            $self->{output}->exit()
        };

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
            if ( $self->{option_results}->{subjectname} =~ /$subject_name/mi ) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => sprintf("Subject Name %s is present in Certificate :%s", $self->{option_results}->{subjectname}, $subject_name));
            } else {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Subject Name %s is not present in Certificate : %s", $self->{option_results}->{subjectname}, $subject_name));
            }

            $self->{output}->display();
            $self->{output}->exit()

        #Issuer Name
        } elsif ($self->{option_results}->{validity_mode} eq 'issuer') {
            my $issuer_name = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($cert));
            if ( $self->{option_results}->{issuer} =~ /$issuer_name/mi ) {
                $self->{output}->output_add(severity => 'OK',
                                            short_msg => sprintf("Issuer Name %s is present in Certificate :%s", $self->{option_results}->{issuername}, $issuer_name));
            } else {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Issuer Name %s is not present in Certificate : %s", $self->{option_results}->{issuername}, $issuer_name));
            }

            $self->{output}->display();
            $self->{output}->exit()
        } else {
            $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find validity-mode '" . $self->{option_results}->{validity_mode} . "'.");
            $self->{output}->option_exit();
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

Threshold warning in days (Days before expiration)

=item B<--critical-date>

Threshold critical in days (Days before expiration)

=item B<--subject>

Subject Name pattern

=item B<--issuer>

Issuer Name pattern

=back

=cut
