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

package apps::backup::veeam::wsman::mode::jobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::jobstatus;
use apps::backup::veeam::wsman::mode::resources::types qw($job_type $job_result);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ' [type: ' . $self->{result_values}->{type}  . ']';
}

sub custom_long_output {
    my ($self, %options) = @_;

    return 'started since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_long_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{is_running} = $options{new_datas}->{$self->{instance} . '_is_running'};
    $self->{result_values}->{is_continuous} = $options{new_datas}->{$self->{instance} . '_is_continuous'};

    return -11 if ($self->{result_values}->{is_running} != 1);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'job', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', skipped_code => { -11 => 1, -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'jobs.detected.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'status' }, { name => 'display' },
                    { name => 'type' }, { name => 'is_running' },
                    { name => 'is_continuous' }, { name => 'scheduled' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [
                    { name => 'status' }, { name => 'display' },
                    { name => 'elapsed' }, { name => 'type' },
                    { name => 'is_running' }, { name => 'is_continuous' }
                ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'filter-name:s'       => { name => 'filter_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'filter-type:s'       => { name => 'filter_type' },
        'filter-end-time:s'   => { name => 'filter_end_time', default => 86400 },
        'filter-start-time:s' => { name => 'filter_start_time' },
        'ok-status:s'         => { name => 'ok_status', default => '' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{is_running} == 0 and not %{status} =~ /success/i' },
        'warning-long:s'      => { name => 'warning_long' },
        'critical-long:s'     => { name => 'critical_long' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['ok_status', 'warning_status', 'critical_status', 'warning_long', 'critical_long']);
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Job '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::veeam::jobstatus::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell(
        label => 'jobstatus',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{jobstatus}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{jobstatus}->{stdout}));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  { "name": "backup 1", "type": 0, "isRunning": false, "scheduled": true, "isContinuous": 0, "sessions": { "result": 0, "creationTimeUTC": 1512875246.2, "endTimeUTC": 1512883615.377 } },
    #  { "name": "backup 2", "type": 0, "isRunning": false, "scheduled": true, "isContinuous": 0, "sessions": { "result": -10, "creationTimeUTC": "", "endTimeUTC": "" } },
    #  { "name": "backup 3", "type": 1, "isRunning": true, "scheduled": true, "isContinuous": 0, "sessions": { "result": 0, "creationTimeUTC": 1513060425.027, "endTimeUTC": -2208992400 } }
    #]

    $self->{global} = { total => 0 };
    $self->{job} = {};
    my $current_time = time();
    foreach my $job (@$decoded) {
        my $sessions = ref($job->{sessions}) eq 'ARRAY' ? $job->{sessions} : [ $job->{sessions} ];
        my $session = $sessions->[0];
        if ($job->{isContinuous} == 1 && defined($sessions->[1])) {
            $session = $sessions->[1];
        }

        $session->{creationTimeUTC} =~ s/,/\./;
        $session->{endTimeUTC} =~ s/,/\./;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $job->{name} =~ /$self->{option_results}->{exclude_name}/);

        my $job_type = defined($job_type->{ $job->{type} }) ? $job_type->{ $job->{type} } : 'unknown';
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job_type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            $session->{endTimeUTC} =~ /[0-9]+/ && $session->{endTimeUTC} > 0 && $session->{endTimeUTC} < $current_time - $self->{option_results}->{filter_end_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            $session->{creationTimeUTC} =~ /[0-9]+/ && $session->{creationTimeUTC} < $current_time - $self->{option_results}->{filter_start_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': start time too old.", debug => 1);
            next;
        }

        my $elapsed_time;
        $elapsed_time = $current_time - $session->{creationTimeUTC} if ($session->{creationTimeUTC} =~ /[0-9]/);

        #is_running = 2 (never running)
        $self->{job}->{ $job->{name} } = {
            display => $job->{name},
            elapsed => $elapsed_time,
            type => $job_type,
            is_continuous => $job->{isContinuous},
            is_running => $job->{isRunning} =~ /True|1/ ? 1 : ($session->{creationTimeUTC} !~ /[0-9]/ ? 2 : 0),
            scheduled => $job->{scheduled} =~ /True|1/i ? 1 : 0, 
            status => defined($job_result->{ $session->{result} }) && $job_result->{ $session->{result} } ne '' ?
                $job_result->{ $session->{result} } : '-'
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

[EXPERIMENTAL] Monitor job status.

=over 8


=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--exclude-name>

Exclude job name (regexp can be used).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (Default: 86400).

=item B<--ok-status>

Set ok threshold for status.
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}, %{scheduled}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}, %{scheduled}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{is_running} == 0 and not %{status} =~ /Success/i').
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}, %{scheduled}.

=item B<--warning-long>

Set warning threshold for long jobs.
Can used special variables like:  %{display}, %{status}, %{type}, %{elapsed}.

=item B<--critical-long>

Set critical threshold for long jobs.
Can used special variables like:  %{display}, %{status}, %{type}, %{elapsed}.

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
