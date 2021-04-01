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

package apps::cisco::cms::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status is '%s'", $self->{result_values}->{status}); 
    $msg .= sprintf(", expires in %d days [%s]",
        $self->{result_values}->{expiry_days},
        $self->{result_values}->{expiry_date}) if (defined($self->{result_values}->{expiry_date}) && $self->{result_values}->{expiry_date} ne '');
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{feature} = $options{new_datas}->{$self->{instance} . '_feature'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{expiry_date} = $options{new_datas}->{$self->{instance} . '_expiry_date'};
    $self->{result_values}->{expiry_seconds} = $options{new_datas}->{$self->{instance} . '_expiry_seconds'};
    $self->{result_values}->{expiry_days} = ($self->{result_values}->{expiry_seconds} ne '') ? $self->{result_values}->{expiry_seconds} / 86400 : 0;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'features', type => 1, cb_prefix_output => 'prefix_feature_output', message_multiple => 'All features licensing are ok' },
    ];

    $self->{maps_counters}->{features} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'feature' }, { name => 'status' }, { name => 'expiry_date' }, { name => 'expiry_seconds' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_feature_output {
    my ($self, %options) = @_;

    return "Feature '" . $options{instance_value}->{feature} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "warning-status:s"      => { name => 'warning_status', default => '%{status} eq "activated" && %{expiry_days} < 60' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} eq "activated" && %{expiry_days} < 30' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_endpoint(method => '/system/licensing');

    $self->{features} = {};

    foreach my $feature (keys %{$results->{features}}) {
        my %months = ("Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12);
        $results->{features}->{$feature}->{expiry} =~ /^(\d+)-(\w+)-(\d+)$/ if (defined($results->{features}->{$feature}->{expiry})); # 2100-Jan-01
        my $dt = DateTime->new(year => $1, month => $months{$2}, day => $3);

        $self->{features}->{$feature} = {
            feature => $feature,
            status => $results->{features}->{$feature}->{status},
            expiry_date => (defined($results->{features}->{$feature}->{expiry})) ? $results->{features}->{$feature}->{expiry} : '',
            expiry_seconds => (defined($results->{features}->{$feature}->{expiry})) ? $dt->epoch - time() : '',
        };
    }

    if (scalar(keys %{$self->{features}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No features found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check features licensing.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} eq "activated" && %{expiry_days} < 60').
Can use special variables like: %{status}, %{expiry_days}, %{feature}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} eq "activated" && %{expiry_days} < 30').
Can use special variables like: %{status}, %{expiry_days}, %{feature}

=back

=cut
