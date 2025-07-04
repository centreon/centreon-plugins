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

package apps::hashicorp::vault::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vault_cluster', type => 1, cb_prefix_output => 'custom_prefix_output'},
    ];

    $self->{maps_counters}->{vault_cluster} = [
        { label => 'seal-status', type => 2, critical_default => '%{sealed} ne "unsealed"', set => {
                key_values => [ { name => 'sealed' } ],
                output_template => "seal status : %s",
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
        },
        { label => 'standby-status', type => 2, set => {
                key_values => [ { name => 'standby' } ],
                output_template => "standby status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub custom_prefix_output {
    my ($self, %options) = @_;

    return 'Server ' . $options{instance_value}->{cluster_name} . ' ';
}

# List of parameteres added during the API call
our @code_parameters = (
    { 'code' => 'perfstandbyok', 'type' => 'bool' },
    { 'code' => 'activecode', 'type' => 'status' },
    { 'code' => 'drsecondarycode', 'type' => 'status' },
    { 'code' => 'haunhealthycode', 'type' => 'status' },
    { 'code' => 'performancestandbycode', 'type' => 'status' },
    { 'code' => 'removedcode', 'type' => 'status' },
    # By default API will return error codes if sealed, uninit or standby
    { 'code' => 'standbyok', 'type' => 'bool', default => 'true' },
    { 'code' => 'sealedcode', 'type' => 'status', default => '200' },
    { 'code' => 'uninitcode', 'type' => 'status', default => '200' },
    { 'code' => 'standbycode', 'type' => 'status', default => '200' },
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    my %arguments;

    $arguments{$_->{'code'}.':s'} = { name => $_->{'code'}, default => $_->{'default'} // '', }
        foreach (@code_parameters);

    $options{options}->add_options(arguments => \%arguments );

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $param (@code_parameters) {
        my $value = lc $self->{option_results}->{$param->{'code'}};
        next if $value eq '';

        my $valid = 0;
        if ($param->{'type'} eq 'status') {
            $valid = $value =~ /^\d{1,3}$/;
        } elsif ($param->{'type'} eq 'bool') {
            $valid = $value eq 'true' || $value eq 'false';

            $self->{option_results}->{$param->{code}} = lc $value;
        }

        unless ($valid) {
            $self->{output}->add_option_msg(short_msg => "Invalid value for ".$param->{'code'}.".");
            $self->{output}->option_exit();
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my @code_arr;

    foreach my $param (@code_parameters) {
        next if $self->{option_results}->{$param->{'code'}} eq '';

        push @code_arr, $param->{'code'} .'='. $self->{option_results}->{$param->{'code'}};
    }

    my $result = $options{custom}->request_api(url_path => 'health' . (@code_arr ? '?'.join('&', @code_arr) : ''));
    my $cluster_name = defined($result->{cluster_name}) ? $result->{cluster_name} : $self->{option_results}->{hostname};

    $self->{vault_cluster}->{$cluster_name} = {
        cluster_name => $cluster_name,
        sealed => $result->{sealed} ? 'sealed' : 'unsealed',
        init => $result->{initialized} ? 'initialized' : 'not initialized',
        standby => $result->{standby} ? 'true' : 'false',
    };
}

1;

__END__

=head1 MODE

Check HashiCorp Vault Health status.

Example:
perl centreon_plugins.pl --plugin=apps::hashicorp::vault::restapi::plugin --mode=health
--hostname=10.0.0.1 --vault-token='s.aBCD123DEF456GHI789JKL012' --verbose

More information on'https://developer.hashicorp.com/vault/api-docs/system/health'.

=over 8

=item B<--standbyok --perfstandbyok --activecode --standbycode --drsecondarycode --haunhealthycode --performancestandbycode --removedcode --sealedcode --uninitcode>

Arguments to pass to the health API call, default are --sealedcode=200 and --uninitcode=200.

More information on'https://developer.hashicorp.com/vault/api-docs/system/health#parameters.'

=item B<--warning-seal-status>

Set warning threshold for seal status (default: none).

=item B<--critical-seal-status>

Set critical threshold for seal status (default: '%{sealed} ne "unsealed"').

=item B<--warning-init-status>

Set warning threshold for initialization status (default: none).

=item B<--critical-init-status>

Set critical threshold for initialization status (default: '%{init} ne "initialized"').

=item B<--warning-standby-status>

Set warning threshold for standby status (default: none).

=item B<--critical-standby-status>

Set critical threshold for standby status (default: none).

=back

=cut
