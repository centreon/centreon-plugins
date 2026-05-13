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

package cloud::docker::restapi::mode::servicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values :counter_kinds);

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "service '" . $options{instance_value}->{service_name} . "' ";
}

sub prefix_tasks_output {
    my ($self, %options) = @_;
    
    return  "task '" . $options{instance_value}->{task_id} . "' service '" . $options{instance_value}->{service_name} . "' ";
}

sub custom_tasks_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [node: %s (%s)] [container: %s] [desired state: %s] [message: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{node_name},
        $self->{result_values}->{node_id},
        $self->{result_values}->{container_id},
        $self->{result_values}->{desired_state},
        $self->{result_values}->{state_message}
    );
}

sub custom_service_output {
    my ($self, %options) = @_;

    return sprintf(
        '[node: %s (%s)] [container: %s]',
        $self->{result_values}->{node_name},
        $self->{result_values}->{node_id},
        $self->{result_values}->{container_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global',   type => COUNTER_TYPE_GLOBAL },
        { name => 'services', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services running well', skipped_code => { -11 => 1 } },
        { name => 'tasks',    type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_tasks_output',   message_multiple => 'All tasks running well',    skipped_code => { -11 => 1 } } 
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tasks-total', nlabel => 'services.tasks.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total tasks of services: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },

        { label => 'tasks-problems-total', nlabel => 'services.tasks.problems.count', set => {
                key_values => [ { name => 'problems' } ],
                output_template => 'total tasks problems of services: %s',
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
                    { name => 'service_name' }, { name => 'task_id' },
                    { name => 'node_name' }, { name => 'node_id' },
                    { name => 'desired_state' }, { name => 'state_message' },
                    { name => 'service_id' }, { name => 'container_id' },
                    { name => 'state' }
                ],
                closure_custom_output => $self->can('custom_tasks_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];

    $self->{maps_counters}->{services} = [
        { 
            label => 'service-status',
            type => COUNTER_KIND_TEXT, 
            critical_default => '%{total} != %{replicas} || %{problems} > 0', 
            set => {
                key_values => [ 
                    { name => 'service_name' }, { name => 'node_name' }, 
                    { name => 'node_id' }, { name => 'service_id' }, 
                    { name => 'container_id' }, { name => 'replicas'},
                    { name => 'total' }, { name => 'problems' }
                ],
                closure_custom_output => $self->can('custom_service_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },

        { label => 'service-replicas', nlabel => 'service.replicas.count', set => {
                key_values => [ { name => 'replicas' }, { name => 'service_name' } ],
                output_template => '[desired replicas: %s]',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks', nlabel => 'service.tasks.count', set => {
                key_values => [ { name => 'total' }, { name => 'service_name' } ],
                output_template => '[total tasks: %s]',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-problems', nlabel => 'service.tasks.problems.count', set => {
                key_values => [ { name => 'problems' }, { name => 'service_name' } ],
                output_template => '[problems: %s]',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-running', nlabel => 'service.tasks.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'service_name' } ],
                output_template => '[running: %s]',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-shutdown', nlabel => 'service.tasks.shutdown.count', set => {
                key_values => [ { name => 'shutdown' }, { name => 'service_name' } ],
                output_template => '[shutdown: %s]',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'service_name' }
                ]
            }
        },
        { label => 'service-tasks-failed', nlabel => 'service.tasks.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'service_name' } ],
                output_template => '[failed: %s]',
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->api_list_services();

    $self->{global} = { total => 0, problem => 0 };
    $self->{services} = {};
    $self->{taks} = {};
 
    foreach my $service_id (keys %$results) {
        my $service_name = $results->{$service_id}->{service_name};
        if (defined($self->{option_results}->{filter_service_name}) && $self->{option_results}->{filter_service_name} ne '' &&
            $service_name !~ /$self->{option_results}->{filter_service_name}/) {
            $self->{output}->output_add(long_msg => "skipping service '" . $service_name . "': no matching filter type.", debug => 1);
            next;
        }

        $self->{services}->{ $service_id } = {
            %{$results->{$service_id}},
            total        => 0,
            running      => 0,
            failed       => 0,
            shutdown     => 0,
            problems     => 0
        };

        foreach my $task_id (keys %{$results->{$service_id}->{tasks}}) {
            if ($results->{$service_id}->{tasks}->{$task_id}->{state} =~ /running|shutdown|failed/i) {
                $self->{services}->{ $service_id }->{ $results->{$service_id}->{tasks}->{$task_id}->{state} }++;
            }
            if ($results->{$service_id}->{tasks}->{$task_id}->{state} ne $results->{$service_id}->{tasks}->{$task_id}->{desired_state}) {
                $self->{services}->{ $service_id }->{problems}++;
                $self->{global}->{problems}++;
            }
            $self->{services}->{ $service_id }->{total}++;
            $self->{tasks}->{ $task_id } = {
                service_id => $service_id,
                task_id => $task_id,
                %{$results->{$service_id}->{tasks}->{$task_id}}
            };
            $self->{global}->{total}++;          
        }
    }

    foreach my $service (keys %{$self->{services}}) {
        if ($self->{services}->{$service}->{total} < $self->{services}->{$service}->{replicas}) {
            $self->{services}->{$service}->{problems}++;
        }
    }
}

1;

__END__

=head1 MODE

Check service status.

=over 8

=item B<--filter-service-name>

Filter services by service name (can be a regexp).

=item B<--unknown-task-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--warning-task-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--critical-task-status>

Define the conditions to match for the status to be CRITICAL (default: '%{desired_state} ne %{state} and %{state} !~ /complete|preparing|assigned/').
You can use the following variables: %{service_id}, %{task_id}, %{service_name}, %{node_name}, %{node_id}, %{desired_state}, %{state_message}, %{container_id}.

=item B<--unknown-service-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{service_id}, %{service_name}, %{node_name}, %{node_id}, %{container_id}, %{total}, %{replicas}, %{problems}.

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{service_id}, %{service_name}, %{node_name}, %{node_id}, %{container_id}, %{total}, %{replicas}, %{problems}.

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{total} != %{replicas} || %{problems} > 0').
You can use the following variables: %{service_id}, %{service_name}, %{node_name}, %{node_id}, %{container_id}, %{total}, %{replicas}, %{problems}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tasks-total', 'tasks-problems-total', 'service-status', 'service-replicas', 'service-tasks', 'service-tasks-problems', 
'service-tasks-running', 'service-tasks-shutdown', 'service-tasks-failed', 'task-status',

=back

=cut
