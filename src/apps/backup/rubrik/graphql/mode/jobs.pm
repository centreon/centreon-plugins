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

package apps::backup::rubrik::graphql::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_excluded change_seconds flatten_arrays disco_escape/;
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;
use centreon::plugins::constants qw(:counters);
use POSIX qw/floor/;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_last_exec_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => [$self->{result_values}->{jobName}, $self->{result_values}->{jobType}],
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_last_exec_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{lastExecSeconds} >= 0 ?
                     floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) :
                     $self->{result_values}->{lastExecSeconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}


sub custom_failed_prct_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => '%',
        instances => [$self->{result_values}->{jobName}, $self->{result_values}->{jobType}],
        value => sprintf('%.2f', $self->{result_values}->{failedPrct}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => [ $self->{result_values}->{jobName}, $self->{result_values}->{jobType} ],
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{durationSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_duration_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{durationSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Number of jobs ' },
        {
            name => 'jobs', type => COUNTER_TYPE_MULTIPLE, prefix_output => "job '%{name}' [type: %{jobType}] ",
            cb_long_output => "checking job '%{name}' (%{fid}) [type: %{jobType}] [object type: %{objectType}] [location: %{location}] [cluster name: %{clusterName}]",
            indent_long_output => '    ', message_multiple => 'All jobs are ok',
            group => [
                { name => 'failed', type => COUNTER_MULTIPLE_INSTANCE },
                { name => 'timers', type => COUNTER_MULTIPLE_INSTANCE },
                { name => 'executions', type => COUNTER_MULTIPLE_SUBINSTANCE, prefix_output => 'last execution started: %{started} ', message_multiple => 'All executions are ok', display_long => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-executions-detected', display_ok => 0, nlabel => 'jobs.executions.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'executions detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{failed} = [
        { label => 'job-executions-failed-prct', nlabel => 'job.executions.failed.percentage', set => {
                key_values => [ { name => 'failedPrct' }, { name => 'jobName' }, { name => 'jobType' } ],
                output_template => 'number of failed executions: %.2f %%',
                closure_custom_perfdata => $self->can('custom_failed_prct_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{timers} = [
         { label => 'job-execution-last', nlabel => 'job.execution.last', set => {
                key_values  => [ { name => 'lastExecSeconds' }, { name => 'lastExecHuman' }, { name => 'jobName' }, { name => 'jobType' } ],
                output_template => 'last execution %s',
                output_use => 'lastExecHuman',
                closure_custom_perfdata => $self->can('custom_last_exec_perfdata'),
                closure_custom_threshold_check => $self->can('custom_last_exec_threshold')
            }
        },
        { label => 'job-running-duration', nlabel => 'job.running.duration', set => {
                key_values  => [ { name => 'durationSeconds' }, { name => 'durationHuman' }, { name => 'jobName' }, { name => 'jobType' } ],
                output_template => 'running duration %s',
                output_use => 'durationHuman',
                closure_custom_perfdata => $self->can('custom_duration_perfdata'),
                closure_custom_threshold_check => $self->can('custom_duration_threshold')
            }
        }
    ];

    $self->{maps_counters}->{executions} = [
        {
            label => 'execution-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /Failure/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'jobName' }
                ],
                output_template => 'status: %s',
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

        'job-id:s@'               => { name => 'job_id', },
        'include-job-id:s'        => { name => 'include_job_id',        default => '' },
        'exclude-job-id:s'        => { name => 'exclude_job_id',        default => '' },

        'job-name:s'              => { name => 'job_name',              default => '' },
        'include-job-name:s'      => { name => 'include_job_name',      default => '' },
        'exclude-job-name:s'      => { name => 'exclude_job_name',      default => '' },

        'job-type:s@'             => { name => 'job_type',  },
        'include-job-type:s'      => { name => 'include_job_type',      default => '' },
        'exclude-job-type:s'      => { name => 'exclude_job_type',      default => '' },

        'job-status:s@'           => { name => 'job_status', },
        'include-job-status:s'    => { name => 'include_job_status', },
        'exclude-job-status:s'    => { name => 'exclude_job_status', },

        'include-location:s'      => { name => 'include_location', default => '' },
        'exclude-location:s'      => { name => 'exclude_location', default => '' },

        'object-type:s@'          => { name => 'object_type', },
        'include-object-type:s'   => { name => 'include_object_type',   default => '' },
        'exclude-object-type:s'   => { name => 'exclude_object_type',   default => '' },

        'unit:s'                  => { name => 'unit', default => 's' },

        'updated-start-time:s'    => { name => 'updated_start_time',    default => '' },
        'updated-end-time:s'      => { name => 'updated_end_time',      default => '' },
        'updated-last:s'          => { name => 'updated_last',          default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => "Using --cluster-name with this mode is not supported !")
    if $options{option_results}->{cluster_name} && @{$options{option_results}->{cluster_name}};

    timerange_check_options($self);
    timerange_check_options($self, prefix => 'updated');

    $self->{option_results}->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/job_type job_status object_type job_id/;

    $self->{option_results}->{job_type} = [ 'BACKUP' ]
        unless $self->{option_results}->{job_type} && @{$self->{option_results}->{job_type}};
    $self->{option_results}->{job_type} = [ grep { ! /^ALL$/ } @{$self->{option_results}->{job_type}} ];

    # Defaults to last day when no other time filter is used
    $self->{option_results}->{updated_start_time} = 9800
        unless $self->{option_results}->{updated_start_time} || $self->{option_results}->{updated_end_time} || $self->{option_results}->{start_time} || $self->{option_results}->{end_time}

}

my @_entities = [ 'jobId', 'jobName', 'jobType', 'locationName' ];

sub manage_selection {
    my ($self, %options) = @_;

    my $cluster_filters = $options{custom}->common_filters();

    # activitySeriesConnection does not support native filtering by name, so we convert names to UUIDs
    my $cluster_ids = $cluster_filters->{id} // [];
    if ($cluster_filters->{name}) {
        my $other_clusters = $options{custom}->clusters_uuid_from_name(@{$cluster_filters->{name}});

        $self->{output}->option_exit(short_msg => 'No matching cluster !')
            unless ref $other_clusters eq 'ARRAY' && @$other_clusters;

        push @$cluster_ids, @$other_clusters;
    }

    my %filters;

    $filters{objectName} = $self->{option_results}->{job_name} if $self->{option_results}->{job_name} ne '';
    $filters{objectType} = $self->{option_results}->{object_type} if @{$self->{option_results}->{object_type}};
    $filters{objectFid} = $self->{option_results}->{job_id} if @{$self->{option_results}->{job_id}};
    $filters{lastActivityType} = $self->{option_results}->{job_type} if @{$self->{option_results}->{job_type}};
    $filters{lastActivityStatus} = $self->{option_results}->{job_status} if @{$self->{option_results}->{job_status}};
    $filters{clusterId} = $cluster_ids if $cluster_ids && @$cluster_ids;

    $filters{startTimeGt} = $self->{option_results}->{start_time}
        if $self->{option_results}->{start_time} ne '';
    $filters{startTimeLt} = $self->{option_results}->{end_time}
        if $self->{option_results}->{end_time} ne '';

    $filters{lastUpdatedTimeGt} = $self->{option_results}->{updated_start_time}
        if $self->{option_results}->{updated_start_time} ne '';
    $filters{lastUpdatedTimeLt} = $self->{option_results}->{updated_end_time}
        if $self->{option_results}->{updated_end_time} ne '';

    my $jobs_exec = $options{custom}->get_jobs_monitoring(
        filters => \%filters
    );

    return $jobs_exec if $self->{output}->is_disco_show();

    my $ctime = time();
    $self->{global} = { detected => 0 };
    $self->{jobs} = {};
    my $s = $self->{option_results};

    my %jobs_by_id;
    foreach my $exec (@$jobs_exec) {
        $exec->{$_} //= '' foreach qw/fid objectName objectType location lastActivityStatus lastActivityType clusterName/;

        my $clusterId = $exec->{cluster} && $exec->{cluster}->{id} ? $exec->{cluster}->{id} : undef;
        next if is_excluded($exec->{fid}, $s->{include_job_id}, $s->{exclude_job_id}, output => $self->{output}) ||
                is_excluded($exec->{objectName}, $s->{include_job_name}, $s->{exclude_job_name}, output => $self->{output}) ||
                is_excluded($exec->{lastActivityType}, $s->{include_job_type}, $s->{exclude_job_type}, output => $self->{output}) ||
                is_excluded($exec->{objectType}, $s->{include_object_type}, $s->{exclude_object_type}, output => $self->{output}) ||
                is_excluded($exec->{location}, $s->{include_location}, $s->{exclude_location}, output => $self->{output}) ||
                is_excluded($exec->{lastActivityStatus}, $s->{include_job_status}, $s->{exclude_job_status}, output => $self->{output}) ||
                $options{custom}->is_common_excluded(id => $clusterId, name => $exec->{clusterName});

        push @{$jobs_by_id{$exec->{fid}}}, $exec;
    }

    foreach my $fid (keys %jobs_by_id) {
        my $executions = $jobs_by_id{$fid};
        my $first = $executions->[0];

        $self->{global}->{detected} += scalar @$executions;

        my ($last_exec, $running_exec);
        my ($failed, $total) = (0, 0);

        foreach my $exec (@$executions) {
            $running_exec = $exec
                if $exec->{lastActivityStatus} =~ /Running/i && (!defined($running_exec) || $exec->{startTime} gt $running_exec->{startTime});

            $last_exec = $exec
                if $exec->{lastActivityStatus} !~ /Queued|Canceled|Canceling/i && (!defined($last_exec) || $exec->{startTime} gt $last_exec->{startTime});

            $failed++ if $exec->{lastActivityStatus} =~ /Failure/i;
            $total++;
        }

        $self->{jobs}->{$fid} = {
            name => $first->{objectName},
            fid => $fid,
            jobType => $first->{lastActivityType},
            objectType => $first->{objectType},
            location => $first->{location},
            clusterName => $first->{clusterName},
            timers => {},
            executions => {}
        };

        $self->{jobs}->{$fid}->{failed} = {
            jobName => $first->{objectName},
            jobType => $first->{lastActivityType},
            failedPrct => $total > 0 ? $failed * 100 / $total : 0
        };

        if ($last_exec) {
            $self->{jobs}->{$fid}->{executions}->{last} = {
                jobName => $first->{objectName},
                jobType => $first->{lastActivityType},
                started => $last_exec->{startTime},
                status => $last_exec->{lastActivityStatus}
            };

            if ($last_exec->{startTime} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/) {
                my $dt_start = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
                my $start_time = $dt_start->epoch();
                my $elapsed = $ctime - $start_time;
                my $end_time;

                if ($last_exec->{lastActivityStatus} =~ /Running|Canceling/i) {
                    $end_time = $ctime;
                } elsif ($last_exec->{lastUpdated} && $last_exec->{lastUpdated} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/) {
                    my $dt_end = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
                    $end_time = $dt_end->epoch();
                }

                $self->{jobs}->{$fid}->{timers} = {
                    jobName => $first->{objectName},
                    jobType => $first->{lastActivityType},
                    lastExecSeconds => $elapsed,
                    lastExecHuman => change_seconds(value => $elapsed)
                };

                if ($end_time) {
                    my $duration = $end_time - $start_time;
                    $self->{jobs}->{$fid}->{timers}->{durationSeconds} = $duration;
                    $self->{jobs}->{$fid}->{timers}->{durationHuman} = change_seconds(value => $duration);
                }
            }
        } else {
            $self->{jobs}->{$fid}->{timers} = {
                jobName => $first->{objectName},
                jobType => $first->{lastActivityType},
                lastExecSeconds => -1,
                lastExecHuman => 'never'
            };
        }
    }

}

sub disco_show {
    my ($self, %options) = @_;

    my $jobs = $self->manage_selection(%options);

    return unless ref $jobs eq 'ARRAY';

    foreach my $job (@{$jobs}) {
        $self->{output}->add_disco_entry(
            jobId => $job->{fid}, jobName => disco_escape($job->{objectName}), jobType => $job->{lastActivityType}, locationName => disco_escape($job->{location} // '')
        );
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => @_entities);
}

1;

__END__

=head1 MODE

Check Rubrik backup jobs using GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering executions by creation date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering executions by creation date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last executions. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).

=item B<--updated-start-time>

Set start time for filtering executions by update date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--updated-end-time>

Set end time for filtering executions by update date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--updated-last>

Set duration to filter last executions by update date. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).
When no time filtering is used updated-last defaults to C<7d>.

=item B<--job-name>

Filter jobs by job name. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--job-type>

Filter jobs by job type. Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).
Default: 'BACKUP'. Use 'ALL' to include all job types.
Refer to the Rubrik documentation for more information about available values.

=item B<--job-status>

Filter jobs by job status. Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--object-type>

Filter jobs by object type. Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--job-id>

Filter jobs by job ID. Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--include-job-id>

Filter jobs by job ID (can be a regexp).

=item B<--exclude-job-id>

Exclude jobs by job ID (can be a regexp).

=item B<--include-job-name>

Filter jobs by job name (can be a regexp).

=item B<--exclude-job-name>

Exclude jobs by job name (can be a regexp).

=item B<--include-job-type>

Filter jobs by job type (can be a regexp).

=item B<--exclude-job-type>

Exclude jobs by job type (can be a regexp).

=item B<--include-job-status>

Filter jobs by job status (can be a regexp).

=item B<--exclude-job-status>

Exclude jobs by job status (can be a regexp).

=item B<--include-object-type>

Filter jobs by object type (can be a regexp).

=item B<--exclude-object-type>

Exclude jobs by object type (can be a regexp).

=item B<--include-location>

Filter jobs by location (can be a regexp).

=item B<--exclude-location>

Exclude jobs by location (can be a regexp).

=item B<--unit>

Select the time unit for last execution time thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--limit>

Define the number of entries to retrieve for the pagination (default: 500).

=item B<--unknown-execution-status>

Set unknown threshold for last job execution status.
You can use the following variables: %{status}, %{jobName}

=item B<--warning-execution-status>

Set warning threshold for last job execution status.
You can use the following variables: %{status}, %{jobName}

=item B<--critical-execution-status>

Set critical threshold for last job execution status (default: %{status} =~ /Failure/i).
You can use the following variables: %{status}, %{jobName}

=item B<--warning-job-execution-last>

Warning threshold for last execution time (unit defined by --unit option).

=item B<--critical-job-execution-last>

Critical threshold for last execution time (unit defined by --unit option).

=item B<--warning-job-executions-failed-prct>

Warning threshold for percentage of failed executions.

=item B<--critical-job-executions-failed-prct>

Critical threshold for percentage of failed executions.

=item B<--warning-job-running-duration>

Warning threshold for running execution duration (unit defined by --unit option).

=item B<--critical-job-running-duration>

Critical threshold for running execution duration (unit defined by --unit option).

=item B<--warning-jobs-executions-detected>

Warning threshold for number of executions detected.

=item B<--critical-jobs-executions-detected>

Critical threshold for number of executions detected.

=back

=cut
