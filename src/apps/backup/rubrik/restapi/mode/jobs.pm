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

package apps::backup::rubrik::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;
use DateTime;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use centreon::plugins::statefile;

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
        value => $self->{result_values}->{lastExecSeconds} >= 0 ? floor($self->{result_values}->{lastExecSeconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }) : $self->{result_values}->{lastExecSeconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => [$self->{result_values}->{jobName}, $self->{result_values}->{jobType}],
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

sub job_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking job '%s' [type: %s] [object type: %s] [location name: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{jobType},
        $options{instance_value}->{objectType},
        $options{instance_value}->{locationName}
    );
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return sprintf(
        "job '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{jobType}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_execution_output {
    my ($self, %options) = @_;

    return sprintf(
        "last execution started: %s ",
        $options{instance_value}->{started}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'jobs', type => 3, cb_prefix_output => 'prefix_job_output', cb_long_output => 'job_long_output', indent_long_output => '    ', message_multiple => 'All jobs are ok',
            group => [
                { name => 'failed', type => 0 },
                { name => 'timers', type => 0, skipped_code => { -10 => 1 } },
                { name => 'executions', type => 1, cb_prefix_output => 'prefix_execution_output', message_multiple => 'executions are ok', display_long => 1, skipped_code => { -10 => 1 } },
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
                closure_custom_perfdata => sub {
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
            type => 2,
            critical_default => '%{status} =~ /failure/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'jobName' }
                ],
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
        'filter-job-id:s'        => { name => 'filter_job_id' },
        'filter-job-name:s'      => { name => 'filter_job_name' },
        'filter-job-type:s'      => { name => 'filter_job_type' },
        'filter-location-name:s' => { name => 'filter_location_name' },
        'filter-object-type:s'   => { name => 'filter_object_type' },
        'unit:s'                 => { name => 'unit', default => 's' },
        'limit:s'                => { name => 'limit' },
        'check-retention'        => { name => 'check_retention' }
    });

    $self->{cache_exec} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

    if (!defined($self->{option_results}->{limit}) || $self->{option_results}->{limit} !~ /\d+/) {
        $self->{option_results}->{limit} = 500;
    }

    $self->{cache_exec}->check_options(option_results => $self->{option_results}, default_format => 'json');
}

sub manage_selection {
    my ($self, %options) = @_;

    my $get_param = [ 'limit=' . $self->{option_results}->{limit} ];
    if (defined($self->{option_results}->{filter_job_type}) && $self->{option_results}->{filter_job_type} ne '') {
        push @{$get_param}, 'job_type=' . $self->{option_results}->{filter_job_type};
    }
    my $jobs_exec = $options{custom}->get_jobs_monitoring(get_param => $get_param);

    $self->{cache_exec}->read(statefile => 'rubrik_' . $self->{mode} . '_' .
        Digest::MD5::md5_hex(
            $options{custom}->get_connection_info() . '_' .
            (defined($self->{option_results}->{filter_job_id}) ? $self->{option_results}->{filter_job_id} : '') . '_' .
            (defined($self->{option_results}->{filter_job_name}) ? $self->{option_results}->{filter_job_name} : '') . '_' .
            (defined($self->{option_results}->{filter_job_type}) ? $self->{option_results}->{filter_job_type} : '') . '_' .
            (defined($self->{option_results}->{filter_object_type}) ? $self->{option_results}->{filter_object_type} : '')
        )
    );
    my $ctime = time();
    my $last_exec_times = $self->{cache_exec}->get(name => 'jobs');
    $last_exec_times = {} if (!defined($last_exec_times));   
    my %jobs_detected = ();

    $self->{global} = { detected => 0 };
    $self->{jobs} = {};
    foreach my $job_exec (@$jobs_exec) {
        next if (defined($self->{option_results}->{filter_job_id}) && $self->{option_results}->{filter_job_id} ne '' && 
            $job_exec->{objectId} !~ /$self->{option_results}->{filter_job_id}/);
        next if (defined($self->{option_results}->{filter_job_name}) && $self->{option_results}->{filter_job_name} ne '' && 
            $job_exec->{objectName} !~ /$self->{option_results}->{filter_job_name}/);
        next if (defined($self->{option_results}->{filter_object_type}) && $self->{option_results}->{filter_object_type} ne '' && 
            $job_exec->{objectType} !~ /$self->{option_results}->{filter_object_type}/i);
        next if (defined($self->{option_results}->{filter_location_name}) && $self->{option_results}->{filter_location_name} ne '' && 
            $job_exec->{locationName} !~ /$self->{option_results}->{filter_location_name}/);

        $self->{global}->{detected}++;
        $jobs_detected{$job_exec->{objectName}} = 1;
        $job_exec->{jobType} = lc($job_exec->{jobType});

        if (!defined($self->{jobs}->{ $job_exec->{objectId} })) {
            $self->{jobs}->{ $job_exec->{objectId} } = {
                name => $job_exec->{objectName},
                jobType => $job_exec->{jobType},
                objectType => $job_exec->{objectType},
                locationName => $job_exec->{locationName},
                timers => {},
                executions => {}
            };
        }

        my ($last_exec, $older_running_exec);
        my ($failed, $total) = (0, 0);
        foreach (@$jobs_exec) {
            next if ($_->{objectId} ne $job_exec->{objectId});

            if (!defined($_->{endTime}) && $_->{jobStatus} =~ /Active/i) {
                $older_running_exec = $_;
            }
            
            if ($_->{jobStatus} !~ /Scheduled|Canceled|Canceling|CancelingScheduled/i) {
                $last_exec = $_;
            }

            # Failure, Scheduled, Success, SuccessfulWithWarnings, Active, Canceled
            $failed++ if ($_->{jobStatus} =~ /Failure/i);
            $total++;
        }

        $self->{jobs}->{ $job_exec->{objectId} }->{failed} = {
            jobName => $job_exec->{objectName},
            jobType => $job_exec->{jobType},
            failedPrct => $total > 0 ? $failed * 100 / $total : 0
        };

        if (defined($last_exec)) {
            $self->{jobs}->{ $job_exec->{objectId} }->{executions}->{last} = {
                jobName => $job_exec->{objectName},
                started => $last_exec->{startTime},
                status => $last_exec->{jobStatus}
            };

            $last_exec->{startTime} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
            my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
            $last_exec_times->{ $job_exec->{objectId} } = {
                jobName => $job_exec->{objectName},
                jobType => $job_exec->{jobType},
                epoch => $dt->epoch(),
                objectType => $job_exec->{objectType},
                locationName => $job_exec->{locationName}
            };
        }

        $self->{jobs}->{ $job_exec->{objectId} }->{timers} = {
            jobName => $job_exec->{objectName},
            jobType => $job_exec->{jobType},
            lastExecSeconds => defined($last_exec_times->{ $job_exec->{objectId} }) ? $ctime - $last_exec_times->{ $job_exec->{objectId} }->{epoch} : -1,
            lastExecHuman => 'never'
        };
        if (defined($last_exec_times->{ $job_exec->{objectId} })) {
            $self->{jobs}->{ $job_exec->{objectId} }->{timers}->{lastExecHuman} = centreon::plugins::misc::change_seconds(value => $ctime - $last_exec_times->{ $job_exec->{objectId} }->{epoch});
        }

        if (defined($older_running_exec)) {
            $older_running_exec->{startTime} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
            my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
            my $duration = $ctime - $dt->epoch();
            $self->{jobs}->{ $job_exec->{objectId} }->{timers}->{durationSeconds} = $duration;
            $self->{jobs}->{ $job_exec->{objectId} }->{timers}->{durationHuman} = centreon::plugins::misc::change_seconds(value => $duration);
        }
    }

    foreach my $objectId (keys %$last_exec_times) {
        next if (defined($self->{jobs}->{$objectId}));

        $self->{jobs}->{$objectId} = {
            name => $last_exec_times->{$objectId}->{jobName},
            jobType => $last_exec_times->{$objectId}->{jobType},
            objectType => $last_exec_times->{$objectId}->{objectType},
            locationName => $last_exec_times->{$objectId}->{locationName},
            timers => {
                jobName => $last_exec_times->{$objectId}->{jobName},
                jobType => $last_exec_times->{$objectId}->{jobType},
                lastExecSeconds => $ctime - $last_exec_times->{$objectId}->{epoch},
                lastExecHuman => centreon::plugins::misc::change_seconds(value => $ctime - $last_exec_times->{$objectId}->{epoch})
            }
        };
    }

    if ($self->{global}->{detected} == 0 && defined($self->{option_results}->{check_retention})) {
            my $jobs_last_detected = $self->{cache_exec}->get(name => 'jobs');
            foreach my $job_id (keys %{$jobs_last_detected}) {
                if (!defined($jobs_detected{$jobs_last_detected->{$job_id}->{jobName}})) {
                    $self->{global}->{detected}++;
                }
            }
    }

    $self->{cache_exec}->write(data => {
        jobs => $last_exec_times
    });
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-job-id>

Filter jobs by job ID.

=item B<--filter-job-name>

Filter jobs by job name.

=item B<--filter-job-type>

Filter jobs by job type.

=item B<--filter-object-type>

Filter jobs by object type.

=item B<--filter-location-name>

Filter jobs by location name.

=item B<--unit>

Select the time unit for last execution time thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--limit>

Define the number of entries to retrieve for the pagination (default: 500). 

=item B<--check-retention>

Use the retention file to check if a job has been detected once but does not appear in the API response. 

=item B<--unknown-execution-status>

Set unknown threshold for last job execution status.
You can use the following variables: %{status}, %{jobName}

=item B<--warning-execution-status>

Set warning threshold for last job execution status.
You can use the following variables: %{status}, %{jobName}

=item B<--critical-execution-status>

Set critical threshold for last job execution status (default: %{status} =~ /Failure/i).
You can use the following variables: %{status}, %{jobName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-executions-detected', 'job-executions-failed-prct',
'job-execution-last', 'job-running-duration'.

=back

=cut
