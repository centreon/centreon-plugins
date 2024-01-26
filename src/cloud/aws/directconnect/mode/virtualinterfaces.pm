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

package cloud::aws::directconnect::mode::virtualinterfaces;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All virtual interfaces are ok'
        },
        metrics => {
            VirtualInterfaceBpsEgress => {
                output => 'outbound data',
                label => 'virtual-interface-egress',
                nlabel => {
                    absolute => 'virtual_interface.egress.bitspersecond',
                },
                unit => 'bps'
            },
            VirtualInterfaceBpsIngress => {
                output => 'inbound data',
                label => 'virtual-interface-ingress',
                nlabel => {
                    absolute => 'virtual_interface.ingress.bitspersecond',
                },
                unit => 'bps'
            },
            VirtualInterfacePpsEgress => {
                output => 'outbound packets data',
                label => 'virtual-interface-packets-egress',
                nlabel => {
                    absolute => 'virtual_interface.egress.packets.persecond',
                },
                unit => '/s'
            },
            VirtualInterfacePpsIngress => {
                output => 'inbound packet data',
                label => 'virtual-interface-packets-ingress',
                nlabel => {
                    absolute => 'virtual_interface.ingress.packets.persecond',
                },
                unit => '/s'
            }
        }
    };

    return $metrics_mapping;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf('state: %s [vlan: %s, type: %s]', $self->{result_values}->{state}, $self->{result_values}->{vlan}, $self->{result_values}->{type});
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "connection '" . $options{instance_value}->{connectionName} . "' virtual interface '" . $options{instance_value}->{virtualInterfaceName} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking connection '" . $options{instance_value}->{connectionName} . "' virtual interface '" . $options{instance_value}->{virtualInterfaceName} . "'";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "statistic '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->SUPER::set_counters(%options);

    unshift @{$self->{maps_counters_type}->[0]->{group}}, {
        name => 'status',
        type => 0, skipped_code => { -10 => 1 }
    };

    $self->{maps_counters}->{status} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'state' }, { name => 'vlan' }, { name => 'type' }, { name => 'connectionName' }, { name => 'virtualInterfaceName' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-connection-id:s'        => { name => 'filter_connection_id' },
        'filter-virtual-interface-id:s' => { name => 'filter_virtual_interface_id' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $connections = $options{custom}->directconnect_describe_connections();
    my $interfaces = $options{custom}->directconnect_describe_virtual_interfaces();

    foreach my $vid (keys %$interfaces) {
        next if (defined($self->{option_results}->{filter_virtual_interface_id}) && $self->{option_results}->{filter_virtual_interface_id} ne ''
            && $vid !~ /$self->{option_results}->{filter_virtual_interface_id}/);
        next if (defined($self->{option_results}->{filter_connection_id}) && $self->{option_results}->{filter_connection_id} ne ''
            && $interfaces->{$vid}->{connectionId} !~ /$self->{option_results}->{filter_connection_id}/);
        
        my $key = $connections->{ $interfaces->{$vid}->{connectionId} }->{name} . $self->{output}->get_instance_perfdata_separator() . $interfaces->{$vid}->{name};

        $self->{metrics}->{$key} = {
            connectionName => $connections->{ $interfaces->{$vid}->{connectionId} }->{name},
            virtualInterfaceName => $interfaces->{$vid}->{name},
            status => {
                connectionName => $connections->{ $interfaces->{$vid}->{connectionId} }->{name},
                virtualInterfaceName => $interfaces->{$vid}->{name},
                type => $interfaces->{$vid}->{type},
                vlan => $interfaces->{$vid}->{vlan},
                state => $interfaces->{$vid}->{state}
            },
            statistics => {}
        };

        my $cw_metrics = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/DX',
            dimensions => [ { Name => 'ConnectionId', Value => $interfaces->{$vid}->{connectionId} }, { Name => 'VirtualInterfaceId', Value => $vid } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($cw_metrics->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$key}->{display} = $interfaces->{$vid}->{name};
                $self->{metrics}->{$key}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$key}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$key}->{statistics}->{lc($statistic)}->{$metric} = 
                    defined($cw_metrics->{$metric}->{lc($statistic)}) ? 
                    $cw_metrics->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No virtual interface found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check direct connect virtual interfaces.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::directconnect::plugin --custommode=paws --mode=virtual-interfaces --region='eu-west-1'
--filter-metric='VirtualInterfaceBpsEgress' --statistic='average' --critical-virtual-interface-egress='10Mb' --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--filter-connection-id>

Filter connection ID (can be a regexp).

=item B<--filter-virtual-interface-id>

Filter virtual interface ID (can be a regexp).

=item B<--filter-metric>

Filter metrics (can be: 'VirtualInterfaceBpsEgress', 'VirtualInterfaceBpsIngress', 
'VirtualInterfacePpsEgress', 'VirtualInterfacePpsIngress') 
(can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vlan}, %{type}, %{virtualInterfaceId}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{vlan}, %{type}, %{virtualInterfaceId}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be 'virtual-interface-egress', 'virtual-interface-ingress', 
'virtual-interface-packets-egress', 'virtual-interface-packets-ingress'.

=back

=cut
