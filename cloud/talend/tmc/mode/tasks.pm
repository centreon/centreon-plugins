#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package cloud::talend::tmc::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub task_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking task '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_task_output {
    my ($self, %options) = @_;

    return sprintf(
        "task '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of tasks ';
}

sub prefix_execution_output {
    my ($self, %options) = @_;

    return sprintf(
        "execution '%s' [started: %s] ",
        $options{instance_value}->{executionId},
        $options{instance_value}->{started}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'tasks', type => 3, cb_prefix_output => 'prefix_task_output', cb_long_output => 'task_long_output', indent_long_output => '    ', message_multiple => 'All tasks are ok',
            group => [
                { name => 'failed', type => 0 },
                { name => 'timers', type => 0 },
                { name => 'executions', type => 1, cb_prefix_output => 'prefix_execution_output', message_multiple => 'executions are ok', display_long => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tasks-executions-detected', display_ok => 0, nlabel => 'tasks.executions.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'executions detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{failed} = [
        { label => 'task-executions-failed-prct', nlabel => 'task.executions.failed.percentage', set => {
                key_values => [ { name => 'failedPrct' } ],
                output_template => 'number of failed executions: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{executions} = [
        {
            label => 'execution-status',
            type => 2,
            critical_default => '%{status} =~ /deploy_failed|execution_rejected|execution_failed|terminated_timeout/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'taskName' }
                ],
                output_template => "status: %s",
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
        'task-id:s'          => { name => 'task_id' },
        'environment-name:s' => { name => 'environment_name' },
        'since-timeperiod:s' => { name => 'since_timeperiod' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{since_timeperiod}) || $self->{option_results}->{since_timeperiod} eq '') {
        $self->{option_results}->{since_timeperiod} = 86400;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $environments = $options{custom}->get_environments();
    my $environmentId;
    if (defined($self->{option_results}->{environment_name}) && $self->{option_results}->{environment_name} ne '') {
        foreach (@$environments) {
            if ($_->{name} eq $self->{option_results}->{environment_name}) {
                $environmentId = $_->{id};
                last;
            }
        }

        if (!defined($environmentId)) {
            $self->{output}->add_option_msg(short_msg => 'unknown environment name ' . $self->{option_results}->{environment_name});
            $self->{output}->option_exit();
        }
    }

    my $tasks_config = $options{custom}->get_tasks_config();

    my $to = time();
    my $tasks_exec = $options{custom}->get_tasks_execution(
        from => ($to - $self->{option_results}->{since_timeperiod}) * 1000,
        to => $to * 1000,
        environmentId => $environmentId,
        taskId => $self->{option_results}->{task_id}
    );

    $self->{global} = { detected => 0 };
    $self->{tasks} = {};
    foreach my $task (@$tasks_config) {
        next if (defined($self->{option_results}->{task_id}) && $self->{option_results}->{task_id} ne '' && $task->{executable} ne $self->{option_results}->{task_id});
        next if (defined($environmentId) && $task->{workspace}->{environment}->{id} ne $environmentId);

        $self->{tasks}->{ $task->{name} } = {
            name => $task->{name},
            timers => {},
            executions => {}
        };

        my ($last_exec, $older_running_exec);
        my ($failed, $total) = (0, 0);
        foreach my $task_exec (@$tasks_exec) {
            next if ($task_exec->{taskId} ne $task->{executable});

            if (!defined($task_exec->{finishTimestamp})) {
                $older_running_exec = $task_exec;
            }
            if (!defined($last_exec)) {
                $last_exec = $task_exec;
            }

            $self->{global}->{detected}++;
            $failed++ if ($task_exec->{status} =~ /deploy_failed|execution_rejected|execution_failed|terminated_timeout/);
            $total++;
        }

        $self->{tasks}->{ $task->{name} }->{failed} = {
            failedPrct => $total > 0 ? $failed * 100 / $total : 0
        };

        if (defined($last_exec)) {
            $self->{tasks}->{ $task->{name} }->{executions}->{ $last_exec->{executionId} } = {
                executionId => $last_exec->{executionId},
                taskName => $task->{name},
                started => $last_exec->{startTimestamp},
                status => $last_exec->{status}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check tasks.

=over 8

=item B<--task-id>

Task filter .

=item B<--environment-name>

Environment filter.

=item B<--since-timeperiod>

Time period to get tasks and plans execution informations (in seconds. Default: 86400). 

=item B<--unknown-execution-status>

Set unknown threshold for last task execution status.
Can used special variables like: %{status}, %{taskName}

=item B<--warning-execution-status>

Set warning threshold for last task execution status.
Can used special variables like: %{status}, %{taskName}

=item B<--critical-execution-status>

Set critical threshold for last task execution status.
Can used special variables like: %{status}, %{taskName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tasks-executions-detected', 'task-executions-failed-prct'.

=back

=cut
