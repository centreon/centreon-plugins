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

package apps::backup::veeam::vbem::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5;
use DateTime;
use POSIX;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_last_exec_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        instances => $self->{result_values}->{name},
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
        instances => $self->{result_values}->{name},
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
        "checking job '%s' [ŧype: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return sprintf(
        "job '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_execution_output {
    my ($self, %options) = @_;

    return sprintf(
        "execution started: %s ",
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
                key_values => [ { name => 'failedPrct' }, { name => 'name' } ],
                output_template => 'number of failed executions: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{timers} = [
         { label => 'job-execution-last', nlabel => 'job.execution.last', set => {
                key_values  => [ { name => 'lastExecSeconds' }, { name => 'lastExecHuman' }, { name => 'name' } ],
                output_template => 'last execution %s',
                output_use => 'lastExecHuman',
                closure_custom_perfdata => $self->can('custom_last_exec_perfdata'),
                closure_custom_threshold_check => $self->can('custom_last_exec_threshold')
            }
        },
        { label => 'job-running-duration', nlabel => 'job.running.duration', set => {
                key_values  => [ { name => 'durationSeconds' }, { name => 'durationHuman' }, { name => 'name' } ],
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
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /failed/i',
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
        'filter-uid:s'  => { name => 'filter_uid' },
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type' },
        'timeframe:s'   => { name => 'timeframe' },
        'unit:s'        => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

    if (!defined($self->{option_results}->{timeframe}) || $self->{option_results}->{timeframe} eq '') {
        $self->{option_results}->{timeframe} = 86400;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jobs_exec = $options{custom}->get_backup_job_session(timeframe => $self->{option_results}->{timeframe});

    my $ctime = time();

    $self->{global} = { detected => 0 };
    $self->{jobs} = {};
    foreach my $job (@{$jobs_exec->{Entities}->{BackupJobSessions}->{BackupJobSessions}}) {
        next if (defined($self->{option_results}->{filter_uid}) && $self->{option_results}->{filter_uid} ne '' && $job->{JobUid} !~ /$self->{option_results}->{filter_uid}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && $job->{JobName} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' && $job->{JobType} !~ /$self->{option_results}->{filter_type}/);

        if (!defined($self->{jobs}->{ $job->{JobUid} })) {
            $self->{jobs}->{ $job->{JobUid} } = {
                name => $job->{JobName},
                type => $job->{JobType},
                failed => { name => $job->{JobName}, total => 0, failed => 0 }
            };
            $self->{global}->{detected}++;
        }

        $job->{CreationTimeUTC} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
        my $epoch = $dt->epoch();
        
        if (!defined($self->{jobs}->{ $job->{JobUid} }->{executions}) || $epoch > $self->{jobs}->{ $job->{JobUid} }->{executions}->{last}->{epoch}) {
            $self->{jobs}->{ $job->{JobUid} }->{executions}->{last} = {
                jobName => $job->{JobName},
                started => $job->{CreationTimeUTC},
                status => $job->{Result},
                epoch => $epoch
            };

            $self->{jobs}->{ $job->{JobUid} }->{timers} = {
                name => $job->{JobName},
                lastExecSeconds => $ctime - $epoch,
                lastExecHuman => centreon::plugins::misc::change_seconds(value => $ctime - $epoch)
            };

            if ($job->{State} =~ /Starting|Working|Resuming/i) {
                my $duration = $ctime - $epoch;
                $self->{jobs}->{ $job->{JobUid} }->{timers}->{durationSeconds} = $duration;
                $self->{jobs}->{ $job->{JobUid} }->{timers}->{durationHuman} = centreon::plugins::misc::change_seconds(value => $duration);
            }
        }

        $self->{jobs}->{ $job->{JobUid} }->{failed}->{total}++;
        if (defined($job->{Result}) && $job->{Result} =~ /Failed/i) {
            $self->{jobs}->{ $job->{JobUid} }->{failed}->{failed}++;
        }
    }

    foreach my $uid (keys %{$self->{jobs}}) {
        $self->{jobs}->{$uid}->{failed}->{failedPrct} = $self->{jobs}->{$uid}->{failed}->{total} > 0 ? $self->{jobs}->{$uid}->{failed}->{failed} * 100 / $self->{jobs}->{$uid}->{failed}->{total} : 0;
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-uid>

Filter jobs by UID.

=item B<--filter-name>

Filter jobs by name.

=item B<--filter-type>

Filter jobs by type.

=item B<--timeframe>

Timeframe to get BackupJobSession (in seconds. Default: 86400). 

=item B<--unit>

Select the time unit for last execution time thresholds. May be 's' for seconds,'m' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--unknown-execution-status>

Set unknown threshold for last job execution status.
You can use the following variables: %{status}, %{jobName}

=item B<--warning-execution-status>

Set warning threshold for last job execution status (default: %{status} =~ /warning/i).
You can use the following variables like: %{status}, %{jobName}

=item B<--critical-execution-status>

Set critical threshold for last job execution status (default: %{status} =~ /failed/i).
You can use the following variables: %{status}, %{jobName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-executions-detected', 'job-executions-failed-prct',
'job-execution-last', 'job-running-duration'.

=back

=cut
