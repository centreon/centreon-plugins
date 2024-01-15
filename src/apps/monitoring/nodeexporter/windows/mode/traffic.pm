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

package apps::monitoring::nodeexporter::windows::mode::traffic;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface %s ",
        $options{instance_value}->{display}
    );
}

sub custom_usage_bandwidth_calc {
    my ($self, %options) = @_;

    my $delta_time = $options{new_datas}->{bandwidth_windows_net_bytes_total} - $options{old_datas}->{bandwidth_windows_net_bytes_total};
    
    my $bandwidth_usage = 0;
    if ($options{old_datas}->{bandwidth_windows_net_current_bandwidth_bytes} > 0){
        my $bandwidth_usage = ($delta_time / $options{old_datas}->{bandwidth_windows_net_current_bandwidth_bytes}) * 100;
    }
    $self->{result_values}->{bandwitdh_avg} = $bandwidth_usage;

    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bandwidth', type => 0  },
        { name => 'traffic', type => 1, message_multiple => 'All interfaces are OK. ', cb_prefix_output => 'prefix_interface_output'}
    ];

    $self->{maps_counters}->{bandwidth} = [
        { label => 'bandwidth-usage', nlabel => 'node.bandwidth.usage', display_ok => 0, set => {
                key_values => [ { name => 'windows_net_current_bandwidth_bytes', diff => 1  }, { name => 'windows_net_bytes_total' } ],
                closure_custom_calc => $self->can('custom_usage_bandwidth_calc'),
                output_template => '%.2f %%',
                output_template => 'Average bandwidth usage : %.2f %%', output_use => 'bandwitdh_avg', threshold_use => 'bandwitdh_avg',
                perfdatas => [
                    { template => '%.2f', value => 'bandwitdh_avg', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'packets-in', nlabel => 'node.packets.in.count', display_ok => 0, set => {
                key_values => [ { name => 'windows_net_packets_received_total', diff => 1 }, { name => 'display' } ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'packets-out', nlabel => 'node.packets.out.count', display_ok => 0, set => {
                key_values => [ { name => 'windows_net_packets_sent_total', diff => 1 }, { name => 'display' } ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'packets-error-in', nlabel => 'node.packets.in.error.count', display_ok => 0, set => {
                key_values => [ { name => 'windows_net_packets_received_errors_total', diff => 1 }, { name => 'display' } ],
                output_template => 'packets error in: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'packets-error-out', nlabel => 'node.packets.out.error.count', display_ok => 0, set => {
                key_values => [ { name => 'windows_net_packets_outbound_errors_total', diff => 1 }, { name => 'display' } ],
                output_template => 'packets error out: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'node.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'windows_net_bytes_received_total', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'node.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'windows_net_bytes_sent_total', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %.2f %s/s',
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
         "interface:s"      =>   { name => 'interface' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");
  
    $self->{cache_name} = 'windows_nodeexporter' . $options{custom}->get_uuid()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{interface}) ? md5_hex($self->{option_results}->{interface}) : md5_hex('all'));
    

    my $traffic_metrics;
    $self->{interface} = {};

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /windows_net_packets_received_total|windows_net_packets_sent_total|windows_net_bytes_received_total|windows_net_bytes_sent_total|windows_net_packets_received_errors_total|windows_net_packets_outbound_errors_total|windows_net_bytes_total|windows_net_current_bandwidth_bytes/i );

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{interface}) && $data->{dimensions}->{nic} !~ /$self->{option_results}->{interface}/i);

            $self->{traffic}->{$data->{dimensions}->{nic}}->{$metric} = $data->{value} ;
            $self->{traffic}->{$data->{dimensions}->{nic}}->{display} = $data->{dimensions}->{nic} ;

            if ($metric =~ /windows_net_bytes_total|windows_net_current_bandwidth_bytes/){
                $self->{bandwidth}->{$metric} = $data->{value};
            }
        }
    }

    if (scalar(keys %{$self->{traffic}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No interface found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

=item B<--interface> 

Specify which interface to monitor. Can be a regex.

Default: all interfaces are monitored.

=item B<--warning-*> 

Warning thresholds.

Can be: 'traffic-in', 'traffic-out', 
'packets-in', 'packets-out',
'bandwidth-usage'

=item B<--critical-*>

Critical thresholds.

Can be: 'traffic-in', 'traffic-out', 
'packets-in', 'packets-out',
'bandwidth-usage'

=back

=cut