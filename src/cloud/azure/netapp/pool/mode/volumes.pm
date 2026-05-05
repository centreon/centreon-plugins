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

package cloud::azure::netapp::pool::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'VolumeAllocatedSize'          => {
            'output'              => 'Volume allocated size',
            'label'               => 'allocated-size',
            'nlabel'              => 'aznetappaccount.volume.allocated.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumeLogicalSize'            => {
            'output'              => 'Volume logical size',
            'label'               => 'logical-used-size',
            'nlabel'              => 'aznetappaccount.volume.logical.used.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumeSnapshotSize'           => {
            'output'              => 'Volume snapshot size',
            'label'               => 'snaphot-size',
            'nlabel'              => 'aznetappaccount.volume.snapshot.size.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 0
        },
        'VolumeConsumedSizePercentage' => {
            'output'          => 'Volume consumed size',
            'label'           => 'consumed-size',
            'nlabel'          => 'aznetappaccount.volume.consumed.size.percentage',
            'unit'            => '%',
            'min'             => '0',
            'max'             => '100',
            'template'        => '%.2f',
            'output_template' => '%.2f %%',
            'display_ok'      => 0
        },
        'VolumeInodesPercentage'       => {
            'output'          => 'Volume Inodes size',
            'label'           => 'inodes-used-percentage',
            'nlabel'          => 'aznetappaccount.volume.inodes.used.percentage',
            'unit'            => '%',
            'min'             => '0',
            'max'             => '100',
            'template'        => '%.2f',
            'output_template' => '%.2f %%',
            'display_ok'      => 0
        },
        'ReadIops'                     => {
            'output'          => 'Volume read iops',
            'label'           => 'read-iops',
            'nlabel'          => 'aznetappaccount.volume.read.iops',
            'unit'            => 'iops',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f',
            'display_ok'      => 0
        },
        'WriteIops'                    => {
            'output'          => 'Volume write iops',
            'label'           => 'write-iops',
            'nlabel'          => 'aznetappaccount.volume.write.iops',
            'unit'            => 'iops',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f',
            'display_ok'      => 0
        },
        'TotalIops'                    => {
            'output'          => 'Volume total iops',
            'label'           => 'total-iops',
            'nlabel'          => 'aznetappaccount.volume.total.iops',
            'unit'            => 'iops',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f',
            'display_ok'      => 1
        },
        'ReadThroughput'               => {
            'output'              => 'Volume read throughput',
            'label'               => 'read-throughput',
            'nlabel'              => 'aznetappaccount.volume.throughput.read.bytespersecond',
            'unit'                => 'B/s',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%s',
            'output_template'     => '%s %s/s',
            'display_ok'          => 0,
            'output_change_bytes' => 1,
        },
        'WriteThroughput'              => {
            'output'              => 'Volume write throughput',
            'label'               => 'write-throughput',
            'nlabel'              => 'aznetappaccount.volume.throughput.write.bytespersecond',
            'unit'                => 'B/s',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%s',
            'output_template'     => '%s %s/s',
            'display_ok'          => 0,
            'output_change_bytes' => 1,
        },
        'TotalThroughput'              => {
            'output'              => 'Volume total throughput',
            'label'               => 'total-throughput',
            'nlabel'              => 'aznetappaccount.volume.throughput.total.bytespersecond',
            'unit'                => 'B/s',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%s',
            'output_template'     => '%s %s/s',
            'display_ok'          => 1,
            'output_change_bytes' => 1,
        },
        'AverageReadLatency'           => {
            'output'          => 'Average Read Latency',
            'label'           => 'read-latency',
            'nlabel'          => 'aznetappaccount.volume.latency.read.milliseconds',
            'unit'            => 'ms',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f ms',
            'display_ok'      => 1,
        },
        'AverageWriteLatency'          => {
            'output'          => 'Average Write Latency',
            'label'           => 'write-latency',
            'nlabel'          => 'aznetappaccount.volume.latency.write.milliseconds',
            'unit'            => 'ms',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f ms',
            'display_ok'      => 1,
        },
        'ThroughputLimitReached'       => {
            'output'          => 'Throughout Limit Reached',
            'label'           => 'throughput-limit-reached',
            'nlabel'          => 'aznetappaccount.volume.throughput.limit',
            'unit'            => '',
            'min'             => '0',
            'max'             => '1',
            'template'        => '%d',
            'output_template' => '%d',
            'display_ok'      => 1,
        }
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "NetApp account volume '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'metric',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_metric_output',
            message_multiple => "All pool metrics are ok",
            skipped_code     => { NO_VALUE() => 1 } }
    ];

    $self->{metrics_mapping} = $self->get_metrics_mapping;

    foreach my $metric_name (keys %{$self->{metrics_mapping}}) {
        my $metric_label = lc($metric_name);
        my $metric = $self->{metrics_mapping}{$metric_name};
        my $entry = {
            label      => $metric->{label},
            nlabel     => $metric->{nlabel},
            display_ok => $metric->{display_ok},
            set        => {
                key_values      =>
                    [ { name => $metric_label }, { name => 'display' } ],
                output_template => $metric->{label} . ': ' . $metric->{output_template},
                perfdatas       =>
                    [
                        {
                            value                => $metric_label,
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "resource:s"       => { name => 'resource' },
        "resource-group:s" => { name => 'resource_group' },
        "account-name:s"   => { name => 'account_name' },
        "pool-name:s"      => { name => 'pool_name' },
        "filter-metric:s"  => { name => 'filter_metric' },
        "api-version:s"    => { name => 'api_version', default => '2018-01-01' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->option_exit(short_msg =>
            'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
    } elsif ($self->{option_results}->{resource} !~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.NetApp\/netAppAccounts\/(.*)\/capacityPools\/(.*)\/volumes\/(.*)$/) {
        if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq ''
            || !defined($self->{option_results}->{account_name}) || $self->{option_results}->{account_name} eq '') {
            $self->{output}->option_exit(short_msg =>
                'Need to specify --resource-group and --account-name together with --resource <name>.');
        }
    }

    $self->{az_account_name} = $self->{option_results}->{account_name};
    $self->{az_pool_name} = $self->{option_results}->{pool_name};
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
    my $account_name = $self->{az_account_name};
    my $pool_name = $self->{az_pool_name};

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.NetApp\/netAppAccounts\/(.*)\/capacityPools\/(.*)\/volumes\/(.*)$/) {
        $resource_group = $1;
        $account_name = $2;
        $pool_name = $3;
        $resource_name = $4;
    } else {
        $resource = '/subscriptions/' . $self->{az_subscription_id} . '/resourceGroups/'
            . $resource_group . '/providers/Microsoft.NetApp/netAppAccounts/'
            . $account_name . '/capacityPools/' . $pool_name . '/volumes/' . $resource_name;
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
        resource           => $account_name . '/capacityPools/' . $pool_name . '/volumes/' . $resource_name,
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

        next if (!defined($metric_results{$resource_name}->{$metric_name}->{average}) && !defined($self->{option_results}->{zeroed}));

        $self->{metric}->{$resource_name}->{display} = $resource_name;
        $self->{metric}->{$resource_name}->{timeframe} = $self->{az_timeframe};
        $self->{metric}->{$resource_name }->{$metric_name} =
            defined($metric_results{$resource_name}->{$metric_name}->{average}) ?
                $metric_results{$resource_name}->{$metric_name}->{average} :
                0;
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->option_exit(short_msg =>
            'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
    }
}

1;

__END__

=head1 MODE

Check NetApp pool volume metrics.
(https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-netapp-netappaccounts-capacitypools-volumes-metrics)

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::netapp::pool::plugin --custommode=azcli --mode=volumes
--resource=MyResource --resource-group=MYRGROUP --critical-allocated-size='10'
--verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::netapp::pool::plugin --custommode=azcli --mode=volumes
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworkGateways/xxx'
--critical-allocated-size='10' --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--filter-metric>

Filter metrics (can be: 'allocated-size', 'logical-used-size', 'snaphot-size', 'consumed-size', 'inodes-used-percentage',
'read-iops', 'write-iops', 'total-iops', 'read-throughput', 'write-throughput', 'total-throughput', 'read-latency',
'write-latency', 'throughput-limit-reached')
Can be a regexp.

=item B<--warning-allocated-size>

Warning thresholds.

=item B<--critical-allocated-size>

Critical thresholds.

=item B<--warning-logical-used-size>

Warning thresholds.

=item B<--critical-logical-used-size>

Critical thresholds.

=item B<--warning-snaphot-size>

Warning thresholds.

=item B<--critical-snaphot-size>

Critical thresholds.

=item B<--warning-consumed-size>

Warning thresholds.

=item B<--critical-consumed-size>

Critical thresholds.

=item B<--warning-inodes-used-percentage>

Warning thresholds.

=item B<--critical-inodes-used-percentage>

Critical thresholds.

=item B<--warning-read-iops>

Warning thresholds.

=item B<--critical-read-iops>

Critical thresholds.

=item B<--warning-write-iops>

Warning thresholds.

=item B<--critical-write-iops>

Critical thresholds.

=item B<--warning-total-iops>

Warning thresholds.

=item B<--critical-total-iops>

Critical thresholds.

=item B<--warning-read-throughput>

Warning thresholds.

=item B<--critical-read-throughput>

Critical thresholds.

=item B<--warning-write-throughput>

Warning thresholds.

=item B<--critical-write-throughput>

Critical thresholds.

=item B<--warning-total-throughput>

Warning thresholds.

=item B<--critical-total-throughput>

Critical thresholds.

=item B<--warning-read-latency>

Warning thresholds.

=item B<--critical-read-latency>

Critical thresholds.

=item B<--warning-write-latency>

Warning thresholds.

=item B<--critical-write-latency>

Critical thresholds.

=item B<--warning-throughput-limit-reached>

Warning thresholds.

=item B<--critical-throughput-limit-reached>

Critical thresholds.

=back

=cut
