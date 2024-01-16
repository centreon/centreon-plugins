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

package cloud::microsoft::office365::management::mode::subscriptions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'capability status: ' . $self->{result_values}->{capabilityStatus};
}

sub custom_subscription_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_subscription_output {
    my ($self, %options) = @_;
    
    return "Subscriptions '" . $options{instance_value}->{skuPartNumber} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'subscriptions', type => 1, cb_prefix_output => 'prefix_subscription_output', message_multiple => 'All subscriptions are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{subscriptions} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{capabilityStatus} =~ /warning/i',
            set => {
                key_values => [
                    { name => 'capabilityStatus' }, { name => 'skuPartNumber' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'subscription-usage', nlabel => 'subscription.usage.count', set => {
                key_values => [
                    { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'skuPartNumber' }
                ],
                closure_custom_output => $self->can('custom_subscription_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'skuPartNumber' }
                ]
            }
        },
        { label => 'subscription-usage-free', display_ok => 0, nlabel => 'subscription.free.count', set => {
                key_values => [
                    { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'skuPartNumber' }
                ],
                closure_custom_output => $self->can('custom_subscription_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'skuPartNumber' }
                ]
            }
        },
        { label => 'subscription-usage-prct', display_ok => 0, nlabel => 'subscription.usage.percentage', set => {
                key_values => [
                    { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' },
                    { name => 'skuPartNumber' }
                ],
                closure_custom_output => $self->can('custom_subscription_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'skuPartNumber' }
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
        'filter-sku-part-number:s' => { name => 'filter_sku_part_number' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->list_subscribed_skus();

    $self->{subscriptions} = {};
    foreach my $subscription (@$results) {
        next if (defined($self->{option_results}->{filter_sku_part_number}) && $self->{option_results}->{filter_sku_part_number} ne '' &&
            $subscription->{skuPartNumber} !~ /$self->{option_results}->{filter_sku_part_number}/);

        $self->{subscriptions}->{ $subscription->{id} } = {
            skuPartNumber => $subscription->{skuPartNumber},
            capabilityStatus => lc($subscription->{capabilityStatus})
        };
        my $total = $subscription->{prepaidUnits}->{enabled} > 0 ? $subscription->{prepaidUnits}->{enabled} : $subscription->{prepaidUnits}->{warning};
        next if ($total == 0);

        $self->{subscriptions}->{ $subscription->{id} }->{total} = $total;
        $self->{subscriptions}->{ $subscription->{id} }->{used} = $subscription->{consumedUnits};
        $self->{subscriptions}->{ $subscription->{id} }->{free} = $total - $subscription->{consumedUnits};
        $self->{subscriptions}->{ $subscription->{id} }->{prct_used} = $subscription->{consumedUnits} * 100  / $total;
        $self->{subscriptions}->{ $subscription->{id} }->{prct_free} = 100 - $self->{subscriptions}->{ $subscription->{id} }->{prct_used};
    }

    if (scalar(keys %{$self->{subscriptions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No subscriptions found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SKU subcriptions.

=over 8

=item B<--filter-sku-part-number>

Filter subscriptions by SKU part number (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warning/i').
You can use the following variables: %{capabilityStatus}, %{skuPartNumber}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{capabilityStatus}, %{skuPartNumber}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'subscription-usage', 'subscription-usage-free', 'subscription-usage-prct'.

=back

=cut
