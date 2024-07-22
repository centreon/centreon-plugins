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

package storage::hp::primera::restapi::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc catalog_status_threshold_ng);

sub custom_node_output {
    my ($self, %options) = @_;

    return sprintf(
            "node %s is %s",
            $self->{result_values}->{id},
            $self->{result_values}->{status}
        );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'nodes', type => 1, message_multiple => 'All nodes are online.' },
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'total',
            nlabel => 'nodes.total.count',
            set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total number of nodes: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        {
            label => 'online',
            nlabel => 'nodes.online.count',
            set => {
                key_values => [ { name => 'online' }, { name => 'total' } ],
                output_template => 'Number of online nodes: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
    ];

    $self->{maps_counters}->{nodes} = [
        {
            label => 'node-status',
            type => 2,
            warning_default => '%{status} !~ /^online$/',
            set => {
                key_values => [ { name => 'status' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_node_output'),
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
        'filter-node:s' => { name => 'filter_node' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}


sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        endpoint => '/api/v1/system'
    );
    my $total_nodes = 0;
    my $online_nodes = 0;

    # Typical content of onlineNodes is [0, 1]
    # %online_nodes_statuses associates 'online' to every online node is as key
    # Example {[0] => 'online'}
    my %online_nodes_statuses = map { $_ => 'online' } @{ $response->{onlineNodes} };
    # Typical content of clusterNodes is [0, 1]
    # %all_nodes_statuses uses this data and the data from %online_nodes_statuses to give the status of all nodes
    # Example: {[0] => 'online', [1] => 'offline'}
    my %all_nodes_statuses = map {$_ => defined($online_nodes_statuses{$_}) ? $online_nodes_statuses{$_} : 'offline'} @{ $response->{clusterNodes} };

    for my $node (keys(%all_nodes_statuses)) {
        next if (defined($self->{option_results}->{filter_node})
                 and $self->{option_results}->{filter_node} ne ''
                 and $node !~ /$self->{option_results}->{filter_node}/);

        $total_nodes = $total_nodes + 1;
        $online_nodes = $online_nodes + 1 if ($all_nodes_statuses{$node} eq 'online');

        $self->{nodes}->{$node} = {
                id     => $node,
                status => $all_nodes_statuses{$node}
        }
    }
    $self->{global} = {
        total  => $total_nodes,
        online => $online_nodes
    }
}

1;

__END__

=head1 MODE

Check if the configured nodes of the HPE Primera cluster are all online.

=over 8

=item B<--filter-node>

Define which nodes (filtered by regular expression) should be monitored.
Example: --filter-node='^(0|1)$'

=item B<--warning-node-status>

Define the conditions to match for the status to be WARNING. (default: '%{status} ne "online"').
You can use the %{status} variables.

=item B<--critical-node-status>

Define the conditions to match for the status to be CRITICAL
You can use the %{status} variables.

=back

=cut
