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

package cloud::google::gcp::compute::computeengine::mode::network;

use base qw(cloud::google::gcp::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'instance/network/received_bytes_count' => {
            output_string => 'received: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.network.received.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.network.received.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'received-volume',
            order => 1
        },
        'instance/network/sent_bytes_count' => {
            output_string => 'sent: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.network.sent.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.network.sent.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'sent-volume',
            order => 2
        },
        'instance/network/received_packets_count' => {
            output_string => 'received packets: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.network.received.packets.count',
                    format => '%.2f',
                    unit => 'packets'
                },
                per_second => {
                    nlabel => 'computeengine.network.received.packets.persecond',
                    format => '%.2f',
                    unit => 'packets/s'
                }
            },
            threshold => 'received-packets',
            order => 3
        },
        'instance/network/sent_packets_count' => {
            output_string => 'sent packets: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.network.sent.packets.count',
                    format => '%.2f',
                    unit => 'packets'
                },
                per_second => {
                    nlabel => 'computeengine.network.sent.packets.persecond',
                    format => '%.2f',
                    unit => 'packets/s'
                }
            },
            threshold => 'sent-packets',
            order => 4
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'dimension-name:s'     => { name => 'dimension_name', default => 'metric.labels.instance_name' },
        'dimension-operator:s' => { name => 'dimension_operator', default => 'equals' },
        'dimension-value:s'    => { name => 'dimension_value' },
        'filter-metric:s'      => { name => 'filter_metric' },
        "per-second"           => { name => 'per_second' },
        'timeframe:s'          => { name => 'timeframe' },
        'aggregation:s@'       => { name => 'aggregation' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{gcp_api} = 'compute.googleapis.com';
    $self->{gcp_dimension_name} = (!defined($self->{option_results}->{dimension_name}) || $self->{option_results}->{dimension_name} eq '') ? 'metric.labels.instance_name' : $self->{option_results}->{dimension_name};
    $self->{gcp_dimension_zeroed} = 'metric.labels.instance_name';
    $self->{gcp_instance_key} = 'metric.labels.instance_name';
    $self->{gcp_dimension_operator} = $self->{option_results}->{dimension_operator};
    $self->{gcp_dimension_value} = $self->{option_results}->{dimension_value};
}

1;

__END__

=head1 MODE

Check Compute Engine instances network metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::compute::computeengine::plugin
--mode=network --dimension-value=mycomputeinstance --filter-metric='bytes'
--aggregation='average' --critical-received-volume='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--dimension-name>

Set dimension name (Default: 'metric.labels.instance_name').

=item B<--dimension-operator>

Set dimension operator (Default: 'equals'. Can also be: 'regexp', 'starts').

=item B<--dimension-value>

Set dimension value (Required).

=item B<--filter-metric>

Filter metrics (Can be: 'instance/network/received_bytes_count',
'instance/network/sent_bytes_count', 'instance/network/received_packets_count',
'instance/network/sent_packets_count') (Can be a regexp).

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--warning-*> B<--critical-*>

Thresholds (Can be: 'received-volume', 'sent-volume',
'received-packets', 'sent-packets').

=item B<--per-second>

Change the data to be unit/sec.

=back

=cut
