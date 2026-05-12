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

package apps::backup::rubrik::graphql::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;

sub custom_status_output {
    my ($self, %options) = @_;

    my $status = 'status: ' . $self->{result_values}->{status};
    if ($self->{output}->is_verbose()) {
        $status .= ", ip address: '" . $self->{result_values}->{ip_address} . "'";
        $status .= ", hostname: '" . $self->{result_values}->{hostname} . "'";
    }

    return $status;
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "Checking cluster '" . $options{instance_value}->{name} . "' ";
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{id} . "' ";
}

sub prefix_global_cluster_output {
    my ($self, %options) = @_;

    return 'node ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All nodes are ok',
            group => [
                { name => 'cluster', type => COUNTER_MULTIPLE_INSTANCE, cb_prefix_output => 'prefix_global_cluster_output' },
                { name => 'nodes', type => COUNTER_MULTIPLE_SUBINSTANCE, display_long => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'nodes are ok', skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-nodes-total', nlabel => 'cluster.nodes.total.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_total' } , { name => 'name' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name'  }
                ]
            }
        },
        { label => 'cluster-nodes-ok', nlabel => 'cluster.nodes.ok.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_ok' }, { name => 'nodes_total' }, { name => 'name' } ],
                output_template => 'ok: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'nodes_total', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'nodes-status', type => COUNTER_KIND_TEXT, critical_default => '%{status} !~ /ok/', set => {
                key_values => [ { name => 'status' }, { name => 'id' }, { name => 'hostname' }, { name => 'ip_address' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        %$timerange_filters,
        'filter-node-id:s'       => { redirect => 'include_node_id' },
        'include-node-id:s'      => { name => 'include_node_id', default => '' },
        'exclude-node-id:s'      => { name => 'exclude_node_id', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    timerange_check_options($self);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $filters = $options{custom}->common_filters();
    $filters->{registrationTime_gt} = $self->{option_results}->{start_time}
        if $self->{option_results}->{start_time} ne '';
    $filters->{registrationTime_lt} = $self->{option_results}->{end_time}
        if $self->{option_results}->{end_time} ne '';

    my $result = $options{custom}->get_cluster_nodes( filters => $filters );

    $self->{output}->option_exit(short_msg => "No matching Cluster !")
        unless ref $result eq 'ARRAY';

    $self->{clusters} = {};
    foreach my $cluster (@{$result}) {
        my $cluster_id = $cluster->{id} // '';
        my $cluster_name = $cluster->{name} // '';
        next if $options{custom}->is_common_excluded(id => $cluster_id, name => $cluster_name);

        next unless ref $cluster->{clusterNodeConnection} eq 'HASH' && $cluster->{clusterNodeConnection}->{nodes};

        my $cluster_item = {
            name => $cluster_name,
            id => $cluster_id,
            cluster => {
                name => $cluster_name,
                nodes_total => 0,
                nodes_ok => 0
            },
            nodes => {}
        };

        foreach my $node (@{$cluster->{clusterNodeConnection}->{nodes}}) {
            next if is_excluded($node->{id}, $self->{option_results}->{include_node_id}, $self->{option_results}->{exclude_node_id}, output => $self->{output});

            my $node_status = lc $node->{status};

            $cluster_item->{nodes}->{ $node->{id} } = {
                id => $node->{id},
                hostname => $node->{hostname},
                ip_address => $node->{ipAddress},
                status => $node_status
            };

            $cluster_item->{cluster}->{nodes_ok}++
                if $node_status eq 'ok';

            $cluster_item->{cluster}->{nodes_total}++;
        }
        $self->{clusters}->{$cluster_id} = $cluster_item;
    }

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless %{$self->{clusters}};

}

1;

__END__

=head1 MODE

Check nodes status via GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering nodes by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering nodes by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last registered nodes. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).

=item B<--include-node-id>

Include node ID (can be a regexp).

=item B<--exclude-node-id>

Exclude node ID (can be a regexp).

=item B<--unknown-nodes-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{id}, %{hostname}, %{ip_address}

=item B<--warning-nodes-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{id}, %{hostname}, %{ip_address}

=item B<--critical-nodes-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/').
You can use the following variables: %{status}, %{id}, %{hostname}, %{ip_address}

=item B<--warning-cluster-nodes-total>

Warning threshold for total number of nodes per cluster.

=item B<--critical-cluster-nodes-total>

Critical threshold for total number of nodes per cluster.

=item B<--warning-cluster-nodes-ok>

Warning threshold for number of healthy nodes per cluster.

=item B<--critical-cluster-nodes-ok>

Critical threshold for number of healthy nodes per cluster.

=back

=cut
