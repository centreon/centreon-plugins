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

package cloud::azure::management::costs::mode::costsexplorer;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;

sub resource_group_prefix_output {
    my ($self, %options) = @_;

    return sprintf( "Resource group '%s' ", $options{instance});
}

sub custom_subscription_output {
    my ($self, %options) = @_;

    return sprintf( "Subscription costs for specified period: %.2f %s", $self->{result_values}->{subscription_cost}, $self->{result_values}->{currency});
}

sub custom_resource_group_output {
    my ($self, %options) = @_;

    return sprintf( "costs for specified period: %.2f %s", $self->{result_values}->{resource_group_cost}, $self->{result_values}->{currency});
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'resource_group', type => 1, cb_prefix_output => 'resource_group_prefix_output', message_multiple => 'All resource group costs are OK', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'subscription-costs', nlabel => 'azure.subscription.global.costs', set => {
                key_values => [ { name => 'subscription_cost' }, { name => 'currency' } ],
                closure_custom_output => $self->can('custom_subscription_output'),
                perfdatas => [
                    { template => '%.2f', min => 0 }
                ]
            }
        }
    ];
    $self->{maps_counters}->{resource_group} = [
        { label => 'resource-group-costs', nlabel => 'azure.resourcegroup.costs', set => {
                key_values => [ { name => 'resource_group_cost' }, { name => 'currency'} ],
                closure_custom_output => $self->can('custom_resource_group_output'),
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

    $options{options}->add_options(arguments => {
        "lookup-days:s"          => { name => 'lookup_days', default => 30 },
        "resource-group:s@"      => { name => 'resource_group' },
        "tags:s@"                => { name => 'tags' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{tags}) && $self->{option_results}->{tags} ne '') {
        foreach my $tag_pair (@{$self->{option_results}->{tags}}) {
            my ($key, $value) = split / => /, $tag_pair;
            next if !defined($key);
            $value = "" if !defined($value);
            centreon::plugins::misc::trim($value);
            push @{$self->{tags}->{ centreon::plugins::misc::trim($key) }}, $value;
        }
    }
}

sub create_body_filter {
    my ($self, %options) = @_;

    my $filter;
    my $resource_group_filter;

    # group by resource group if we want costs for one or multiple resource groups
    if (defined($self->{option_results}->{resource_group}) && $self->{option_results}->{resource_group} ne ""){ 
        $resource_group_filter->{dimensions}->{name} = "ResourceGroup";
        $resource_group_filter->{dimensions}->{operator} = "In";
        $resource_group_filter->{dimensions}->{values} = $self->{option_results}->{resource_group};
    }

    # if we have more than two elements to filter on (either several tags, or a tag and some resource groups) we need to have a 'and' array containing the elements
    if ((defined($self->{tags}) && keys %{$self->{tags}} > 0) && (defined($self->{option_results}->{resource_group}) && $self->{option_results}->{resource_group} ne "")
        || (defined($self->{tags}) && keys %{$self->{tags}} > 1)){
        foreach my $tag (keys %{$self->{tags}}){
            push @{$filter->{and}}, my $tags_filter = {
                tags => {
                    name => $tag,
                    operator => "In",
                    values => $self->{tags}->{$tag}
                }
            };
        }
        push @{$filter->{and}}, $resource_group_filter if keys %{$resource_group_filter} > 0; # we add a filter for resource group if at least one resource group was specified
        return $filter;
    }

    # if we have at least one tag and no resource group we need to set the filter on this tag, without the 'and'
    if (defined($self->{tags}) && keys %{$self->{tags}} >= 0 && (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq "")){
        foreach my $tag (keys %{$self->{tags}}){
            $filter = {
                tags => {
                    name => $tag,
                    operator => "In",
                    values => $self->{tags}->{$tag}
                }
            };
        }
        return $filter;
    }

    # if we only have resource group(s) specified to filter on, then we return the filter for resource group(s)
    $filter = $resource_group_filter;
    return $filter;
}

sub create_body_payload {
    my ($self, %options) = @_;

    my $start_date = DateTime->now->subtract( days => $self->{option_results}->{lookup_days} );
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

    if ((defined($self->{option_results}->{resource_group}) && $self->{option_results}->{resource_group} ne "") || 
        ((defined($self->{tags}) && keys %{$self->{tags}} > 0))){
            my $filter;
            $filter = $self->create_body_filter();
            $form_post->{dataset}->{filter} = $filter if defined($filter);
            push @{$form_post->{dataset}->{grouping}}, { "type" => "Dimension", "name" => "ResourceGroup"};
    }
    return $form_post;
}


sub manage_selection {
    my ($self, %options) = @_;
   
    my $raw_form_post = $self->create_body_payload();
    my $costs = $options{custom}->azure_get_subscription_cost_management(body_post => $raw_form_post);
    
    my $sum_costs;
    my $currency; 
    
    if ((!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq "") 
            && keys %{$self->{tags}} == 0){
        foreach my $daily_subscription_cost (@{$costs}){
            $sum_costs += ${$daily_subscription_cost}[0];
            $currency = ${$daily_subscription_cost}[2];
        }
        $self->{global} = { 
            subscription_cost => $sum_costs,
            currency => $currency
        };
    }
    if (defined($self->{option_results}->{resource_group}) || defined($self->{option_results}->{tags}) && keys %{$self->{tags}} > 0){
        my $resource_group_total_costs;

        foreach my $daily_resource_group_cost (@{$costs}){
            my $resource_group = ${$daily_resource_group_cost}[2];
            $sum_costs += ${$daily_resource_group_cost}[0];
            $currency = ${$daily_resource_group_cost}[3];

            $resource_group_total_costs->{$resource_group}->{sum} = $sum_costs;
            $resource_group_total_costs->{$resource_group}->{currency} = $currency;
        }

        foreach my $resource_group (keys %$resource_group_total_costs){
            $self->{resource_group}->{$resource_group} = {
                resource_group_cost => $resource_group_total_costs->{$resource_group}->{sum},
                currency => $resource_group_total_costs->{$resource_group}->{currency}
            };
        }
    }
    if (scalar(keys %{$self->{global}}) <= 0 && scalar(keys %{$self->{resource_group}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check costs for a subscription or per resource group.

If you don't specify a resource group or any tags then you will have costs for the whole subscription.

You can specify resource groups and tags to filter on. 

Example to get costs per subscription for the last 30 days:
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --mode=costs-explorer --custommode=api --client-id='xxx' 
--client-secret='xxx' --tenant='xxx' --subscription='xxx' --lookup-days=30 

Example to get costs for a resource group:
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --mode=costs-explorer --custommode=api --client-id='xxx' 
--client-secret='xxx' --tenant='xxx' --subscription='xxx' --lookup-days=30 --resource-group=MYRESOURCEGROUP --tags='Environment => integration'

=over 8

=item B<--resource-group>

Set resource group (optional).

If you don't, you get costs for the whole subscription.

You can specify multiple resource groups. You will get results for each one of the resource groups specified.
Example: --resource-group=MYRESOURCEGROUP1 --resource-group=MYRESOURCEGROUP2

=item B<--tags>

Set tags to filter on (optional).

You can specify multiple tags. You will get results for the resource groups matching all the tags specified.
Example: --tags='Environment => DEV' --tags='managed_by => automation'

=item B<--lookup-days>

Days backward to look up (default: '30').

=item B<--warning-subscription-costs>

Set warning threshold for subscription costs.

=item B<--critical-subscription-costs>

Set critical threshold for subscription costs.

=item B<--warning-resource-group-costs>

Set warning threshold for resource groups costs.

=item B<--critical-resource-group-costs>

Set critical threshold for resource groups costs.

=back

=cut
