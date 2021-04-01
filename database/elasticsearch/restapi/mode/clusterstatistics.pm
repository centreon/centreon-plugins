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

package database::elasticsearch::restapi::mode::clusterstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "Cluster '" . $self->{result_values}->{display} . "' Status '" . $self->{result_values}->{status} . "'";

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'nodes-total', nlabel => 'nodes.total.count', set => {
                key_values => [ { name => 'nodes_total' } ],
                output_template => 'Nodes: %d',
                perfdatas => [
                    { value => 'nodes_total', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'nodes-data', nlabel => 'nodes.data.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_data' }, { name => 'nodes_total' } ],
                output_template => 'Nodes Data: %d',
                perfdatas => [
                    { value => 'nodes_data', template => '%d',
                      min => 0, max => 'nodes_total' },
                ],
            }
        },
        { label => 'nodes-coordinating', nlabel => 'nodes.coordinating.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_coordinating' }, { name => 'nodes_total' } ],
                output_template => 'Nodes Coordinating: %d',
                perfdatas => [
                    { value => 'nodes_coordinating', template => '%d',
                      min => 0, max => 'nodes_total' },
                ],
            }
        },
        { label => 'nodes-master', nlabel => 'nodes.master.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_master' }, { name => 'nodes_total' } ],
                output_template => 'Nodes Master: %d',
                perfdatas => [
                    { value => 'nodes_master', template => '%d',
                      min => 0, max => 'nodes_total' },
                ],
            }
        },
        { label => 'nodes-ingest', nlabel => 'nodes.ingest.count', display_ok => 0, set => {
                key_values => [ { name => 'nodes_ingest' }, { name => 'nodes_total' } ],
                output_template => 'Nodes Ingest: %d',
                perfdatas => [
                    { value => 'nodes_ingest', template => '%d',
                      min => 0, max => 'nodes_total' },
                ],
            }
        },
        { label => 'indices-total', nlabel => 'indices.total.count', set => {
                key_values => [ { name => 'indices_count' } ],
                output_template => 'Indices: %d',
                perfdatas => [
                    { value => 'indices_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'shards-total', nlabel => 'shards.total.count', set => {
                key_values => [ { name => 'shards_total' } ],
                output_template => 'Shards: %d',
                perfdatas => [
                    { value => 'shards_total', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'shards-active-count', nlabel => 'shards.active.count', display_ok => 0, set => {
                key_values => [ { name => 'shards_active' } ],
                output_template => 'Shards Active: %d',
                perfdatas => [
                    { value => 'shards_active', template => '%d',
                      min => 0, max => 'shards_total' },
                ],
            }
        },
        { label => 'shards-active-percentage', nlabel => 'shards.active.percentage', display_ok => 0, set => {
                key_values => [ { name => 'active_shards_percent' } ],
                output_template => 'Shards Active: %.2f%%',
                perfdatas => [
                    { value => 'active_shards_percent', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],                
            }
        },
        { label => 'shards-unassigned', nlabel => 'shards.unassigned.count', set => {
                key_values => [ { name => 'shards_unassigned' }, { name => 'shards_total' } ],
                output_template => 'Shards Unassigned: %d',
                perfdatas => [
                    { value => 'shards_unassigned', template => '%d',
                      min => 0, max => 'shards_total' },
                ],
            }
        },
        { label => 'shards-relocating', nlabel => 'shards.relocating.count', display_ok => 0, set => {
                key_values => [ { name => 'shards_relocating' }, { name => 'shards_total' } ],
                output_template => 'Shards Relocating: %d',
                perfdatas => [
                    { value => 'shards_relocating', template => '%d',
                      min => 0, max => 'shards_total' },
                ],
            }
        },
        { label => 'shards-initializing', nlabel => 'shards.initializing.count', display_ok => 0, set => {
                key_values => [ { name => 'shards_initializing' }, { name => 'shards_total' } ],
                output_template => 'Shards Initializing: %d',
                perfdatas => [
                    { value => 'shards_initializing', template => '%d',
                      min => 0, max => 'shards_total' },
                ],
            }
        },
        { label => 'tasks-pending', nlabel => 'tasks.pending.count', set => {
                key_values => [ { name => 'tasks_pending' } ],
                output_template => 'Tasks Pending: %d',
                perfdatas => [
                    { value => 'tasks_pending', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'documents-total', nlabel => 'documents.total.count', set => {
                key_values => [ { name => 'docs_count' } ],
                output_template => 'Documents: %d',
                perfdatas => [
                    { value => 'docs_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'data-size', nlabel => 'data.size.bytes', set => {
                key_values => [ { name => 'size_in_bytes' } ],
                output_template => 'Data: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'size_in_bytes', template => '%s',
                      min => 0, unit => 'B' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"    => { name => 'warning_status', default => '%{status} =~ /yellow/i' },
        "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /red/i' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $cluster_health = $options{custom}->get(path => '/_cluster/health');
    my $cluster_stats = $options{custom}->get(path => '/_cluster/stats');

    $self->{global} = { 
        display => $cluster_stats->{cluster_name},
        status => $cluster_stats->{status},
        nodes_total => $cluster_stats->{nodes}->{count}->{total},
        nodes_data => $cluster_stats->{nodes}->{count}->{data},
        nodes_coordinating => $cluster_stats->{nodes}->{count}->{coordinating_only},
        nodes_master => $cluster_stats->{nodes}->{count}->{master},
        nodes_ingest => $cluster_stats->{nodes}->{count}->{ingest},
        indices_count => $cluster_stats->{indices}->{count},
        shards_total => $cluster_stats->{indices}->{shards}->{total},
        shards_active => $cluster_health->{active_shards},
        shards_unassigned => $cluster_health->{unassigned_shards},
        shards_relocating => $cluster_health->{relocating_shards},
        shards_initializing => $cluster_health->{initializing_shards},
        active_shards_percent => $cluster_health->{active_shards_percent_as_number},
        tasks_pending => $cluster_health->{number_of_pending_tasks},
        docs_count => $cluster_stats->{indices}->{docs}->{count},
        size_in_bytes => $cluster_stats->{indices}->{store}->{size_in_bytes},
    };
}

1;

__END__

=head1 MODE

Check cluster statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'nodes-total', 'nodes-data', 'nodes-coordinating',
'nodes-master', 'nodes-ingest', 'indices-total', 'shards-total', 
'shards-active-count', 'shards-active-percentage', 
'shards-unassigned', 'shards-relocating', 'shards-initializing', 
'tasks-pending', 'documents-total', 'data-size'.

=item B<--critical-*>

Threshold critical.
Can be: 'nodes-total', 'nodes-data', 'nodes-coordinating',
'nodes-master', 'nodes-ingest', 'indices-total', 'shards-total', 
'shards-active-count', 'shards-active-percentage', 
'shards-unassigned', 'shards-relocating', 'shards-initializing', 
'tasks-pending', 'documents-total', 'data-size'.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /yellow/i')
Can used special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /red/i').
Can used special variables like: %{status}.

=back

=cut
