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

package apps::backup::rubrik::graphql::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(flatten_arrays is_empty);
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;
use centreon::plugins::constants qw(:counters);

sub prefix_task_output {
    my ($self, %options) = @_;

    return "task '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Tasks ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'succeeded', nlabel => 'tasks.succeeded.count', set => {
                key_values => [ { name => 'succeeded' } ],
                output_template => 'succeeded: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'failed', nlabel => 'tasks.failed.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'canceled', nlabel => 'tasks.canceled.count', set => {
                key_values => [ { name => 'canceled' } ],
                output_template => 'canceled: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
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
        %$timerange_filters,
        'task-category:s@'            => { name => 'task_category' },
        'object-type:s@'              => { name => 'object_type' },
        'task-status:s@'              => { name => 'task_status' },
        'task-type:s@'                => { name => 'task_type' },
        'display-on-status:s'         => { name => 'display_on_status', default => 'canceled|failed' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => "Using --cluster-name with this mode is not supported !")
        if $options{option_results}->{cluster_name} && @{$options{option_results}->{cluster_name}};

    timerange_check_options($self, %options);

    $self->{option_results}->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/task_category object_type task_status task_type/;

    $self->{option_results}->{start_time} = 1440 unless $self->{option_results}->{start_time};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { succeeded => 0, failed => 0, canceled => 0 };

    my %details = ( succeeded => [], failed => [], canceled => [] );

    my %filters;
    $filters{taskCategory} = $self->{option_results}->{task_category} if @{$self->{option_results}->{task_category}};
    $filters{objectType} = $self->{option_results}->{object_type} if @{$self->{option_results}->{object_type}};
    $filters{taskStatus} = $self->{option_results}->{task_status} if @{$self->{option_results}->{task_status}};
    $filters{taskType} = $self->{option_results}->{task_type} if @{$self->{option_results}->{task_type}};
    $filters{time_gt} = $self->{option_results}->{start_time} if $self->{option_results}->{start_time} ne '';
    $filters{time_lt} = $self->{option_results}->{end_time} if $self->{option_results}->{end_time} ne '';

    my $tasks = $options{custom}->get_protection_tasks( filters => \%filters );

    foreach my $task (@$tasks) {
        next unless $task->{status};

        my $status = lc $task->{status};
        $status = 'succeeded' if $status eq 'success' or $status eq 'succeeded with warnings';

        next unless exists $self->{global}->{$status};

        $self->{output}->output_add(long_msg => sprintf("Task %s: '%s' (%s, %s), cluster: '%s' (%s), start time: '%s', end time '%s'",
                                                        $task->{status}, $task->{objectName}, $task->{objectType}, $task->{taskType}, $task->{clusterName},
                                                        $task->{clusterUuid}, $task->{startTime}, $task->{endTime}).
                                                    (is_empty($task->{failureReason}) ? '' : ", reason: '".$task->{failureReason}."'"))
            if $self->{output}->is_verbose() && $self->{option_results}->{display_on_status} && $status =~ $self->{option_results}->{display_on_status};

        $self->{global}->{$status}++;
    }
}

1;

__END__

=head1 MODE

Check tasks via GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering tasks. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering tasks. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last tasks. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).
Default is: C<1d> (1 day).

=item B<--task-category>

Filter by task category. Multiple values can be separated by comma.
Can be 'protected' or 'recovery'. Default is 'protected'.

=item B<--object-type>

Filter by object type. Multiple values can be separated by comma.

=item B<--task-status>

Filter by task status. Multiple values can be separated by comma.

=item B<--task-type>

Filter by task type. Multiple values can be separated by comma.

=item B<--display-on-status>

Display task details in verbose output for matching status (default: 'canceled|failed').
Available status: succeeded, canceled, failed
Can be a regexp to match multiple statuses.

=item B<--warning-succeeded>

Warning threshold for number of succeeded tasks.

=item B<--critical-succeeded>

Critical threshold for number of succeeded tasks.

=item B<--warning-failed>

Warning threshold for number of failed tasks.

=item B<--critical-failed>

Critical threshold for number of failed tasks.

=item B<--warning-canceled>

Warning threshold for number of canceled tasks.

=item B<--critical-canceled>

Critical threshold for number of canceled tasks.

=back

=cut
