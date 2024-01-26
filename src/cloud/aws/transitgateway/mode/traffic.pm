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

package cloud::aws::transitgateway::mode::traffic;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All TransitGateways metrics are ok'
        },
        metrics => {
            BytesIn => {
                output => 'Bytes In',
                label  => 'bytes-in',
                nlabel => {
                    absolute   => 'gateway.traffic.in.bytes',
                    per_second => 'gateway.traffic.in.bytespersecond'
                },
                unit   => 'B'
            },
            BytesOut => {
                output => 'Bytes Out',
                label  => 'bytes-out',
                nlabel => {
                    absolute   => 'gateway.traffic.out.bytes',
                    per_second => 'gateway.traffic.out.bytespersecond'
                },
                unit   => 'B'
            },
            PacketsIn => {
                output => 'Packets Received (In)',
                label  => 'packets-in',
                nlabel => {
                    absolute   => 'gateway.packets.in.count',
                    per_second => 'gateway.packets.in.countpersecond'
                },
                unit   => ''
            },
            PacketsOut => {
                output => 'Packets Sent (Out)',
                label  => 'packets-out',
                nlabel => {
                    absolute   => 'gateway.packets.out.count',
                    per_second => 'gateway.packets.out.countpersecond'
                },
                unit   => ''
            },
            PacketDropCountBlackhole => {
                output => 'Packets Drop Blackhole',
                label  => 'packets-drop-blackhole',
                nlabel => {
                    absolute   => 'gateway.packets.blackholedropped.count',
                    per_second => 'gateway.packets.blackholedropped.countpersecond'
                },
                unit   => ''
            },
            PacketDropCountNoRoute => {
                output => 'Packets Drop No Route',
                label  => 'packets-drop-noroute',
                nlabel => {
                    absolute   => 'gateway.packets.noroutedropped.count',
                    per_second => 'gateway.packets.noroutedropped.countpersecond'
                },
                unit   => ''
            }
        }
    };

    return $metrics_mapping;
}

sub long_output {
    my ($self, %options) = @_;

    return "AWS TransitGateway '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-gateway:s' => { name => 'filter_gateway' }
    });

    return $self;
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
