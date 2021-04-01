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

package apps::java::zookeeper::jmx::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'zk', type => 1, cb_prefix_output => 'prefix_zk_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{zk} = [
        { label => 'avg-request-latency', set => {
                key_values => [ { name => 'AvgRequestLatency' } ],
                output_template => 'Avg Request Latency : %s ms',
                perfdatas => [
                    { label => 'avg_request_latency', value => 'AvgRequestLatency', template => '%s', 
                      min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'max-request-latency', set => {
                key_values => [ { name => 'MaxRequestLatency' } ],
                output_template => 'Max Request Latency : %s ms',
                perfdatas => [
                    { label => 'max_request_latency', value => 'MaxRequestLatency', template => '%s', 
                      min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'outstanding-requests', set => {
                key_values => [ { name => 'OutstandingRequests' } ],
                output_template => 'Outstanding Requests : %s',
                perfdatas => [
                    { label => 'outstanding_requests', value => 'OutstandingRequests', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'packets-received', set => {
                key_values => [ { name => 'PacketsReceived', diff => 1 } ],
                output_template => 'Packets Received : %s',
                perfdatas => [
                    { label => 'packets_received', value => 'PacketsReceived', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'packets-sent', set => {
                key_values => [ { name => 'PacketsSent', diff => 1 } ],
                output_template => 'Packets Sent : %s',
                perfdatas => [
                    { label => 'packets_sent', value => 'PacketsSent', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'num-connections', set => {
                key_values => [ { name => 'NumAliveConnections' } ],
                output_template => 'Num Alive Connections : %s',
                perfdatas => [
                    { label => 'num_connections', value => 'NumAliveConnections', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub prefix_zk_output {
    my ($self, %options) = @_;
    
    return "Zookeeper '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{zk} = {};
    $self->{request} = [
         { mbean => 'org.apache.ZooKeeperService:name0=*,name1=*,name2=Leader',
          attributes => [ { name => 'AvgRequestLatency' }, { name => 'MaxRequestLatency' }, 
                          { name => 'OutstandingRequests' }, { name => 'PacketsReceived' },
                          { name => 'PacketsSent' }, { name => 'NumAliveConnections' } ] },
         { mbean => 'org.apache.ZooKeeperService:name0=*,name1=*,name2=Follower',
          attributes => [ { name => 'AvgRequestLatency' }, { name => 'MaxRequestLatency' }, 
                          { name => 'OutstandingRequests' }, { name => 'PacketsReceived' },
                          { name => 'PacketsSent' }, { name => 'NumAliveConnections' } ] },
    ];
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    foreach my $mbean (keys %{$result}) {
        next if ($mbean !~ /name2=(.*?)(?:,|$)/);
        my $type = $1;
        
        $self->{zk}->{$type} = { 
            display => $type, 
            %{$result->{$mbean}},
        };
    }
    
    if (scalar(keys %{$self->{zk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No zookeeper found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "zookeeper_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check hibernate statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^avg-request-latency$'

=item B<--warning-*>

Threshold warning.
Can be: 'avg-request-latency', 'max-request-latency', 'outstanding-requests',
'packets-received' 'packets-sent', 'num-connections'.

=item B<--critical-*>

Threshold critical.
Can be: 'avg-request-latency', 'max-request-latency', 'outstanding-requests',
'packets-received' 'packets-sent', 'num-connections'.

=back

=cut
