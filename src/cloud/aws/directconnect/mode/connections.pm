#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package cloud::aws::ec2::mode::connections;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All connections are ok'
        },
        metrics => {
            ConnectionBpsEgress => {
                output => 'outbound data',
                label => 'connection-egress',
                nlabel => {
                    absolute => 'connection.egress.bitspersecond',
                },
                unit => 'b'
            },
            ConnectionBpsIngress => {
                output => 'inbound data',
                label => 'connection-ingress',
                nlabel => {
                    absolute => 'connection.ingress.bitspersecond',
                },
                unit => 'b'
            },
            ConnectionPpsEgress => {
                output => 'outbound packets data',
                label => 'connection-packets-egress',
                nlabel => {
                    absolute => 'connection.egress.packets.persecond',
                },
                unit => 'b'
            },
            ConnectionPpsIngress => {
                output => 'inbound packet data',
                label => 'connection-packets-ingress',
                nlabel => {
                    absolute => 'connection.ingress.packets.persecond',
                },
                unit => 'b'
            }
        },
        fiber_metrics => {
            ConnectionLightLevelTx => {
                output => 'outbound light level',
                label => 'connection-ligh-level-outbound',
                nlabel => {
                    absolute => 'connection.outbound.light.level.dbm',
                },
                unit => 'dBm'
            },
            ConnectionLightLevelRx => {
                output => 'inbound light level',
                label => 'connection-ligh-level-inbound',
                nlabel => {
                    absolute => 'connection.inbound.light.level.dbm',
                },
                unit => 'dBm'
            }
        }
    };

    return $metrics_mapping;
}

sub custom_fiber_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{lane_number} = $options{new_datas}->{$self->{instance} . '_lane_number'};
    $self->{result_values}->{value} = $options{new_datas}->{ $self->{instance} . '_' . $options{extra_options}->{metric} };
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_fiber_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_fiber_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => [$self->{instance}, $self->{result_values}->{lane_number}],
        nlabel    => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{nlabel}->{per_second} :
            $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{nlabel}->{absolute},
        unit      => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{unit} . '/s' :
            $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{unit},
        value     => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{result_values}->{value_per_sec} :
            $self->{result_values}->{value}),
        min       => $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{min},
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{label}),
    );
}

sub custom_fiber_metric_output {
    my ($self, %options) = @_;

    my $msg = '';
    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        my ($value, $unit) = ($self->{result_values}->{value_per_sec}, $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{unit});
        $msg = sprintf("%s: %.2f %s", $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{output}, $value, $unit . '/s');
    } else {
        my ($value, $unit) = ($self->{result_values}->{value}, $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{unit});
        $msg = sprintf("%s: %.2f %s", $self->{instance_mode}->{fiber_metrics_mapping}->{ $self->{result_values}->{metric} }->{output}, $value, $unit);
    }
    return $msg;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "connection '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking connection '" . $options{instance_value}->{display} . "' ";
}

sub prefix_fiber_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' optical lane number '" . $options{instance_value}->{lane_number} . "' Metrics ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->SUPER::set_counters(%options);

    my $data = $self->get_metrics_mapping();
    $self->{fiber_metrics_mapping} = $data->{fiber_metrics};

    push @{$self->{maps_counters_type}->[0]->{group}}, {
        name => 'state',
        type => 0, skipped_code => { -10 => 1 }
    };
    push @{$self->{maps_counters_type}->[0]->{group}}, {
        name => 'fiber_statistics', display_long => 1, cb_prefix_output => 'prefix_fiber_statistics_output',
        message_multiple => 'All fiber metrics are ok', type => 1, skipped_code => { -10 => 1 }
    };

    $self->{maps_counters}->{state} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'bandwidth' }, { name => 'connectionName' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    foreach my $metric (keys %{$self->{fiber_metrics_mapping}}) {
        my $entry = {
            label => $self->{fiber_metrics_mapping}->{$metric}->{label},
            set => {
                key_values                          => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' }, { name => 'lane_number' } ],
                closure_custom_calc                 => $self->can('custom_fiber_metric_calc'),
                closure_custom_calc_extra_options   => { metric => $metric },
                closure_custom_output               => $self->can('custom_fiber_metric_output'),
                closure_custom_perfdata             => $self->can('custom_fiber_metric_perfdata'),
                closure_custom_threshold_check      => $self->can('custom_fiber_metric_threshold')
            }
        };
        push @{$self->{maps_counters}->{fiber_statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-connection-id:s' => { name => 'filter_connection_id' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{aws_fiber_metrics} = [];
    foreach my $metric (keys %{$self->{fiber_metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{aws_fiber_metrics}}, $metric;
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $connections = $options{custom}->directconnect_describe_connections();

    foreach $connection_id (keys %$connections) {
        next if (defined($self->{option_results}->{filter_connection_id}) && $self->{option_results}->{filter_connection_id} ne ''
            && $connection_id !~ /$self->{option_results}->{filter_connection_id}/);

        $self->{metrics}->{$connection_id} = {
            display => $connections->{$connection_id}->{name},
            status => {
                connectionName => $connections->{$connection_id}->{name},
                bandwidth => $connections->{$connection_id}->{bandwidth},
                state => $connections->{$connection_id}->{state}
            },
            statistics => {},
            fiber_statistics => {}
        };

        my $cw_metrics = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/DX',
            dimensions => [ { ConnectionId => $connection_id } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($cw_metrics->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$connection_id}->{display} = $connections->{$connection_id}->{name};
                $self->{metrics}->{$connection_id}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$connection_id}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$connection_id}->{statistics}->{lc($statistic)}->{$metric} = 
                    defined($cw_metrics->{$metric}->{lc($statistic)}) ? 
                    $cw_metrics->{$metric}->{lc($statistic)} : 0;
            }
        }

        $cw_metrics = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/DX',
            dimensions => [ { ConnectionId => $connection_id } ],
            metrics => $self->{aws_fiber_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_fiber_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($cw_metrics->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$instance}->{display} = $connections->{$connection_id}->{name};
                $self->{metrics}->{$instance}->{lane_number} = $connections->{$connection_id}->{plop};
                $self->{metrics}->{$instance}->{fiber_statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{fiber_statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$instance}->{fiber_statistics}->{lc($statistic)}->{$metric} = 
                    defined($cw_metrics->{$metric}->{lc($statistic)}) ? 
                    $cw_metrics->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No connection found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check direct connect connections.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::directconnect::plugin --custommode=paws --mode=connections --region='eu-west-1'
--name='centreon-middleware' --filter-metric='ConnectionBpsEgress' --statistic='average'
--critical-connection-egress='10Mb' --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--filter-connection-id>

Filter connection id (can be a regexp).

=item B<--filter-metric>

Filter metrics (Can be: 'ConnectionBpsEgress', 'ConnectionBpsIngress', 
'ConnectionPpsEgress', 'ConnectionPpsIngress', 'ConnectionLightLevelTx', 'ConnectionLightLevelRx') 
(Can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{bandwidth}, %{connectionName}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{state}, %{bandwidth}, %{connectionName}

=item B<--warning-*> B<--critical-*>

Thresholds (Can be 'connection-egress', 'connection-ingress', 
'connection-packets-egress', 'connection-packets-ingress',
'connection-ligh-level-outbound', 'connection-ligh-level-inbound).

=back

=cut
