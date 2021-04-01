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

package apps::protocols::x509::mode::certificate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

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
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2,
            warning_default => '%{expiration} < 60',
            critical_default => '%{expiration} < 30',
            set => {
                key_values => [
                    { name => 'subject' }, { name => 'issuer' },
                    { name => 'expiration' }, { name => 'date' },
                    { name => 'alt_subjects' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cert = $options{custom}->get_certificate_informations();

    $self->{global} = {
        subject => $cert->{subject},
        issuer => $cert->{issuer},
        expiration => $cert->{expiration},
        date => $cert->{expiration_date},
        alt_subjects => $cert->{alt_subjects}
    };
}

1;

__END__

=head1 MODE

Check X509's certificate validity (for SMTPS, POPS, IMAPS, HTTPS)

=over 8

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
