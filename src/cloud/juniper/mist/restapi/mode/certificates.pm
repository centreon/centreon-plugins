#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::juniper::mist::restapi::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc;
use POSIX qw(floor);
use Time::Piece;
use File::Temp qw(tempfile);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # skipped_code -10 (no value) is suppressed: when the organization uses a
        # Mist-managed server certificate there is no custom cert to measure, and
        # we surface that with an explicit OK message instead of a noisy
        # "skipped (no value(s))".
        { name => 'server', type => COUNTER_TYPE_GLOBAL, skipped_code => { -10 => 1 } },
        { name => 'cas', type => COUNTER_TYPE_INSTANCE, prefix_output => "CA certificate '%{subject}' ",
          message_multiple => 'All CA certificates are OK' }
    ];

    $self->{maps_counters}->{server} = [
        {
            label => 'certificate-expiry',
            nlabel => 'mist.nac.server.certificate.expiry.days',
            # Centreon range '60:' fires when the value is below 60, so an already
            # expired certificate (negative days) also matches - which is the
            # whole point: the silent RADIUS certificate expiry this plugin was
            # written after must raise an alert.
            warning_default => '60:',
            critical_default => '30:',
            set => {
                key_values => [ { name => 'expiration' }, { name => 'subject' }, { name => 'issuer' }, { name => 'date' } ],
                output_template => "RADIUS server certificate '%{subject}' expires in %{expiration} days (%{date})",
                perfdatas => [
                    { template => '%d', unit => 'd' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cas} = [
        {
            label => 'ca-expiry',
            nlabel => 'mist.nac.ca.certificate.expiry.days',
            warning_default => '180:',
            critical_default => '90:',
            set => {
                key_values => [ { name => 'expiration' }, { name => 'subject' }, { name => 'issuer' }, { name => 'date' } ],
                output_template => "expires in %{expiration} days (%{date})",
                perfdatas => [
                    { template => '%d', unit => 'd', label_extra_instance => 1, instance_use => 'subject' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'check-cas'               => { name => 'check_cas' },
        'filter-certificate-cn:s' => { name => 'filter_certificate_cn' }
    });

    return $self;
}

# Watches the NAC (Access Assurance) RADIUS server certificate and, optionally,
# the imported CA certificates. The certificates live in the organization
# settings under the 'mist_nac' section:
#   { "mist_nac": { "server_cert": { "cert": "<PEM>" }, "cacerts": [ "<PEM>", ... ] } }
sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my $settings = $options{custom}->request_api(endpoint => "/api/v1/orgs/$org_id/setting");

    $self->{output}->option_exit(short_msg => "No 'mist_nac' section in organization settings (Access Assurance not configured?)")
        if (ref($settings->{mist_nac}) ne 'HASH');
    my $nac = $settings->{mist_nac};

    # --- RADIUS server certificate ------------------------------------------
    my $server_pem = (ref($nac->{server_cert}) eq 'HASH') ? $nac->{server_cert}->{cert} : undef;

    if (defined($server_pem) && $server_pem =~ /BEGIN CERTIFICATE/) {
        my $info = $self->_parse_certificate($server_pem);
        if (!defined($info)) {
            $self->{output}->output_add(severity => 'CRITICAL', short_msg => 'RADIUS server certificate is unreadable or invalid');
        } else {
            $self->{server} = {
                expiration => $info->{days_left},
                subject => $info->{subject_cn},
                issuer => $info->{issuer_cn},
                date => $info->{not_after_str}
            };
        }
    } else {
        # No custom certificate means Mist manages and auto-renews it: this is a
        # healthy state, not a gap in monitoring.
        $self->{output}->output_add(severity => 'OK', short_msg => 'no custom RADIUS server certificate (Mist-managed, auto-renewed)');
    }

    # --- imported CA certificates -------------------------------------------
    $self->{cas} = {};
    if (defined($self->{option_results}->{check_cas}) && ref($nac->{cacerts}) eq 'ARRAY') {
        my $index = 0;
        foreach my $pem (@{$nac->{cacerts}}) {
            $index++;
            my $info = $self->_parse_certificate($pem);
            if (!defined($info)) {
                $self->{output}->output_add(severity => 'WARNING', short_msg => "CA certificate #$index is unreadable or invalid");
                next;
            }

            my $cn = $info->{subject_cn};
            next if (defined($self->{option_results}->{filter_certificate_cn})
                && $self->{option_results}->{filter_certificate_cn} ne ''
                && $cn !~ /$self->{option_results}->{filter_certificate_cn}/i);

            # Key on the index (unique) rather than the CN, so two CAs sharing a
            # Common Name are both kept and displayed.
            $self->{cas}->{$index} = {
                expiration => $info->{days_left},
                subject => $cn,
                issuer => $info->{issuer_cn},
                date => $info->{not_after_str}
            };
        }
    }
}

# X.509 decoding uses Crypt::OpenSSL::X509 when available, and falls back to the
# openssl binary: minimal pollers often lack the XS module.
sub _parse_certificate {
    my ($self, $pem) = @_;

    return undef if (!defined($pem) || $pem !~ /BEGIN CERTIFICATE/);

    my ($subject, $issuer, $enddate);

    my $decoded = eval {
        require Crypt::OpenSSL::X509;
        my $x509 = Crypt::OpenSSL::X509->new_from_string($pem);
        $subject = $x509->subject();
        $issuer = $x509->issuer();
        $enddate = $x509->notAfter();
        1;
    };

    if (!$decoded) {
        my ($fh, $tmp) = tempfile('mistcertXXXXXX', TMPDIR => 1, UNLINK => 1);
        print $fh $pem;
        close($fh);

        my ($error, $output) = centreon::plugins::misc::backtick(
            command => 'openssl',
            arguments => [ 'x509', '-in', $tmp, '-noout', '-subject', '-issuer', '-enddate' ],
            timeout => 10
        );
        return undef if ($error != 0 || !defined($output));

        ($subject) = $output =~ /^subject=\s*(.+)$/m;
        ($issuer) = $output =~ /^issuer=\s*(.+)$/m;
        ($enddate) = $output =~ /^notAfter=\s*(.+)$/m;
    }

    return undef if (!defined($enddate));

    (my $normalized = $enddate) =~ s/\s+GMT\s*$//;
    $normalized =~ s/\s+/ /g;

    my $time_piece = eval { Time::Piece->strptime($normalized, '%b %d %H:%M:%S %Y') };
    return undef if ($@ || !defined($time_piece));

    return {
        subject_cn => _extract_cn($subject) // 'unknown',
        issuer_cn => _extract_cn($issuer) // '',
        not_after_str => $time_piece->strftime('%Y-%m-%d'),
        days_left => floor(($time_piece->epoch - time()) / 86400)
    };
}

sub _extract_cn {
    my ($dn) = @_;

    return undef if (!defined($dn));
    if ($dn =~ /CN\s*=\s*([^,\/]+)/) {
        my $cn = $1;
        $cn =~ s/^\s+|\s+$//g;
        return $cn;
    }
    return undef;
}

1;

__END__

=head1 MODE

Check the Juniper Mist Access Assurance (NAC) RADIUS server certificate and,
optionally, the imported CA certificates.

A silent expiry of the RADIUS server certificate breaks every 802.1X
authentication at once, which is exactly the failure this mode guards against.
When no custom server certificate is configured, Mist manages and auto-renews
it, and the mode reports OK.

=over 8

=item B<--check-cas>

Also check the imported CA certificates (C<mist_nac.cacerts>). Disabled by
default.

=item B<--filter-certificate-cn>

Only check CA certificates whose Common Name matches this regular expression.

=item B<--warning-certificate-expiry>

Warning threshold, in days, for the RADIUS server certificate expiry
(default: '60:', i.e. warn when fewer than 60 days remain).

=item B<--critical-certificate-expiry>

Critical threshold, in days, for the RADIUS server certificate expiry
(default: '30:', i.e. alert when fewer than 30 days remain, including an
already expired certificate).

=item B<--warning-ca-expiry>

Warning threshold, in days, for the imported CA certificates expiry
(default: '180:').

=item B<--critical-ca-expiry>

Critical threshold, in days, for the imported CA certificates expiry
(default: '90:').

=back

=cut
