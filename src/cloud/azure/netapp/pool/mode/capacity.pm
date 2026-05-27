#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package cloud::azure::netapp::pool::mode::capacity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'VolumePoolAllocatedSize'               => {
            'output'              => 'Provisioned pool size',
            'label'               => 'allocated-size',
            'nlabel'              => 'aznetappaccount.pool.allocated.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumePoolAllocatedUsed'               => {
            'output'              => 'Pool allocated used size',
            'label'               => 'allocated-used',
            'nlabel'              => 'aznetappaccount.pool.allocated.used.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumePoolTotalLogicalSize'            => {
            'output'              => 'Pool consumed size',
            'label'               => 'consumed-size',
            'nlabel'              => 'aznetappaccount.pool.consumed.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumePoolTotalSnapshotSize'           => {
            'output'              => 'Pool snapshot size',
            'label'               => 'snapshot-size',
            'nlabel'              => 'aznetappaccount.pool.snapshot.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumePoolAllocatedToVolumeThroughput' => {
            'output'              => 'Pool allocated throughput',
            'label'               => 'allocated-throughput',
            'nlabel'              => 'aznetappaccount.pool.allocated.throughput.bytespersecond',
            'unit'                => 'B/s',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%s',
            'output_template'     => '%s %s/s',
            'display_ok'          => 0,
            'output_change_bytes' => 1,
        },
        'VolumePoolProvisionedThroughput'       => {
            'output'              => 'Pool provisioned throughput',
            'label'               => 'provisioned-throughput',
            'nlabel'              => 'aznetappaccount.pool.provisioned.throughput.bytespersecond',
            'unit'                => 'B/s',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%s',
            'output_template'     => '%s %s/s',
            'display_ok'          => 0,
            'output_change_bytes' => 1,
        },
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "NetApp account pool '" . $options{instance_value}->{display} .
        "' [" . $options{instance_value}->{stat} . '-' . $self->{az_interval} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'metric',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_metric_output',
            message_multiple => "All pool metrics are ok",
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{metrics_mapping} = $self->get_metrics_mapping;

    foreach my $aggregation ('average') {
        foreach my $metric_name (keys %{$self->{metrics_mapping}}) {
            my $metric_label = $self->{metrics_mapping}{$metric_name}->{label};
            my $metric = $self->{metrics_mapping}{$metric_name};
            my $entry = {
                label      => $metric_label . '-' . $aggregation,
                nlabel     => $metric->{nlabel},
                display_ok => $metric->{display_ok},
                set        => {
                    key_values      =>
                        [ { name => $metric_label . '_' . $aggregation }, { name => 'display' }, { name => 'stat' } ],
                    output_template => $metric->{label} . ': ' . $metric->{output_template},
                    perfdatas       =>
                        [
                            {
                                value                => $metric_label . '_' . $aggregation,
                                template             => $metric->{template},
                                label_extra_instance => 1,
                                unit                 => $metric->{unit},
                                min                  => $metric->{min},
                                max                  => $metric->{max}
                            },
                        ],
                }
            };

            if ($metric->{output_change_bytes}) {
                $entry->{set}->{output_change_bytes} = 1;
            }

            if ($metric->{per_second}) {
                $entry->{set}->{output_template} .= '/s';
            }

            push @{$self->{maps_counters}->{metric}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            "resource:s"       => { name => 'resource' },
            "resource-group:s" => { name => 'resource_group' },
            "account-name:s"   => { name => 'account_name' },
            "filter-metric:s"  => { name => 'filter_metric' },
            "api-version:s"    => { name => 'api_version', default => '2018-01-01' },
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->option_exit(short_msg =>
            'Need to specify either --resource <name> with --resource-group and --account-name option or --resource <id>.');
    } elsif ($self->{option_results}->{resource} !~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.NetApp\/netAppAccounts\/(.*)\/capacityPools\/(.*)$/) {
        if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq ''
            || !defined($self->{option_results}->{account_name}) || $self->{option_results}->{account_name} eq '') {
            $self->{output}->option_exit(short_msg =>
                'Need to specify --resource-group and --account-name together with --resource <name>.');
        }
    }

    $self->{az_account_name} = $self->{option_results}->{account_name};
    $self->{az_subscription_id} = $self->{option_results}->{subscription};
    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));;
    $self->{az_resource_type} = 'netAppAccounts';
    $self->{az_resource_namespace} = 'Microsoft.NetApp';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 3600;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT1H";

    $self->{az_aggregations} = [ 'average' ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    my $resource = $self->{az_resource};
    my $resource_group = $self->{az_resource_group};
    my $resource_name = $resource;
    my $account_name = $self->{az_account_name};;

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.NetApp\/netAppAccounts\/(.*)\/capacityPools\/(.*)$/) {
        $resource_group = $1;
        $account_name = $2;
        $resource_name = $3;
    } else {
        $resource = '/subscriptions/' . $self->{az_subscription_id} . '/resourceGroups/'
            . $resource_group . '/providers/Microsoft.NetApp/netAppAccounts/'
            . $account_name . '/capacityPools/' . $resource_name;
    }

    my $metrics = $options{custom}->azure_list_resource_metrics(resource => $resource);
    my %metric_values = map {
        $_->{name}->{value} => $_;
    } @$metrics;

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        my $metric_label_name = $self->{metrics_mapping}{$metric}->{label};
        next if is_excluded($metric_label_name, $self->{option_results}->{filter_metric});

        next unless exists $metric_values{$metric};

        push @{$self->{az_metrics}}, $metric;
    }

    ($metric_results{$resource_name}, undef, undef) = $options{custom}->azure_get_metrics(
        resource           => $account_name . '/capacityPools/' . $resource_name,
        resource_group     => $resource_group,
        resource_type      => $self->{az_resource_type},
        resource_namespace => $self->{az_resource_namespace},
        metrics            => $self->{az_metrics},
        aggregations       => $self->{az_aggregations},
        timeframe          => $self->{az_timeframe},
        interval           => $self->{az_interval},
    );

    foreach my $metric (@{$self->{az_metrics}}) {
        my $metric_name = lc($metric);
        $metric_name =~ s/ /_/g;
        my $metric_label_name = $self->{metrics_mapping}{$metric}->{label};
        my $aggregations = [];

        if (defined($self->{option_results}->{aggregation})) {
            foreach my $stat (@{$self->{option_results}->{aggregation}}) {
                if ($stat ne '') {
                    push @{$aggregations}, ucfirst(lc($stat));
                }
            }
        } else {
            push @{$aggregations}, lc($metric_values{$metric}->{primaryAggregationType});
        }

        foreach my $aggregation (@{$aggregations}) {
            my $metric_def = $metric_values{$metric};
            my %agg_lookup = map {lc($_) => 1} @{$metric_def->{supportedAggregationTypes}};

            next if !exists $agg_lookup{lc($aggregation)};
            next if (!defined($metric_results{$resource_name}->{$metric_name}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

            $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{display} = $resource_name;
            $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{timeframe} = $self->{az_timeframe};
            $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{stat} = lc($aggregation);
            $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{$metric_label_name . "_" . lc($aggregation)} =
                defined($metric_results{$resource_name}->{$metric_label_name}->{lc($aggregation)}) ?
                    $metric_results{$resource_name}->{$metric_label_name}->{lc($aggregation)} :
                    0;
        }
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->option_exit(short_msg =>
            'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
    }
}

1;

__END__

=head1 MODE

Check NetApp capacity pool metrics.
(https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-netapp-netappaccounts-capacitypools-metrics)

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::netapp::pool::plugin --custommode=azcli --mode=tunnel-traffic
--resource=MyResource --resource-group=MYRGROUP --critical-allocated-size='10'
--verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::netapp::pool::plugin --custommode=azcli --mode=tunnel-traffic
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.NetApp/netAppAccounts/capacityPools/xxx'
--critical-allocated-size='10' --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--account-name>

Filter resource by NetApp account name.

=item B<--filter-metric>

Filter metrics (can be: 'allocated-size', 'allocated-used', 'consumed-size', 'snapshot-size', 'allocated-throughput',
'provisioned-throughput')
Can be a regexp.

=item B<--warning-$metric$-$aggregation$>

Warning thresholds ($metric$ can be: C<allocated-size>, C<allocated-used>, C<consumed-size>, C<snapshot-size>,
C<allocated-throughput>, C<provisioned-throughput>).

=item B<--critical-$metric$-$aggregation$>

Critical thresholds ($metric$ can be: C<allocated-size>, C<allocated-used>, C<consumed-size>, C<snapshot-size>,
C<allocated-throughput>, C<provisioned-throughput>).

=back

=cut
