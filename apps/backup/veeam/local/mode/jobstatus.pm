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

package apps::backup::veeam::local::mode::jobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::jobstatus;
use apps::backup::veeam::local::mode::resources::types qw($job_type $job_result);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status} . ' [type: ' . $self->{result_values}->{type}  . ']';
}

sub custom_long_output {
    my ($self, %options) = @_;

    return 'started since : ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_long_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{is_running} = $options{new_datas}->{$self->{instance} . '_is_running'};

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
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Jobs : %s',
                perfdatas => [
                    { label => 'total', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'type' }, { name => 'is_running' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'elapsed' }, { name => 'type' }, { name => 'is_running' } ],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'           => { name => 'timeout', default => 50 },
        'command:s'           => { name => 'command', default => 'powershell.exe' },
        'command-path:s'      => { name => 'command_path' },
        'command-options:s'   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'               => { name => 'no_ps' },
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'filter-name:s'       => { name => 'filter_name' },
        'filter-type:s'       => { name => 'filter_type' },
        'filter-end-time:s'   => { name => 'filter_end_time', default => 86400 },
        'filter-start-time:s' => { name => 'filter_start_time' },
        'ok-status:s'         => { name => 'ok_status', default => '' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{is_running} == 0 and not %{status} =~ /Success/i' },
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

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::veeam::jobstatus::get_powershell();
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  { name: 'xxxx', type: 0, isRunning: False, result: 0, creationTimeUTC: 1512875246.2, endTimeUTC: 1512883615.377 },
    #  { name: 'xxxx', type: 0, isRunning: False, result: 1, creationTimeUTC: '', endTimeUTC: '' },
    #  { name: 'xxxx', type: 1, isRunning: True, result: 0, creationTimeUTC: 1513060425.027, endTimeUTC: -2208992400 }
    #]

    $self->{global} = { total => 0 };
    $self->{job} = {};
    my $current_time = time();
    foreach my $job (@$decoded) {
        $job->{creationTimeUTC} =~ s/,/\./;
        $job->{endTimeUTC} =~ s/,/\./;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job_type->{ $job->{type} } !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            $job->{endTimeUTC} =~ /[0-9]+/ && $job->{endTimeUTC} < $current_time - $self->{option_results}->{filter_end_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            $job->{creationTimeUTC} =~ /[0-9]+/ && $job->{creationTimeUTC} < $current_time - $self->{option_results}->{filter_start_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': start time too old.", debug => 1);
            next;
        }

        my $elapsed_time;
        $elapsed_time = $current_time - $job->{creationTimeUTC} if ($job->{creationTimeUTC} =~ /[0-9]/);

        #is_running = 2 (never running)
        $self->{job}->{ $job->{name} } = {
            display => $job->{name},
            elapsed => $elapsed_time,
            type => $job_type->{ $job->{type} },
            is_running => $job->{isRunning} =~ /True|1/ ? 1 : ($job->{creationTimeUTC} !~ /[0-9]/ ? 2 : 0),
            status => defined($job_result->{ $job->{result} }) && $job_result->{ $job->{result} } ne '' ?
                $job_result->{ $job->{result} } : '-'
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check job status.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (Default: 86400).

=item B<--ok-status>

Set ok threshold for status (Default: '')
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}.

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{is_running} == 0 and not %{status} =~ /Success/i').
Can used special variables like: %{display}, %{status}, %{type}, %{is_running}.

=item B<--warning-long>

Set warning threshold for long jobs (Default: none)
Can used special variables like:  %{display}, %{status}, %{type}, %{elapsed}.

=item B<--critical-long>

Set critical threshold for long jobs (Default: none).
Can used special variables like:  %{display}, %{status}, %{type}, %{elapsed}.

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
