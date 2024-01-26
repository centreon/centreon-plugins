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

package apps::thales::mistral::vs9::restapi::mode::mmccertificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_certificate_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'active: %s [revoked: %s]',
        $self->{result_values}->{active},
        $self->{result_values}->{revoked}
    );
}

sub custom_certificate_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} },
        unit => $self->{instance_mode}->{option_results}->{time_certificate_unit},
        instances => [
            $self->{result_values}->{sn},
            $self->{result_values}->{subjectCommonName},
            $self->{result_values}->{issuerCommonName}
        ],
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_certificate_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{time_certificate_unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return sprintf(
        "certificate '%s' [subject: %s, issuer: %s, usages: %s] ",
        $options{instance_value}->{sn},
        $options{instance_value}->{subjectCommonName},
        $options{instance_value}->{issuerCommonName},
        $options{instance_value}->{usages}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output', message_multiple => 'all certificates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{certificates} = [
        {
            label => 'certificate-status',
            type => 2,
            set => {
                key_values => [
                    { name => 'active' }, { name => 'revoked' },
                    { name => 'sn' }, { name => 'subjectCommonName' }, { name => 'issuerCommonName' }
                ],
                closure_custom_output => $self->can('custom_certificate_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'certificate-expires', nlabel => 'certificate.expires', set => {
                key_values      => [
                    { name => 'expires_seconds' }, { name => 'expires_human' },
                    { name => 'sn' }, { name => 'subjectCommonName' }, { name => 'issuerCommonName' }
                ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_certificate_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_certificate_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'time-certificate-unit:s' => { name => 'time_certificate_unit', default => 's' },
        'filter-cert-inactive'    => { name => 'filter_cert_inactive' },
        'filter-cert-revoked'     => { name => 'filter_cert_revoked' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{time_certificate_unit} eq '' || !defined($unitdiv->{$self->{option_results}->{time_certificate_unit}})) {
        $self->{option_results}->{time_certificate_unit} = 's';
    }
}

sub add_certificate {
    my ($self, %options) = @_;

    return if ($options{cert}->{validityPeriodEnd} !~ /^\s*(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+([+-].*)$/);

    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        time_zone  => $7
    );

    my $revoked;
    if (defined($options{cert}->{revoked})) {
        $revoked = $options{cert}->{revoked} =~ /true|1/i ? 'yes' : 'no';
        return if (defined($self->{option_results}->{filter_cert_revoked}) && $revoked eq 'yes');
    }

    my $active;
    if (defined($options{cert}->{active})) {
        $active = $options{cert}->{active} =~ /true|1/i ? 'yes' : 'no';
        return if (defined($self->{option_results}->{filter_cert_inactive}) && $active eq 'no');
    }

    $self->{certificates}->{ $options{cert}->{serialNumber} } = {
        sn => $options{cert}->{serialNumber},
        subjectCommonName => $options{cert}->{subjectCommonName},
        issuerCommonName => defined($options{cert}->{issuerCommonName}) ? $options{cert}->{issuerCommonName} : '',
        usages => join(' ', @{$options{cert}->{usages}}),
        active => $active,
        revoked => $revoked,
        expires_seconds => $dt->epoch() - time()
    };
    $self->{certificates}->{ $options{cert}->{serialNumber} }->{expires_seconds} = 0
        if ($self->{certificates}->{ $options{cert}->{serialNumber} }->{expires_seconds} < 0);
    $self->{certificates}->{ $options{cert}->{serialNumber} }->{expires_human} = centreon::plugins::misc::change_seconds(
        value =>  $self->{certificates}->{ $options{cert}->{serialNumber} }->{expires_seconds}
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $certificates = $options{custom}->request_api(
        endpoint => '/certificateCas',
        get_param => ['projection=withSignedCertificates']
    );

    $self->{certificates} = {};
    foreach my $cert (@{$certificates->{content}}) {
        $self->add_certificate(cert => $cert);
        foreach my $mmc (@{$cert->{certificatesMmc}}) {
            $self->add_certificate(cert => $mmc);
        }
    }
}

1;

__END__

=head1 MODE

Check certificates.

=over 8

=item B<--time-certificate-unit>

Select the time unit for certificate threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--filter-cert-inactive>

Skip inactive certificates.

=item B<--filter-cert-revoked>

Skip revoked certificates.

=item B<--unknown-certificate-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{active}, %{revoked}, %{sn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--warning-certificate-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{active}, %{revoked}, %{sn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--critical-certificate-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{active}, %{revoked}, %{sn}, %{subjectCommonName}, %{issuerCommonName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'certificate-expires'.

=back

=cut
