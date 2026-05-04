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

package cloud::azure::network::virtualnetwork::mode::latency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'PingMeshAverageRoundtripMs'  => {
            'output'          => 'Round trip time for Pings to a VM',
            'label'           => 'roundtrip-time',
            'nlabel'          => 'azvnet.ping.time.milliseconds',
            'unit'            => 'ms',
            'min'             => '0',
            'max'             => '',
            'template'        => '%.2f',
            'output_template' => '%.2f ms',
            'display_ok'      => 1,
        },
        'PingMeshProbesFailedPercent' => {
            'output'          => 'Failed Pings to a VM',
            'label'           => 'failed-pings',
            'nlabel'          => 'azvnet.ping.failed.percent',
            'unit'            => '%',
            'min'             => '0',
            'max'             => '100',
            'template'        => '%.2f',
            'output_template' => '%.2f %%',
            'display_ok'      => 1,
        },
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "Virtual network '" . $options{instance_value}->{display} . "' [" . $options{instance_value}->{stat} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'metric',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_metric_output',
            message_multiple => "All virtual networks metrics are ok",
            skipped_code     => { NO_VALUE() => 1 } }
    ];

    $self->{metrics_mapping} = $self->get_metrics_mapping;

    foreach my $aggregation ('minimum', 'maximum', 'average', 'total') {
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
                    output_template => $metric_label . '_' . $aggregation . ': ' . $metric->{output_template},
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
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "resource:s@"      => { name => 'resource' },
        "resource-group:s" => { name => 'resource_group' },
        "filter-metric:s"  => { name => 'filter_metric' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg =>
            'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }

    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_subscription_id} = $self->{option_results}->{subscription};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));;
    $self->{az_resource_type} = 'virtualNetworks';
    $self->{az_resource_namespace} = 'Microsoft.Network';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 3600;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT1H";

    $self->{az_aggregations} = [ 'average' ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $resource (@{$self->{az_resource}}) {
        my $resource_group = $self->{az_resource_group};

        my $resource_name = $resource;
        if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Network\/virtualNetworks\/(.*)$/) {
            $resource_group = $1;
            $resource_name = $2;
        } else {
            $resource = "/subscriptions/" . $self->{az_subscription_id} . "/resourceGroups/" . $resource_group . "/providers/Microsoft.Network/virtualNetworks/" . $resource_name;
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

        if (scalar(@{$self->{az_metrics}}) <= 0) {
            $self->{output}->add_option_msg(short_msg =>
                'No valid resource metric definitions. Please check --filter-metric option');
            $self->{output}->option_exit();
        }

        ($metric_results{$resource_name}, undef, undef) = $options{custom}->azure_get_metrics(
            resource           => $resource_name,
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
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg =>
            'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check VPN gateway tunnels traffic metrics.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::network::virtualnetwork::plugin --custommode=azcli --mode=latency
--resource=MyResource --resource-group=MYRGROUP --aggregation='average' --critical-roundtrip-time-average='10'
--verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::network::virtualnetwork::plugin --custommode=azcli --mode=latency
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx'
--aggregation='average' --critical-roundtrip-time-average='10' --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--filter-metric>

Filter metrics (can be: 'roundtrip-time', 'failed-pings')
(can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Warning thresholds ($metric$ can be: 'roundtrip-time', 'failed-pings').

=item B<--critical-$metric$-$aggregation$>

Critical thresholds ($metric$ can be: 'roundtrip-time', 'failed-pings').

=back

=cut
