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

package cloud::docker::restapi::mode::servicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { 
            name => 'services', type => COUNTER_TYPE_MULTIPLE, message_multiple => 'All services running well', skipped_code => { -11 => 1 },
            group => [ 
                { name => 'service', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -11 => 1 }},
                { name => 'tasks', type => COUNTER_MULTIPLE_SUBINSTANCE, prefix_output => "service '%{service_name}' task '%{task_id}' ", message_multiple => 'All tasks running well', skipped_code => { -11 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tasks-total', nlabel => 'services.tasks.total.count', display_ok => 0,  set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total services tasks: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'tasks-problems-total', nlabel => 'services.tasks.problems.count', display_ok => 0, set => {
                key_values => [ { name => 'problems' } ],
                output_template => 'Total tasks problems: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{tasks} = [
        { 
            label => 'task-status', 
            type => COUNTER_KIND_TEXT, 
            critical_default => '%{desired_state} ne %{state} and %{state} !~ /complete|preparing|assigned/',
            set => {
                key_values => [ 
                    { name => 'service_name' }, { name => 'service_id' },
                    { name => 'node_name' }, { name => 'node_id' },
                    { name => 'desired_state' }, { name => 'state_message' },
                    { name => 'task_id' }, { name => 'container_id' },
                    { name => 'state' }
                ],
                output_template => "state: %{state} [node: %{node_name} (%{node_id})] [container: %{container_id}] [desired state: %{desired_state}] [message: %{state_message}]",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];

    $self->{maps_counters}->{service} = [
        { 
            label => 'service-status',
            type => COUNTER_KIND_TEXT, 
            critical_default => '%{running} != %{replicas}', 
            set => {
                key_values => [ 
                    { name => 'service_name' }, { name => 'service_id' }, 
                    { name => 'replicas' }, { name => 'total' }, 
                    { name => 'problems' }, { name => 'running' }, 
                    { name => 'shutdown' }, { name => 'failed' },
                ],
                output_template => "service '%{service_name}' (%{service_id})",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        { label => 'service-tasks-problems', nlabel => 'service.tasks.problems.count', set => {
                key_values => [ { name => 'problems' } , { name => 'service_name' } ],
                output_template => 'Problems: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 , instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-replicas', nlabel => 'service.replica.count', set => {
                key_values => [ { name => 'replicas' } , { name => 'service_name' } ],
                output_template => 'Desired replicas: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 , instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-count', nlabel => 'service.tasks.count', display_ok => 0, set => {
                key_values => [ { name => 'total' }, { name => 'service_name' } ],
                output_template => 'Total tasks: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-running', nlabel => 'service.tasks.running.count', set => {
                key_values => [ { name => 'running' } , { name => 'service_name' } ],
                output_template => 'Running: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 , instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-shutdown', nlabel => 'service.tasks.shutdown.count', set => {
                key_values => [ { name => 'shutdown' }, { name => 'service_name' } ],
                output_template => 'Shutdown: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-failed', nlabel => 'service.tasks.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'service_name' } ],
                output_template => 'Failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-restart-count', nlabel => 'service.tasks.restart.count', display_ok => 0, set => {
                key_values => [ { name => 'restart', no_value => -1 }, { name => 'service_name' } ],
                output_template => 'Restart count: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-restart-rate', nlabel => 'service.tasks.restart.rate', display_ok => 0, set => {
                key_values => [ { name => 'rate', no_value => -1 }, { name => 'service_name' } ],
                output_template => 'Restart rate: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
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
        'filter-service-name:s' => { name => 'filter_service_name' },
        'restart-window:s'      => { name => 'restart_window', default => 300 }     
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->api_list_services();

    $self->{global} = { total => 0, problems => 0 };
    $self->{services} = {};
    $self->{taks} = {};
    my $restart_policy_relations = { 'any' => 'complete|failed', 'on-failure' => 'failed', 'none' => 'N/A' };
    my $dt_now = DateTime->now->epoch;
    my $dt_state_timestamp;

    foreach my $service_id (keys %$results) {
        my $service_name = $results->{$service_id}->{service}->{service_name};
        if (defined($self->{option_results}->{filter_service_name}) && $self->{option_results}->{filter_service_name} ne '' &&
            $service_name !~ /$self->{option_results}->{filter_service_name}/) {
            $self->{output}->output_add(long_msg => "skipping service '" . $service_name . "': no matching filter type.", debug => 1);
            next;
        }

        $self->{services}->{ $service_id } = {
            service_name => $service_name,
            %{$results->{$service_id}}
        };
        my $restart_policy =  $self->{services}->{ $service_id }->{service}->{restart_policy};

        if ($restart_policy eq 'any' || $restart_policy eq 'on-failure' ) {
            $self->{services}->{ $service_id }->{service}->{restart} = 0;
            $self->{services}->{ $service_id }->{service}->{rate} = 0
        }

        foreach my $task_id (keys %{$results->{$service_id}->{tasks}}) {
            if ($results->{$service_id}->{tasks}->{$task_id}->{state} =~ /$restart_policy_relations->{$restart_policy}/ ) {
                $self->{services}->{ $service_id }->{service}->{restart}++;

                if ($results->{$service_id}->{tasks}->{$task_id}->{timestamp} ne '') {
                    $results->{$service_id}->{tasks}->{$task_id}->{timestamp} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.(?:\d)*Z$/; # 2026-06-22T16:00:30.00000Z"
                    $dt_state_timestamp = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
                    
                    if ($dt_state_timestamp->epoch > ($dt_now - $self->{option_results}->{restart_window})) {
                        $self->{services}->{ $service_id }->{ $service_name }->{rate}++;
                    }
                }
            }

            $self->{services}->{ $service_id }->{service}->{total}++;
            $self->{global}->{total}++;     

            next if ($results->{$service_id}->{tasks}->{$task_id}->{state} !~ /running|shutdown|failed/i);
            $self->{services}->{ $service_id }->{service}->{ $results->{$service_id}->{tasks}->{$task_id}->{state} }++;

            if ($results->{$service_id}->{tasks}->{$task_id}->{state} ne 'complete' && 
                $results->{$service_id}->{tasks}->{$task_id}->{state} ne $results->{$service_id}->{tasks}->{$task_id}->{desired_state}) {
                $self->{services}->{service}->{ $service_id }->{problems}++;
                $self->{global}->{problems}++;
            }
        }
        
    }
    if (scalar(keys %{$self->{services}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Service found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check service status.

=over 8

=item B<--filter-service-name>

Filter services by service name (can be a regexp).

=item B<--restart-window>

Time window, in seconds, used to calculate the task restart rate (default: 300).

=item B<--unknown-task-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{service_id}, %{service_name}, %{task_id}, %{node_name}, 
%{node_id}, %{desired_state}, %{state}, %{state_message}, %{container_id}.

=item B<--warning-task-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{service_id}, %{service_name}, %{task_id}, %{node_name}, 
%{node_id}, %{desired_state}, %{state}, %{state_message}, %{container_id}.

=item B<--critical-task-status>

Define the conditions to match for the status to be CRITICAL (default: '%{desired_state} ne %{state} and %{state} !~ /complete|preparing|assigned/').
You can use the following variables: %{service_id}, %{service_name}, %{task_id}, %{node_name}, 
%{node_id}, %{desired_state}, %{state}, %{state_message}, %{container_id}.

=item B<--unknown-service-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{service_id}, %{service_name}, %{total}, %{replicas}, %{problems}, 
%{running}, %{shutdown}, %{failed}.

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{service_id}, %{service_name}, %{total}, %{replicas}, %{problems}, 
%{running}, %{shutdown}, %{failed}.

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{total} != %{replicas}').
You can use the following variables: %{service_id}, %{service_name}, %{total}, %{replicas}, %{problems}, 
%{running}, %{shutdown}, %{failed}.

=item B<--warning-service-replicas>

Threshold.

=item B<--critical-service-replicas>

Threshold.

=item B<--critical-service-tasks-count>

Threshold.

=item B<--warning-service-tasks-failed>

Threshold.

=item B<--critical-service-tasks-failed>

Threshold.

=item B<--warning-service-tasks-problems>

Threshold.

=item B<--critical-service-tasks-problems>

Threshold.

=item B<--warning-service-tasks-restart-count>

Threshold.

=item B<--critical-service-tasks-restart-count>

Threshold.

=item B<--warning-service-tasks-restart-rate>

Threshold.

=item B<--critical-service-tasks-restart-rate>

Threshold.

=item B<--warning-service-tasks-running>

Threshold.

=item B<--critical-service-tasks-running>

Threshold.

=item B<--warning-service-tasks-shutdown>

Threshold.

=item B<--critical-service-tasks-shutdown>

Threshold.

=item B<--warning-tasks-problems-total>

Threshold.

=item B<--critical-tasks-problems-total>

Threshold.

=item B<--warning-tasks-total>

Threshold.

=item B<--critical-tasks-total>

Threshold.

=back

=cut
