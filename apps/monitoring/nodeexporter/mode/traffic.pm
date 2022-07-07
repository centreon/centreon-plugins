#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::nodeexporter::mode::traffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'traffic', type => 1, message_multiple => 'All interfaces are OK. ', display_long => 1 }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'packets-in', nlabel => 'node.packets.in.count', display_ok => 0, set => {
                key_values => [ { name => 'node_network_receive_packets_total', diff => 1 }, { name => 'display' } ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'packets-out', nlabel => 'node.packets.out.count', display_ok => 0, set => {
                key_values => [
                    { name => 'node_network_transmit_packets_total', diff => 1 }, { name => 'display' }
                ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'node.traffic.in.bitspersecond', set => {
                key_values => [
                    { name => 'node_network_receive_bytes_total', per_second => 1 }, { name => 'display' }
                ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'node.traffic.out.bitspersecond', set => {
                key_values => [
                    { name => 'node_network_transmit_bytes_total', per_second => 1 }, { name => 'display' }
                ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
         "filter:s"      => { name => 'filter' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
  
    $self->{cache_name} = 'linux_nodeexporter' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_channel}) ? md5_hex($self->{option_results}->{filter_channel}) : md5_hex('all'));
    

    my $traffic_metrics;
    $self->{traffic} = {};

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /node_network_receive_packets_total|node_network_transmit_packets_total|node_network_receive_bytes_total|node_network_transmit_bytes_total/i );

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{filter}) && $data->{dimensions}->{device} =~ $self->{option_results}->{filter});
            $traffic_metrics->{$data->{dimensions}->{device}}->{$metric} = $data->{value};
            $traffic_metrics->{$data->{dimensions}->{device}}->{display} = $data->{dimensions}->{device};
        }

    }

    foreach my $interface (keys %$traffic_metrics) {
        $self->{traffic}->{$interface} = {
            %{$traffic_metrics->{$interface}}
        }
    }
}

1;

__END__

=head1 MODE

=item B<--filter> 

Filter to exclude interfaces. Is a regex.

=item B<--warning-*> 

Warning thresholds.

Can be: 'traffic-in', 'traffic-out', 
'packets-in', 'packets-out'.

=item B<--critical-*>

Critical thresholds.

Can be: 'traffic-in', 'traffic-out', 
'packets-in', 'packets-out'.

=back

=cut