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

package database::mssql::mode::failedjobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::Local;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "job '%s' status %s [runtime: %s] [duration: %s]",
        $self->{result_values}->{name},
        $self->{result_values}->{status},
        $self->{result_values}->{runtime},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
    );
}


sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Jobs  ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'jobs', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'jobs.problems.current.count', min => 0 },
          group => [ { name => 'job', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-total', nlabel => 'jobs.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach (('failed', 'success', 'canceled', 'running', 'retry')) {
        push @{$self->{maps_counters}->{global}},
            { label => 'jobs-' . $_, nlabel => 'jobs.' . $_ . '.count', display_ok => 0, set => {
                    key_values => [ { name => $_ }, { name => 'total' } ],
                    output_template => $_ . ': %s',
                    perfdatas => [
                        { template => '%s', min => 0, max => 'total' }
                    ]
                }
            };
    }

    $self->{maps_counters}->{job} = [
        {
            label => 'status',
            type => 2,
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' },
                    { name => 'runtime'}, { name => 'duration' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter:s'            => { name => 'filter' },
        'warning:s'           => { name => 'warning', redirect => 'warning-jobs-failed-count' },  # legacy
        'critical:s'          => { name => 'critical', redirect => 'critical-jobs-failed-count' }, # legacy
        'lookback:s'          => { name => 'lookback' }
    });

    return $self;
}

my $map_state = {
    0 => 'failed',
    1 => 'success',
    2 => 'retry',
    3 => 'canceled',
    4 => 'running'
};

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    my $query = "
        SELECT 
            j.[name] AS [JobName], run_status, run_duration, h.run_date AS LastRunDate, h.run_time AS LastRunTime,
            CASE
            WHEN h.[run_date] IS NULL OR h.[run_time] IS NULL THEN NULL
            ELSE datediff(Minute, CAST(
                CAST(h.[run_date] AS CHAR(8))
                + ' '
                + STUFF(
                    STUFF(RIGHT('000000' + CAST(h.[run_time] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                        , 6, 0, ':')
                AS DATETIME), current_timestamp)
            END AS [MinutesSinceStart]
        FROM msdb.dbo.sysjobhistory h 
        INNER JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id 
        WHERE j.enabled = 1 
        AND h.instance_id IN (SELECT MAX(h.instance_id) 
        FROM msdb.dbo.sysjobhistory h GROUP BY (h.job_id))";
    $options{sql}->query(query => $query);    
    my $result = $options{sql}->fetchall_arrayref();

    $self->{global} = {
        total => 0,
        failed => 0,
        success => 0,
        retry => 0,
        canceled => 0,
        running => 0
    };
    $self->{jobs}->{global} = { job => {} };

    # run_date format = YYYYMMDD
    # run_time format = HHMMSS. Can be: HMMSS
    # run_duration format = HHMMSS
    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter}) && $row->[0] !~ /$self->{option_results}->{filter}/);
        next if (defined($self->{option_results}->{lookback}) && $row->[5] > $self->{option_results}->{lookback});
    
        my $job_name = $row->[0];
        my $run_duration;
        my $run_date = $row->[3];
        my ($year, $month, $day) = $run_date =~ /(\d{4})(\d{2})(\d{2})/;
        my $run_time = sprintf('%06d', $row->[4]);
        my ($hour, $minute, $second) = $run_time =~ /(\d{2})(\d{2})(\d{2})$/;

        if (defined($row->[2])) {
            my $run_duration_padding = sprintf('%06d', $row->[2]);
            my ($hour_duration, $minute_duration, $second_duration) = $run_duration_padding =~ /(\d{2})(\d{2})(\d{2})$/;
            $run_duration = ($hour_duration * 3600 + $minute_duration * 60 + $second_duration);
        } else {
            my $start_time = timelocal($second, $minute, $hour, $day, $month - 1, $year);
            $run_duration = (time() - $start_time);
        }

        $self->{jobs}->{global}->{job}->{$job_name} = {
            name => $job_name,
            status => $map_state->{ $row->[1] },
            duration => $run_duration,
            runtime => (defined($year) ? $year . '-' . $month . '-' . $day : '') . $hour . ':' . $minute . ':' . $second
        };

        $self->{global}->{total}++;
        $self->{global}->{ $map_state->{ $row->[1] } }++;
    }
}

1;

__END__

=head1 MODE

Check MSSQL failed jobs.

=over 8

=item B<--filter>

Filter job.

=item B<--lookback>

Check job history in minutes.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{status}, %{duration}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{name}, %{status}, %{duration}

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'jobs-total', 'jobs-failed', 'jobs-success', 'jobs-canceled', 'jobs-running', 'jobs-retry'.

=back

=cut
