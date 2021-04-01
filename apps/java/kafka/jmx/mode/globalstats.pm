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

package apps::java::kafka::jmx::mode::globalstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'leader-count', set => {
                key_values => [ { name => 'leader_count' } ],
                output_template => 'Leaders : %s',
                perfdatas => [
                    { label => 'leader_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active-controller-count', set => {
                key_values => [ { name => 'active_controller_count' } ],
                output_template => 'Active Controllers : %s',
                perfdatas => [
                    { label => 'active_controller_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'partition-count', set => {
                key_values => [ { name => 'partition_count' } ],
                output_template => 'Partitions : %s',
                perfdatas => [
                    { label => 'partition_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'offline-partitions-count', set => {
                key_values => [ { name => 'offline_partitions_count' } ],
                output_template => 'Offline partitions : %s',
                perfdatas => [
                    { label => 'offline_partitions_count', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'under-replicated-partitions', set => {
                key_values => [ { name => 'under_replicated_partitions' } ],
                output_template => 'Under replicated partitions : %s',
                perfdatas => [
                    { label => 'under_replicated_partitions', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'unclean-leader-elections', set => {
                key_values => [ { name => 'unclean_leader_elections', diff => 1 } ],
                output_template => 'Number of unclean leader elections : %s',
                perfdatas => [
                    { label => 'unclean_leader_elections', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'total-fetch-requests', set => {
                key_values => [ { name => 'total_fetch_requests', diff => 1 } ],
                output_template => 'Number of total fetch requests : %s',
                perfdatas => [
                    { label => 'total_fetch_requests', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{request} = [
         { mbean => 'kafka.server:name=UnderReplicatedPartitions,type=ReplicaManager', attributes => [ { name => 'Value' } ] },
         { mbean => 'kafka.server:name=PartitionCount,type=ReplicaManager', attributes => [ { name => 'Value' } ] },
         { mbean => 'kafka.server:name=LeaderCount,type=ReplicaManager', attributes => [ { name => 'Value' } ] },
         { mbean => 'kafka.controller:name=OfflinePartitionsCount,type=KafkaController', attributes => [ { name => 'Value' } ] },
         { mbean => 'kafka.controller:name=ActiveControllerCount,type=KafkaController', attributes => [ { name => 'Value' } ] },
         { mbean => 'kafka.controller:name=UncleanLeaderElectionsPerSec,type=ControllerStats', attributes => [ { name => 'Count' } ] },
         { mbean => 'kafka.server:name=BytesInPerSec,type=BrokerTopicMetrics', attributes => [ { name => 'Count' } ] },
         { mbean => 'kafka.server:name=BytesOutPerSec,type=BrokerTopicMetrics', attributes => [ { name => 'Count' } ] },
         { mbean => 'kafka.server:name=TotalFetchRequestsPerSec,type=BrokerTopicMetrics', attributes => [ { name => 'Count' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);    
    $self->{global} = {
        under_replicated_partitions => $result->{'kafka.server:name=UnderReplicatedPartitions,type=ReplicaManager'}->{Value},
        offline_partitions_count => $result->{'kafka.controller:name=OfflinePartitionsCount,type=KafkaController'}->{Value},
        partition_count => $result->{'kafka.server:name=PartitionCount,type=ReplicaManager'}->{Value},
        leader_count => $result->{'kafka.server:name=LeaderCount,type=ReplicaManager'}->{Value},
        active_controller_count => $result->{'kafka.controller:name=ActiveControllerCount,type=KafkaController'}->{Value},
        unclean_leader_elections => $result->{'kafka.controller:name=UncleanLeaderElectionsPerSec,type=ControllerStats'}->{Count},
        traffic_in => $result->{'kafka.server:name=BytesInPerSec,type=BrokerTopicMetrics'}->{Count} * 8,
        traffic_out => $result->{'kafka.server:name=BytesOutPerSec,type=BrokerTopicMetrics'}->{Count} * 8,
        total_fetch_requests => $result->{'kafka.server:name=TotalFetchRequestsPerSec,type=BrokerTopicMetrics'}->{Count},
    };
    
    $self->{cache_name} = "kafka_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check kafka global statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^traffic-in$'

=item B<--warning-*>

Threshold warning.
Can be: 'under-replicated-partitions', 'offline-partitions-count', 'partition-count', 'leader-count',
'active-controller-count', 'unclean-leader-elections', 'traffic-in', 'traffic-out', 'total-fetch-requests'.

=item B<--critical-*>

Threshold critical.
Can be: 'under-replicated-partitions', 'offline-partitions-count', 'partition-count', 'leader-count',
'active-controller-count', 'unclean-leader-elections', 'traffic-in', 'traffic-out', 'total-fetch-requests'.

=back

=cut
