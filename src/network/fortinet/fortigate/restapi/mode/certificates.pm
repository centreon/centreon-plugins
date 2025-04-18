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

package network::fortinet::fortigate::restapi::mode::certificates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_certificate_output {
    my ($self, %options) = @_;

    return sprintf(
        "Certificate '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'certificates', type => 1, cb_prefix_output => 'prefix_certificate_output', message_multiple => 'All certificates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{certificates} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /expired/i', set => {
                key_values => [ { name => 'name' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires', nlabel => 'certificate.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'name' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'unit:s'        => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub add_certificate {
    my ($self, %options) = @_;

    return if (!defined($options{entry}->{status}));
    return if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
        $options{name} !~ /$self->{option_results}->{filter_name}/);

    $self->{certificates}->{ $options{name} } = {
        name => $options{name},
        status => $options{entry}->{status}
    };
    if (defined($options{entry}->{valid_to})) {
        $self->{certificates}->{ $options{name} }->{expires_seconds} = $options{entry}->{valid_to} - time();
        $self->{certificates}->{ $options{name} }->{expires_seconds} = 0 if ($self->{certificates}->{ $options{name} }->{expires_seconds} < 0);
        $self->{certificates}->{ $options{name} }->{expires_human} = centreon::plugins::misc::change_seconds(
            value => $self->{certificates}->{ $options{name} }->{expires_seconds}
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $certificates = $options{custom}->request_api(
        endpoint => '/api/v2/monitor/system/available-certificates'
    );

    $self->{certificates} = {};

    foreach my $certificate (@{ $certificates->{results} }) {
          if (defined($certificate->{name}) and defined($certificate->{valid_to}) and defined($certificate->{status})) {
                $self->add_certificate(name => $certificate->{name}, entry => $certificate);
          }
    }
}

1;

__END__

=head1 MODE

Check certificates.

=over 8

=item B<--filter-name>

Filter certificates by name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{status}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{status} =~ /expired/i').
You can use the following variables: %{name}, %{status}.

=item B<--unit>

Select the unit for expires threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-expires>

Thresholds.

=item B<--critical-expires>

Thresholds.

=back

=cut
