#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::costs::mode::querysubscriptions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;

sub resource_group_prefix_output {
    my ($self, %options) = @_;

    return sprintf( "Resource group '%s' ", $options{instance});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf( "Subscription costs for specified period: %.2f %s", $self->{result_values}->{subscription_cost}, $self->{result_values}->{currency});
}

sub custom_resource_group_status_output {
    my ($self, %options) = @_;

    return sprintf( "costs for specified period: %.2f %s", $self->{result_values}->{resource_group_cost}, $self->{result_values}->{currency});
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'resource_group', type => 1, cb_prefix_output => 'resource_group_prefix_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'subscription-costs', nlabel => 'subscription.global.costs', set => {
                key_values => [ { name => 'subscription_cost' }, { name => 'currency' } ],
                closure_custom_output => $self->can('custom_status_output'),
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{resource_group} = [
        { label => 'resource-group-costs', nlabel => 'resourcegroup.costs', set => {
                key_values => [ { name => 'resource_group_cost' }, { name => 'currency'} ],
                closure_custom_output => $self->can('custom_resource_group_status_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1 },
                ]
            }
        }
    ]

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "loopback:s"             => { name => 'loopback' },
                                    "resource-group:s@"      => { name => 'resource_group' }
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

}

sub create_body_payload {
    my ($self, %options) = @_;

    
    my $start_date = DateTime->now->subtract( days => $options{loopback} );
    my $end_date = DateTime->now;

    my $form_post = {
        "type" => "Usage",
        "timeframe" => "Custom",
        "dataset" => {
            "aggregation" => {
                "totalCost" => {
                    "name" => "PreTaxCost",
                    "function" => "Sum"
                }
            },
            "granularity" => "daily",
        }
    };  

    $form_post->{timeperiod}->{from} = $start_date->ymd;
    $form_post->{timeperiod}->{to} = $end_date->ymd;

    if (defined($options{resource_group}) && $options{resource_group} ne ""){
        push @{$form_post->{dataset}->{grouping}}, { "type" => "Dimension", "name" => "ResourceGroup"};
        $form_post->{dataset}->{filter}->{dimensions}->{name} = "ResourceGroup";
        $form_post->{dataset}->{filter}->{dimensions}->{operator} = "In";
        $form_post->{dataset}->{filter}->{dimensions}->{values} = $options{resource_group};
    }

    return $form_post;
}


sub manage_selection {
    my ($self, %options) = @_;
   
    my $raw_form_post = $self->create_body_payload(loopback => $self->{option_results}->{loopback}, resource_group => $self->{option_results}->{resource_group});
    my $costs = $options{custom}->azure_get_subscription_cost_management(body_post => $raw_form_post);
    
    my $sum_costs;
    my $currency; 
    
    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq ""){
        foreach my $daily_subscription_cost (@{$costs}){
            $sum_costs += ${$daily_subscription_cost}[0];
            $currency = ${$daily_subscription_cost}[2];
        }
        $self->{global} = { subscription_cost => $sum_costs,
                            currency => $currency
        };
    }
    if (defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} ne ""){
        my $resource_group_total_costs;

        foreach my $daily_resource_group_cost (@{$costs}){
            my $resource_group = ${$daily_resource_group_cost}[2];
            $sum_costs += ${$daily_resource_group_cost}[0];
            $currency = ${$daily_resource_group_cost}[3];

            $resource_group_total_costs->{$resource_group}->{sum} = $sum_costs;
            $resource_group_total_costs->{$resource_group}->{currency} = $currency;
        }

        foreach my $resource_group (keys %$resource_group_total_costs){
            $self->{resource_group}->{$resource_group} = { resource_group_cost => $resource_group_total_costs->{$resource_group}->{sum},
                                                           currency => $resource_group_total_costs->{$resource_group}->{currency}
            };
        }
    }
}

1;

__END__

=head1 MODE

=over 8

=back

=cut
