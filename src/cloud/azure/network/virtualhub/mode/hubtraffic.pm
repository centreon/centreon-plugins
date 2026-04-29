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

package cloud::azure::network::virtualhub::mode::hubtraffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'RoutingInfrastructureUnits'    => {
            'output'          => 'Units consumed',
            'label'           => 'units-consumed',
            'nlabel'          => 'azvirtualhub.infrastructure.units.consumed.count',
            'unit'            => '',
            'min'             => '0',
            'max'             => '',
            'template'        => '%d',
            'output_template' => '%d',
            'display_ok'      => 0,
        },
        'SpokeVMUtilization'            => {
            'output'          => 'Spoke VM Utilization',
            'label'           => 'spoke-vm-utilization',
            'nlabel'          => 'azvirtualhub.spoke.vm.utilization.percentage',
            'unit'            => '%',
            'min'             => '0',
            'max'             => '100',
            'template'        => '%.2f',
            'output_template' => '%.2f %%',
            'display_ok'      => 0
        },
        'VirtualHubDataProcessed'       => {
            'output'              => 'Data processed',
            'label'               => 'data-processed',
            'nlabel'              => 'azvirtualhub.data.processed.bytes',
            'unit'                => 'B',
            'min'                 => '0',
            'max'                 => '',
            'template'            => '%d',
            'output_template'     => '%d %s',
            'output_change_bytes' => 1,
            'display_ok'          => 1
        },
        'CountOfRoutesLearnedFromPeer'  => {
            'output'          => 'Count Of Routes Learned From Peer',
            'label'           => 'route-learned-from-peer',
            'nlabel'          => 'azvirtualhub.route.learned.from.peer.count',
            'unit'            => '',
            'min'             => '0',
            'max'             => '',
            'template'        => '%d',
            'output_template' => '%d',
            'display_ok'      => 0,
        },
        'CountOfRoutesAdvertisedToPeer' => {
            'output'          => 'Count Of Routes Advertised To Peer',
            'label'           => 'route-advertised-to-peer',
            'nlabel'          => 'azvirtualhub.route.advertised.to.peer.count',
            'unit'            => '',
            'min'             => '0',
            'max'             => '',
            'template'        => '%d',
            'output_template' => '%d',
            'display_ok'      => 0,
        },
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "Virtual Hub '" . $options{instance_value}->{display} . "' [" . $options{instance_value}->{stat} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'metric',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_metric_output',
            message_multiple => "All virtual hub metrics are ok",
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
                display_ok => ,$metric->{display_ok},
                set        => {
                    key_values      =>
                        [
                            { name => $metric_label . '_' . $aggregation },
                            { name => 'display' },
                            { name => 'stat' }
                        ],
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
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));;
    $self->{az_resource_type} = 'virtualHubs';
    $self->{az_resource_namespace} = 'Microsoft.Network';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";

    $self->{az_aggregations} = [ 'average', 'maximum', 'minimum', 'total' ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $resource (@{$self->{az_resource}}) {
        my $resource_group = $self->{az_resource_group};
        my $resource_name = $resource;
        if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Network\/virtualHubs\/(.*)$/) {
            $resource_group = $1;
            $resource_name = $2;
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

Check Virtual Hub traffic metrics.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::network::virtualhub::plugin --custommode=azcli --mode=hub-traffic
--resource=MyResource --resource-group=MYRGROUP --warning-units-consumed-maximum='10'
--verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::network::virtualhub::plugin --custommode=azcli --mode=hub-traffic
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualHubs/xxx'
--warning-units-consumed-maximum='10' --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--filter-metric>

Filter metrics (can be: C<units-consumed>, C<spoke-vm-utilization>, C<data-processed>, C<route-learned-from-peer>, C<route-advertised-to-peer>)
(can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Warning thresholds ($metric$ can be: C<units-consumed>, C<spoke-vm-utilization>, C<data-processed>, C<route-learned-from-peer>, C<route-advertised-to-peer>).

=item B<--critical-$metric$-$aggregation$>

Critical thresholds ($metric$ can be: C<units-consumed>, C<spoke-vm-utilization>, C<data-processed>, C<route-learned-from-peer>, C<route-advertised-to-peer>).

=back

=cut
