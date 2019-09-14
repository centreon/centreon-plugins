#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::google::gcp::compute::computeengine::mode::network;

use base qw(cloud::google::gcp::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'instance/network/received_bytes_count' => {
            'output_string' => 'Received Bytes: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.network.received.volume.bytes',
                    'format' => '%.2f',
                    'unit' => 'B',
                    'change_bytes' => 1,
                },
                'per_second' => {
                    'nlabel' => 'computeengine.network.received.volume.bytespersecond',
                    'format' => '%.2f',
                    'unit' => 'B/s',
                    'change_bytes' => 1,
                },
            },
            'threshold' => 'received-volume',
        },
        'instance/network/sent_bytes_count' => {
            'output_string' => 'Sent Bytes: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.network.sent.volume.bytes',
                    'format' => '%.2f',
                    'unit' => 'B',
                    'change_bytes' => 1,
                },
                'per_second' => {
                    'nlabel' => 'computeengine.network.sent.volume.bytespersecond',
                    'format' => '%.2f',
                    'unit' => 'B/s',
                    'change_bytes' => 1,
                },
            },
            'threshold' => 'sent-volume',
        },
        'instance/network/received_packets_count' => {
            'output_string' => 'Received Packets: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.network.received.packets.count',
                    'format' => '%.2f',
                    'unit' => 'packets',
                },
                'per_second' => {
                    'nlabel' => 'computeengine.network.received.packets.persecond',
                    'format' => '%.2f',
                    'unit' => 'packets/s',
                },
            },
            'threshold' => 'received-packets',
        },
        'instance/network/sent_packets_count' => {
            'output_string' => 'Sent Packets: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.network.sent.packets.count',
                    'format' => '%.2f',
                    'unit' => 'packets',
                },
                'per_second' => {
                    'nlabel' => 'computeengine.network.sent.packets.persecond',
                    'format' => '%.2f',
                    'unit' => 'packets/s',
                },
            },
            'threshold' => 'sent-packets',
        },
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'instance:s@'       => { name => 'instance' },
        'filter-metric:s'   => { name => 'filter_metric' },
        "per-second"        => { name => 'per_second' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{instance})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --instance <name>.");
        $self->{output}->option_exit();
    }
    
    $self->{gcp_api} = "compute.googleapis.com";
    $self->{gcp_dimension} = 'metric.labels.instance_name';
    $self->{gcp_instance} = $self->{option_results}->{instance};
    $self->{gcp_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{gcp_aggregations} = ['average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{gcp_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{gcp_aggregations}}, $stat;
            }
        }
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{gcp_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Compute Engine instances network metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::compute::computeengine::plugin
--custommode=api --mode=network --instance=mycomputeinstance --filter-metric='bytes'
--aggregation='average' --critical-received-volume='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--instance>

Set instance name (Required).

=item B<--filter-metric>

Filter metrics (Can be: 'instance/network/received_bytes_count',
'instance/network/sent_bytes_count', 'instance/network/received_packets_count',
'instance/network/sent_packets_count') (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds warning (Can be: 'received-volume', 'sent-volume',
'received-packets', 'sent-packets').

=item B<--per-second>

Change the data to be unit/sec.

=back

=cut
