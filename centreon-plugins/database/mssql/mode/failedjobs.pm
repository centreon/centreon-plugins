#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::Local;

my %states = (
    0 => 'failed',
    1 => 'success',
    2 => 'Retry',
    3 => 'Canceled',
    4 => 'Running',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter:s"                => { name => 'filter', },
                                  "skip"                    => { name => 'skip', },
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "warning-duration:s"      => { name => 'warning_duration', },
                                  "critical-duration:s"     => { name => 'critical_duration', },
                                  "lookback:s"              => { name => 'lookback', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-duration', value => $self->{option_results}->{warning_duration})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning duration threshold '" . $self->{option_results}->{warning_duration} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-duration', value => $self->{option_results}->{critical_duration})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical duration threshold '" . $self->{option_results}->{critical_duration} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All jobs are ok.");

    $self->{sql}->connect();

    my $count = 0;
    my $count_failed = 0;

    my $query = "SELECT j.[name] AS [JobName], run_status, run_duration, h.run_date AS LastRunDate, h.run_time AS LastRunTime,
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
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();
    my @job_failed;
    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter}) && $$row[0] !~ /$self->{option_results}->{filter}/);
        next if (defined($self->{option_results}->{lookback}) && $$row[5] > $self->{option_results}->{lookback});
        $count++;
        my $job_name = $$row[0];
        my $run_status = $$row[1];
        my $run_duration;
        my $run_date = $$row[3];
        my ($year,$month,$day) = $run_date =~ /(\d{4})(\d{2})(\d{2})/;
        my $run_time = $$row[4];
        my ($hour,$minute,$second) = $run_time =~ /(\d{2})(\d{2})(\d{2})/;

        if (defined($$row[2])) {
            $run_duration = $$row[2];
        } else {
            my $start_time = timelocal($second,$minute,$hour,$day,$month-1,$year);
            $run_duration = (time() - $start_time) / 60;
        }

        if ($run_status == 0) {
            $count_failed++;
            push (@job_failed, $job_name);
        } else {
            my $exit_code1 = $self->{perfdata}->threshold_check(value => $run_duration, threshold => [ { label => 'critical-duration', exit_litteral => 'critical' }, { label => 'warning-duration', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit_code1, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code1,
                                            short_msg => sprintf("Job '%s' duration : %d minutes", $job_name, $run_duration));
            }
        }
        $self->{output}->output_add(long_msg => sprintf("Job '%s' status %s [Runtime : %s %s] [Duration : %d minutes]", $job_name, $states{$run_status}, $run_date, $run_time, $run_duration));
    }

    my $exit_code2 = $self->{perfdata}->threshold_check(value => $count_failed, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    if(!defined($self->{option_results}->{skip}) && $count == 0) {
        $self->{output}->output_add(severity => 'Unknown',
                                    short_msg => "No job found.");
    } elsif (!$self->{output}->is_status(value => $exit_code2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit_code2,
                                    short_msg => sprintf("%d failed job(s)", $count_failed));
    }

    $self->{output}->perfdata_add(label => 'failed_jobs',
                                  value => $count_failed,
                                  min => 0,
                                  max => $count);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MSSQL failed jobs.

=over 8

=item B<--filter>

Filter job.

=item B<--skip>

Skip error if no job found.

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--warning-duration>

Threshold warning for job duration.

=item B<--critical-duration>

Threshold critical for job duration.

=item B<--lookback>

Check job history in minutes.

=back

=cut
