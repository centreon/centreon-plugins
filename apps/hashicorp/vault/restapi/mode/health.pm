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

package apps::hashicorp::vault::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

# sub custom_status_output {
#     my ($self, %options) = @_;

#     return sprintf('Id: %s, Status: %s', $self->{result_values}->{id}, $self->{result_values}->{status});
# }

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vault_cluster', type => 1, cb_prefix_output => 'custom_prefix_output'},
    ];

    $self->{maps_counters}->{vault_cluster} = [
        { label => 'sealed-status', type => 2, critical_default => '%{sealed} eq "sealed"', set => {
                key_values => [ { name => 'sealed' } ],
                output_template => "sealed status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'init-status', type => 2, critical_default => '%{init} ne "initialized"', set => {
                key_values => [ { name => 'init' } ],
                output_template => "init status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub custom_prefix_output {
    my ($self, %options) = @_;

    return 'Server ' . $self->{option_results}->{hostname} . ': ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

}

sub manage_selection {
    my ($self, %options) = @_;
    
    # API will return 503 when the vault is sealed
    my $custom_status = '%{http_code} < 200 or (%{http_code} >= 300 and %{http_code} !=503)';
    
    my $result = $options{custom}->request_api(
        url_path => '/health',
        overload_status => 1,
        overload_status_type => 'unknown',
        custom_status => $custom_status
    );

    $self->{vault_cluster}->{$self->{option_results}->{hostname}} = {
        sealed => $result->{sealed} ? 'sealed' : 'unsealed',
        init => $result->{initialized} ? 'initialized' : 'not initialized',
    };
}

1;

__END__

=head1 MODE

Check Hashicorp Vault Health status.

Example:
perl centreon_plugins.pl --plugin=apps::hashicorp::vault::restapi::plugin --mode=health
--hostname=10.0.0.1 --vault-token='s.aBCD123DEF456GHI789JKL012' --verbose

More information on'https://www.vaultproject.io/api-docs/system/health'.

=over 8

=item B<--filter-name>

Filter by application name (Regexp can be used).
Example: --filter-name='^application1$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --warning-status='%{status} ne "STARTED"'

=item B<--critical-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --critical-status='%{status} ~= m/FAILED/'

=back

=cut
