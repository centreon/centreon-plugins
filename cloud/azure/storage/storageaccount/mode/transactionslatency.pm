#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::azure::storage::storageaccount::mode::transactionslatency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_metric_output {
    my ($self, %options) = @_;

    my $msg = "Resource '" . $options{instance_value}->{display} . "'";
    $msg .= " (" . $options{instance_value}->{namespace} . ")" if ($options{instance_value}->{namespace} ne '');
    $msg .= " " . $options{instance_value}->{stat} . " ";
    
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All transactions metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $aggregation ('minimum', 'maximum', 'average', 'total') {
        foreach my $metric ('SuccessServerLatency', 'SuccessE2ELatency') {
            my $metric_label = lc($metric);
            my $entry = { label => $metric_label . '-' . $aggregation, set => {
                                key_values => [ { name => $metric_label . '_' . $aggregation }, { name => 'display' }, { name => 'stat' } ],
                                output_template => $metric . ': %.2f ms',
                                perfdatas => [
                                    { label => $metric_label . '_' . $aggregation, value => $metric_label . '_' . $aggregation . '_absolute', 
                                      template => '%.2f', unit => 'ms', label_extra_instance => 1, instance_use => 'display_absolute',
                                      min => 0 },
                                ],
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "resource:s@"           => { name => 'resource' },
        "resource-group:s"      => { name => 'resource_group' },
        "resource-namespace:s"  => { name => 'resource_namespace' },
        "filter-metric:s"       => { name => 'filter_metric' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group option or --resource <id>.");
        $self->{output}->option_exit();
    }
    
    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));
    $self->{az_resource_type} = 'storageAccounts';
    $self->{az_resource_namespace} = 'Microsoft.Storage';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";
    $self->{az_resource_extra_namespace} = defined($self->{option_results}->{resource_namespace}) ? $self->{option_results}->{resource_namespace} : '';
    $self->{az_aggregations} = ['Average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric ('SuccessServerLatency', 'SuccessE2ELatency') {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{az_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $resource (@{$self->{az_resource}}) {
        my $resource_group = $self->{az_resource_group};
        my $resource_name = $resource;
        my $namespace = $self->{az_resource_namespace};
        my $namespace_full = ($self->{az_resource_extra_namespace} ne '') ? '/' . lc($self->{az_resource_extra_namespace}) . 'Services/default' : '';
        my $namespace_name = ($self->{az_resource_extra_namespace} ne '') ? $self->{az_resource_extra_namespace} : "Account";
        if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Storage\/storageAccounts\/(.*)\/(.*)\/default$/ ||
            $resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Storage\/storageAccounts\/(.*)$/) {
            $resource_group = $1;
            $resource_name = $2;
            $namespace_full = '/' . $3 . '/default' if(defined($3));
            $namespace_name = $3 if(defined($3));
        }
        $namespace_name =~ s/Services//g;

        ($metric_results{$resource_name}, undef, undef) = $options{custom}->azure_get_metrics(
            resource => $resource_name . $namespace_full,
            resource_group => $resource_group,
            resource_type => $self->{az_resource_type},
            resource_namespace => $namespace,
            metrics => $self->{az_metrics},
            aggregations => $self->{az_aggregations},
            timeframe => $self->{az_timeframe},
            interval => $self->{az_interval},
        );

        foreach my $metric (@{$self->{az_metrics}}) {
            my $metric_name = lc($metric);
            $metric_name =~ s/ /_/g;
            foreach my $aggregation (@{$self->{az_aggregations}}) {
                next if (!defined($metric_results{$resource_name}->{$metric_name}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{display} = $resource_name;
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{timeframe} = $self->{az_timeframe};
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{stat} = lc($aggregation);
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{namespace} = ucfirst($namespace_name);
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{$metric_name . "_" . lc($aggregation)} = defined($metric_results{$resource_name}->{$metric_name}->{lc($aggregation)}) ? $metric_results{$resource_name}->{$metric_name}->{lc($aggregation)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage account resources transaction latency metrics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::storage::storageaccount::plugin --custommode=azcli --mode=transactions-latency
--resource=MYFILER --resource-group=MYHOSTGROUP --resource-namespace=Blob --aggregation='average'
--critical-successserverlatency-average='10' --verbose

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::storage::storageaccount::plugin --custommode=azcli --mode=transactions-latency
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Storage/storageAccounts/xxx'
--aggregation='average' --critical-successserverlatency-average='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--resource-namespace>

Set resource namespace (Can be: 'Blob', 'File', 'Table', 'Queue').
Leave empty for account metric.

=item B<--filter-metric>

Filter metrics (Can be: 'SuccessServerLatency', 'SuccessE2ELatency') (Can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Thresholds warning ($metric$ can be: 'successserverlatency', 'successe2elatency',
$aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--critical-$metric$-$aggregation$>

Thresholds critical ($metric$ can be: 'successserverlatency', 'successe2elatency',
$aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=back

=cut
