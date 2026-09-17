#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package database::mysql::mode::galeracluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_node_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "node status: %s [ready: %s]",
        $self->{result_values}->{nodeStatus},
        $self->{result_values}->{nodeReady}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'node-status',
            type => COUNTER_KIND_TEXT,
            warning_default  => '%{nodeStatus} =~ /joining|joined/i',
            critical_default => '%{nodeStatus} =~ /initialized/',
            set => {
                key_values => [ { name => 'nodeStatus' }, { name => 'nodeReady' } ],
                closure_custom_output => $self->can('custom_node_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {   label => 'node-recv-queue', display_ok => 0, nlabel => 'node.receive.queue.average.count',
            set => {
                key_values => [ { name => 'nodeRecvQueueAvg' } ],
                output_template => 'node receive queue average: %.5f',
                perfdatas => [
                    { template => '%.5f', min => 0 }
                ]
            }
        },
        {   label => 'node-send-queue', display_ok => 0, nlabel => 'node.send.queue.average.count',
            set => {
                key_values => [ { name => 'nodeSendQueueAvg' } ],
                output_template => 'node send queue average: %.5f',
                perfdatas => [
                    { template => '%.5f', min => 0 }
                ]
            }
        },
        {
            label => 'cluster-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{clusterStatus} !~ /^primary$/',
            set => {
                key_values => [ { name => 'clusterStatus' } ],
                output_template => 'cluster status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {   label => 'cluster-size', nlabel => 'cluster.size.count',
            set => {
                key_values => [ { name => 'clusterSize' } ],
                output_template => 'cluster size: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cluster_info = {};

    $options{sql}->connect();
    my $query = q{
        SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_status
        WHERE variable_name IN (
            'WSREP_CLUSTER_STATUS', 'WSREP_LOCAL_STATE_COMMENT', 'WSREP_CLUSTER_SIZE', 'WSREP_READY', 'WSREP_LOCAL_RECV_QUEUE_AVG', 'WSREP_LOCAL_SEND_QUEUE_AVG'
        )
    };
    $options{sql}->query(query => $query);
    while ((my @row = $options{sql}->fetchrow_array())) {
        $cluster_info->{ $row[0] } = $row[1];
    }

    $self->{global} = {
        nodeStatus       => defined($cluster_info->{WSREP_LOCAL_STATE_COMMENT}) ? lc($cluster_info->{WSREP_LOCAL_STATE_COMMENT}) : '-',
        nodeReady        => lc($cluster_info->{WSREP_READY}),
        clusterSize      => $cluster_info->{WSREP_CLUSTER_SIZE},
        clusterStatus    => lc($cluster_info->{WSREP_CLUSTER_STATUS}),
        nodeRecvQueueAvg => $cluster_info->{WSREP_LOCAL_RECV_QUEUE_AVG},
        nodeSendQueueAvg => $cluster_info->{WSREP_LOCAL_SEND_QUEUE_AVG}
    };
}

1;

__END__

=head1 MODE

Check Galera Cluster.

=over 8

=item B<--unknown-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{nodeStatus}, %{nodeReady}

=item B<--warning-node-status>

Define the conditions to match for the status to be WARNING (default: '%{nodeStatus} =~ /joining|joined/i').
You can use the following variables: %{nodeStatus}, %{nodeReady}

=item B<--critical-node-status>

Define the conditions to match for the status to be CRITICAL (default: '%{nodeStatus} =~ /initialized/').
You can use the following variables: %{nodeStatus}, %{nodeReady}

=item B<--unknown-cluster-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{clusterStatus}

=item B<--warning-cluster-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{clusterStatus}

=item B<--critical-cluster-status>

Define the conditions to match for the status to be CRITICAL (default: '%{clusterStatus} !~ /^primary$/').
You can use the following variables: %{clusterStatus}

=item B<--warning-cluster-size>

Threshold.

=item B<--critical-cluster-size>

Threshold.

=item B<--warning-node-recv-queue>

Threshold.

=item B<--critical-node-recv-queue>

Threshold.

=item B<--warning-node-send-queue>

Threshold.

=item B<--critical-node-send-queue>

Threshold.

=back

=cut
