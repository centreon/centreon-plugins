
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

package cloud::azure::network::vpngateway::mode::tunneltraffic;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'TunnelIngressBytes' => {
            'output' => 'Ingress bytes',
            'label'  => 'traffic-in',
            'nlabel' => 'azvpngateway.tunnel.ingress.bytes',
            'unit'   => 'B',
            'min'    => '0',
            'max'    => ''
        },
        'TunnelEgressBytes' => {
            'output' => 'Egress bytes',
            'label'  => 'traffic-out',
            'nlabel' => 'azvpngateway.tunnel.egress.bytes',
            'unit'   => 'B',
            'min'    => '0',
            'max'    => ''
        },
        'TunnelIngressPackets' => {
            'output' => 'Ingress packets',
            'label'  => 'packets-in',
            'nlabel' => 'azvpngateway.tunnel.packets.in.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'TunnelEgressPackets' => {
            'output' => 'Egress packets',
            'label'  => 'packets-out',
            'nlabel' => 'azvpngateway.tunnel.packets.out.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'TunnelIngressPacketDropTSMismatch' => {
            'output' => 'Ingress packets dropped (TSmismatch)',
            'label'  => 'dropped-packets-in',
            'nlabel' => 'azvpngateway.tunnel.dropped.packets.in.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'TunnelEgressPacketDropTSMismatch' => {
            'output' => 'Egress packets dropped (TSmismatch)',
            'label'  => 'dropped-packets-out',
            'nlabel' => 'azvpngateway.tunnel.dropped.packets.out.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "resource:s"       => { name => 'resource' },
        "resource-group:s" => { name => 'resource_group' },
        "filter-metric:s"  => { name => 'filter_metric' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Network\/virtualNetworkGateways\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }
    
    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'virtualNetworkGateways';
    $self->{az_resource_namespace} = 'Microsoft.Network';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";
    $self->{az_aggregations} = ['Total'];

    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check VPN gateway tunnels traffic metrics.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::network::vpngateway::plugin --custommode=azcli --mode=tunnel-traffic
--resource=MyResource --resource-group=MYRGROUP --aggregation='total' --critical-traffic-in='10'
--verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::network::vpngateway::plugin --custommode=azcli --mode=tunnel-traffic
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworkGateways/xxx'
--aggregation='total' --critical-traffic-in='10' --verbose

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--filter-metric>

Filter metrics (can be: 'TunnelIngressBytes', 'TunnelEgressBytes', 'TunnelIngressPackets',
'TunnelEgressPackets', 'TunnelIngressPacketDropTSMismatch', 'TunnelEgressPacketDropTSMismatch')
(can be a regexp).

=item B<--warning-traffic-in>

Thresholds.

=item B<--critical-traffic-in>

Thresholds.

=item B<--warning-traffic-out>

Thresholds.

=item B<--critical-traffic-out>

Thresholds.

=item B<--warning-packets-in>

Thresholds.

=item B<--critical-packets-in>

Thresholds.

=item B<--warning-packets-out>

Thresholds.

=item B<--critical-packets-out>

Thresholds.

=item B<--warning-dropped-packets-in>

Thresholds.

=item B<--critical-dropped-packets-in>

Thresholds.

=item B<--warning-dropped-packets-out>

Thresholds.

=item B<--critical-dropped-packets-out>

Thresholds.



=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
