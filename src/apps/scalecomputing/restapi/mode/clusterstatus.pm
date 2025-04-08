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

package apps::scalecomputing::restapi::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;

    my $output = sprintf(
        "Cluster %s last task (%s): %s",
        $self->{result_values}->{display},
        $self->{result_values}->{task_description},
        $self->{result_values}->{task_state}
    );

    if (defined($self->{result_values}->{task_message}) && length($self->{result_values}->{task_message})) {
        $output .= " - message: $self->{result_values}->{task_message}";
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'clusters',
            type             => 1,
            message_multiple => 'All clusters are ok',
            skipped_code     => { -10 => 1, -11 => 1 }
        }
    ];

    $self->{maps_counters}->{clusters} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{task_state} eq "ERROR"',
            unknown_default  => '%{task_state} eq "UNINITIALIZED"',
            set              =>
                {
                    key_values                     => [
                        { name => 'display' },
                        { name => 'task_progress_percent' },
                        { name => 'task_state' },
                        { name => 'task_description' },
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'uuid:s'   => { name => 'uuid' },
        'use-name' => { name => 'use_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->list_clusters();
    foreach my $cluster (@{$clusters}) {
        if (defined($self->{option_results}->{uuid}) && $self->{option_results}->{uuid} ne '' &&
            $cluster->{uuid} !~ /$self->{option_results}->{uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $cluster->{uuid} . "' . ", debug => 1);
            next;
        }

        push @{$self->{filtered_clusters}}, $cluster;
    }

    foreach my $cluster (@{$self->{filtered_clusters}}) {
        my $node_task = $cluster->{latestTaskTag};
        $self->{clusters}->{$cluster->{uuid}} = {
            display               => defined($self->{option_results}->{use_name}) ?
                $cluster->{clusterName} : $cluster->{uuid},
            uuid                  => $cluster->{uuid},
            cluster_name          => $cluster->{clusterName},
            task_progress_percent => defined($node_task) ? $node_task->{progressPercent} : "no task",
            task_state            => defined($node_task) ? $node_task->{state} : "UNINITIALIZED",
            task_description      => defined($node_task) ? $node_task->{formattedDescription} : "no task",
            task_message          => defined($node_task) ? $node_task->{formattedMessage} : "no task",
        };

    }
}

1;

__END__

=head1 MODE

Monitor the status of a cluster

=over 8

=item B<--uuid>

cluster to check. If not set, we check all clusters.

=item B<--use-name>

Use cluster name for perfdata and display.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{task_state} eq "UNINITIALIZED"').
You can use the following variables: %{task_state}, %{task_progress_percent}, %{task_description}, %{task_message}, %{cluster_name}
%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{task_state}, %{task_progress_percent}, %{task_description}, %{task_message}, %{cluster_name}
%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{task_state} eq "ERROR"').
You can use the following variables: %{task_state}, %{task_progress_percent}, %{task_description}, %{task_message}, %{cluster_name}
%{task_state} can be 'UNINITIALIZED', 'QUEUED', 'RUNNING', 'COMPLETE', 'ERROR'.

=back

=cut
