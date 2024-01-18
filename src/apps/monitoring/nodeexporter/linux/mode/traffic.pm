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

package apps::monitoring::nodeexporter::linux::mode::traffic;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;


sub interface_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking interfaces %s ",
        $options{instance_value}->{status}->{display}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface %s ",
        $options{instance_value}->{status}->{display}
    );
}

sub prefix_packet_output {
    my ($self, %options) = @_;

    return 'packets ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'interface', type => 3, message_multiple => 'All interfaces are OK. ', cb_prefix_output => 'prefix_interface_output', cb_long_output => 'interface_long_output',
          indent_long_output => '    ' , 
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{operState} ne "up"',
            set => {
                key_values => [
                    { name => 'operState' }, { name => 'display' }
                ],
                output_template => "status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
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
         "interface:s"      =>   { name => 'interface', default => '^(?!(lo$))' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
  
    $self->{cache_name} = 'linux_nodeexporter' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all'));
    

    my $traffic_metrics;
    $self->{interface} = {};

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /node_network_receive_packets_total|node_network_transmit_packets_total|node_network_receive_bytes_total|node_network_transmit_bytes_total|node_network_up/i );

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{interface}) && $data->{dimensions}->{device} !~ /$self->{option_results}->{interface}/i);
            $self->{interface}->{$data->{dimensions}->{device}}->{traffic}->{$metric} = $data->{value} if ($metric ne 'node_network_up');
            $self->{interface}->{$data->{dimensions}->{device}}->{traffic}->{display} = $data->{dimensions}->{device} if ($metric ne 'node_network_up');

            if ($metric eq 'node_network_up') {
                $self->{interface}->{$data->{dimensions}->{device}}->{status}->{operState} = ($data->{value} == 1) ? "up" : "down";
                $self->{interface}->{$data->{dimensions}->{device}}->{status}->{display} = $data->{dimensions}->{device};
            }
        }
    }

    if (scalar(keys %{$self->{interface}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

=item B<--interface> 

Specify which interface to monitor. Can be a regex.

Default: all interfaces are monitored except 'lo' interface.

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