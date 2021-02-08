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

package cloud::aws::transitgateway::mode::traffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'BytesIn' => {
        'output' => 'Bytes In',
        'label'  => 'bytes-in',
        'nlabel' => {
            'absolute'   => 'gateway.traffic.in.bytes',
            'per_second' => 'gateway.traffic.in.bytespersecond'
        },
        'unit'   => 'B'
    },
    'BytesOut' => {
        'output' => 'Bytes Out',
        'label'  => 'bytes-out',
        'nlabel' => {
            'absolute'   => 'gateway.traffic.out.bytes',
            'per_second' => 'gateway.traffic.out.bytespersecond'
        },
        'unit'   => 'B'
    },
    'PacketsIn' => {
        'output' => 'Packets Received (In)',
        'label'  => 'packets-in',
        'nlabel' => {
            'absolute'   => 'gateway.packets.in.count',
            'per_second' => 'gateway.packets.in.countpersecond'
        },
        'unit'   => ''
    },
    'PacketsOut' => {
        'output' => 'Packets Sent (Out)',
        'label'  => 'packets-out',
        'nlabel' => {
            'absolute'   => 'gateway.packets.out.count',
            'per_second' => 'gateway.packets.out.countpersecond'
        },
        'unit'   => ''
    },
    'PacketDropCountBlackhole' => {
        'output' => 'Packets Drop Blackhole',
        'label'  => 'packets-drop-blackhole',
        'nlabel' => {
            'absolute'   => 'gateway.packets.blackholedropped.count',
            'per_second' => 'gateway.packets.blackholedropped.countpersecond'
        },
        'unit'   => ''
    },
    'PacketDropCountNoRoute' => {
        'output' => 'Packets Drop No Route',
        'label'  => 'packets-drop-noroute',
        'nlabel' => {
            'absolute'   => 'gateway.packets.noroutedropped.count',
            'per_second' => 'gateway.packets.noroutedropped.countpersecond'
        },
        'unit'   => ''
    }
);


sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value     => defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        nlabel    => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $metrics_mapping{$self->{result_values}->{metric}}->{nlabel}->{per_second} :
            $metrics_mapping{$self->{result_values}->{metric}}->{nlabel}->{absolute},
        unit      => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $metrics_mapping{$self->{result_values}->{metric}}->{unit} . '/s' :
            $metrics_mapping{$self->{result_values}->{metric}}->{unit},
        value     => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{result_values}->{value_per_sec} :
            $self->{result_values}->{value}),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;
    my $msg = "";

    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        my ($value, $unit) = ($metrics_mapping{$self->{result_values}->{metric}}->{unit} eq 'B') ?
            $self->{perfdata}->change_bytes(value => $self->{result_values}->{value_per_sec}) :
            ($self->{result_values}->{value_per_sec}, $metrics_mapping{$self->{result_values}->{metric}}->{unit});
        $msg = sprintf("%s: %.2f %s", $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value, $unit . '/s');
    } else {
        my ($value, $unit) = ($metrics_mapping{$self->{result_values}->{metric}}->{unit} eq 'B') ?
            $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}) :
            ($self->{result_values}->{value}, $metrics_mapping{$self->{result_values}->{metric}}->{unit});
        $msg = sprintf("%s: %.2f %s", $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value, $unit);
    }
    return $msg;
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "AWS TransitGateway'" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All TransitGateways metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            set => {
                key_values                        => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc               => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output             => $self->can('custom_metric_output'),
                closure_custom_perfdata           => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check    => $self->can('custom_metric_threshold')
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-gateway:s' => { name => 'filter_gateway' },
        'filter-metric:s'  => { name => 'filter_metric' },
        'per-sec'          => { name => 'per_sec' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;

    $self->{aws_statistics} = ['Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    };
    foreach my $metric (keys %metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{aws_metrics}}, $metric;
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{gateways} = $options{custom}->tgw_list_gateways();

    my %metric_results;
    foreach my $instance (@{$self->{gateways}}) {
        next if (defined($self->{option_results}->{filter_gateway}) && $self->{option_results}->{filter_gateway} ne ''
            && $instance->{id} !~ /$self->{option_results}->{filter_gateway}/);

        $instance->{name} =~ s/ /_/g;

        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace  => 'AWS/TransitGateway',
            dimensions => [ { Name => 'TransitGateway', Value => $instance->{id} } ],
            metrics    => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe  => $self->{aws_timeframe},
            period     => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));
                $self->{metrics}->{ $instance->{id} }->{display} = $instance->{id};
                $self->{metrics}->{ $instance->{id} }->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{ $instance->{id} }->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{ $instance->{id} }->{statistics}->{lc($statistic)}->{$metric} =
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ?
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AWS TransitGateways statistics.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::transitgateway::plugin --custommode=awscli --mode=traffic --region='eu-west-1'
--filter-gateway='MyTGW_1' --warning-packets-drop-blackole='500' --critical-packets-drop-blackole='1000' --verbose

See 'https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-cloudwatch-metrics.html' for more information.


=over 8

=item B<--filter-gateway>

Filter on a specific TransitGateway ID. This filter is based on the "TransitGatewayId" attribute of the gateway.

=item B<--filter-metric>

Filter on a specific metric.
Can be: BytesIn, BytesOut, PacketsIn, PacketsOut, PacketDropCountBlackhole, PacketDropCountNoRoute

=item B<--warning-$metric$>

Warning thresholds ($metric$ can be: 'bytes-in', 'bytes-out', 'packets-in', 'packets-out',
'packets-drop-blackhole', 'packets-drop-noroute').

=item B<--critical-$metric$>

Critical thresholds ($metric$ can be: 'bytes-in', 'bytes-out', 'packets-in', 'packets-out',
'packets-drop-blackhole', 'packets-drop-noroute').

=back

=cut
