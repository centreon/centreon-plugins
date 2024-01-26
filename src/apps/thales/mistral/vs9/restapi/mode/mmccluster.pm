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

package apps::thales::mistral::vs9::restapi::mode::mmccluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_cluster_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'enabled: %s, replication status: %s',
         $self->{result_values}->{enabled},
         $self->{result_values}->{replicationStatus}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return 'cluster ';
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 0, cb_prefix_output => 'prefix_cluster_output' },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'all nodes are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{cluster} = [
        {
            label => 'cluster-status',
            type => 2,
            unknown_default => '%{replicationStatus} =~ /unknown/i',
            warning_default => '%{replicationStatus} =~ /not_synchronized/i',
            set => {
                key_values => [ { name => 'replicationStatus' }, { name => 'enabled' } ],
                closure_custom_output => $self->can('custom_cluster_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'synchronization-done', display_ok => 0, nlabel => 'cluster.synchronization.done.percentage', set => {
                key_values => [ { name => 'synchronizationDone' } ],
                output_template => 'synchronization done: %s %%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        {
            label => 'node-status',
            type => 2,
            warning_default => '%{status} =~ /disconnected/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cluster = $options{custom}->request_api(endpoint => '/managementCenters/cluster');

    $self->{cluster} = {
        enabled => $cluster->{enabled} =~ /true|1/i ? 'yes' : 'no',
        replicationStatus => lc($cluster->{replicationStatus}),
        synchronizationDone => $cluster->{synchronizePercentageDone}
    };

    $self->{nodes} = {};
    foreach (keys %{$cluster->{statusList}}) {
        $self->{nodes}->{$_} = {
            name => $_,
            status => $cluster->{statusList}->{$_} =~ /true|1/i ? 'connected' : 'disconnected'
        };
    }
}

1;

__END__

=head1 MODE

Check MMC cluster status.

=over 8

=item B<--unknown-cluster-status>

Define the conditions to match for the status to be UNKNOWN  (default: '%{replicationStatus} =~ /unknown/i').
You can use the following variables: %{enabled}, %{replicationStatus}

=item B<--warning-cluster-status>

Define the conditions to match for the status to be WARNING (default: '%{replicationStatus} =~ /not_synchronized/i').
You can use the following variables: %{enabled}, %{replicationStatus}

=item B<--critical-cluster-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}

=item B<--unknown-node-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-node-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /disconnected/i').
You can use the following variables: %{status}, %{name}

=item B<--critical-node-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'synchronization-done'.

=back

=cut
