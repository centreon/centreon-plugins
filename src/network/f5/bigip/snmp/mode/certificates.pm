#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{expires_unit},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{expires_unit},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_expires_output {
    my ($self, %options) = @_;

    my $msg = $self->{result_values}->{expires_seconds} > 0 ?
        'expires in ' . $self->{result_values}->{expires_human} :
        'has expired';

    $msg.= ' ['. $self->{result_values}->{expires_date} .']' if $self->{output}->is_verbose();

    return $msg;
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return sprintf(
        "Certificate '%s' ",
        $options{instance_value}->{name}
    );
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{unit} = 's'
        if $self->{option_results}->{unit} eq '' || not defined $unitdiv->{$self->{option_results}->{unit}};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output',
          message_multiple => 'All certificates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'certificates-count', nlabel => 'certificates.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'number of certificates: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{certificates} = [
        { label => 'certificate-expires', critical_default => '@0:0', nlabel => 'certificate.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_date' },
                                     { name => 'expires_human' },  { name => 'expires_unit' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_expires_output'),
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "include-name:s" => { name => 'include_name', default => '' },
        "exclude-name:s" => { name => 'exclude_name', default => '' },
        "include-issuer:s" => { name => 'include_issuer', default => '' },
        "exclude-issuer:s" => { name => 'exclude_issuer', default => '' },
        "include-validation:i" => { name => 'include_validation', default => '' },
        "exclude-validation:i" => { name => 'exclude_validation', default => '' },
        'unit:s' => { name => 'unit', default => 's' }
    });

    return $self;
}

my $mapping = {
    sysCertificateFileObjectName =>                        { oid => '.1.3.6.1.4.1.3375.2.1.15.1.2.1.1' },
    sysCertificateFileObjectIssuerCert =>                  { oid => '.1.3.6.1.4.1.3375.2.1.15.1.2.1.2' },
    sysCertificateFileObjectCertStatusValidationOptions => { oid => '.1.3.6.1.4.1.3375.2.1.15.1.2.1.3' },
    sysCertificateFileObjectExpirationString =>            { oid => '.1.3.6.1.4.1.3375.2.1.15.1.2.1.4' },
    sysCertificateFileObjectExpirationDate =>              { oid => '.1.3.6.1.4.1.3375.2.1.15.1.2.1.5' },
};
my $oid_sysCertificateFileObjectEntry = '.1.3.6.1.4.1.3375.2.1.15.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{certificates} = {};
    $self->{global} = { total => 0 };

    my $results = $options{snmp}->get_table(
        oid => $oid_sysCertificateFileObjectEntry,
        nothing_quit => 1
    );

    my $now = time;

    foreach (keys %$results) {
        next unless /^$mapping->{sysCertificateFileObjectName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{include_issuer} ne '' || $self->{option_results}->{include_validation} ne '') {
            my $whitelist = 0;
            $whitelist = 1 if $self->{option_results}->{include_name} ne '' &&
                                $result->{sysCertificateFileObjectName} =~ /$self->{option_results}->{include_name}/;
            $whitelist = 1 if $self->{option_results}->{include_issuer} ne '' &&
                                $result->{sysCertificateFileObjectIssuerCert} =~ /$self->{option_results}->{include_issuer}/;
            $whitelist = 1 if $self->{option_results}->{include_validation} ne '' &&
                                $result->{sysCertificateFileObjectCertStatusValidationOptions} =~ /$self->{option_results}->{include_validation}/;

            if ($whitelist == 0) {
               $self->{output}->output_add(long_msg => "skipping '" . $result->{sysCertificateFileObjectName} . "': no including filter match.", debug => 1);
               next
            }
        }

        if (($self->{option_results}->{exclude_name} ne '' && $result->{sysCertificateFileObjectName} =~ /$self->{option_results}->{exclude_name}/) ||
            ($self->{option_results}->{exclude_issuer} ne '' && $result->{sysCertificateFileObjectIssuerCert} =~ /$self->{option_results}->{exclude_issuer}/) ||
            ($self->{option_results}->{exclude_validation} ne '' && $result->{sysCertificateFileObjectCertStatusValidationOptions} =~ /$self->{option_results}->{exclude_validation}/)) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{sysCertificateFileObjectName} . "': excluding filter match.", debug => 1);
            next
        }

        my $expire_seconds = $result->{sysCertificateFileObjectExpirationDate} - $now;
        $expire_seconds = 0 if $expire_seconds < 0;

        $self->{certificates}->{$instance} = {
            name => $result->{sysCertificateFileObjectName},
            expires_date   => $result->{sysCertificateFileObjectExpirationString},
            expires_seconds => $expire_seconds,
            expires_unit   => floor($expire_seconds / $unitdiv->{ $self->{option_results}->{unit} }),
            expires_human => centreon::plugins::misc::change_seconds( value => $expire_seconds ),
        };
        $self->{global}->{count}++;
    }

    if (scalar(keys %{$self->{certificates}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No certificate found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check certificates.

    - certificates.count            Number of matching certificates.
    - certificate.expires           Time remaining before the expiration of certificates.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

Can be : certificate-expires, certificates-count

Example : --filter-counters='^certificate-expires$'

=item B<--include-name>

Filter certificate by name (regexp can be used).

Example : --include-name='ABCaBundle'

=item B<--include-issuer>

Filter certificate by issuer (regexp can be used).

=item B<--include-validation>

Filter certificate by status validation options (regexp can be used).

Example : --include-validation='1'

=item B<--exclude-name>

Exclude certificate by name (regexp can be used).

=item B<--exclude-issuer>

Exclude certificate by issuer (regexp can be used).

=item B<--exclude-validation>

Exclude certificate by status validation options (regexp can be used).

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds,'m' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-certificate-expires>

Threshold.

=item B<--critical-certificate-expires>

Threshold.

=item B<--warning-certificates-count>

Threshold.

=item B<--critical-certificates-count>

Threshold.

=back

=cut
