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

package apps::backup::backupexec::local::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::backupexec::jobs;
use apps::backup::backupexec::local::mode::resources::types qw($job_status $job_substatus $job_type);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [substatus: %s] [type: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{subStatus},
        $self->{result_values}->{type}
    );
}

sub custom_long_output {
    my ($self, %options) = @_;

    return 'started since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_long_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{subStatus} = $options{new_datas}->{$self->{instance} . '_subStatus'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{isActive} = $options{new_datas}->{$self->{instance} . '_isActive'};

    return -11 if ($self->{result_values}->{isActive} != 1);

    return 0;
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Job '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', skipped_code => { -11 => 1, -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'jobs.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'Jobs detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'status', type => 2, critical_default => 'not %{status} =~ /succeeded/i', set => {
                key_values => [
                    { name => 'name' }, { name => 'type' },
                    { name => 'status' }, { name => 'subStatus' },
                    { name => 'isActive' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'long', type => 2, set => {
                key_values => [
                    { name => 'name' }, { name => 'type' },
                    { name => 'status' }, { name => 'subStatus' },
                    { name => 'elapsed' }, { name => 'isActive' }
                ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
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
        'timeout:s'           => { name => 'timeout', default => 50 },
        'command:s'           => { name => 'command' },
        'command-path:s'      => { name => 'command_path' },
        'command-options:s'   => { name => 'command_options' },
        'no-ps'               => { name => 'no_ps' },
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'bemcli-file'         => { name => 'bemcli_file' },
        'filter-name:s'       => { name => 'filter_name' },
        'filter-type:s'       => { name => 'filter_type' },
        'filter-end-time:s'   => { name => 'filter_end_time', default => 86400 },
        'filter-start-time:s' => { name => 'filter_start_time' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::backupexec::jobs::get_powershell(
            bemcli_file => $self->{option_results}->{bemcli_file}
        );
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
    #  { "name": "backup 1", "type": 1, "status": 9, "subStatus": 0, "isActive": false, "creationTimeUTC": 1512875246.2, "endTimeUTC": 1512883615.377, "elapsedTime": 120 },
    #  { "name": "backup 2", "type": 2, "status": 0, "subStatus": 1, "isActive": true, "creationTimeUTC": "1512875246.2", "endTimeUTC": "", "elapsedTime": 10000 }
    #]

    $self->{global} = { detected => 0 };
    $self->{jobs} = {};
    my $current_time = time();
    foreach my $job (@$decoded) {
        $job->{creationTimeUTC} =~ s/,/\./;
        $job->{endTimeUTC} =~ s/,/\./;

        my $job_type = defined($job_type->{ $job->{type} }) ? $job_type->{ $job->{type} } : 'unknown';
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job_type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            $job->{endTimeUTC} =~ /[0-9]+/ && $job->{endTimeUTC} > 0 && $job->{endTimeUTC} < $current_time - $self->{option_results}->{filter_end_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            $job->{creationTimeUTC} =~ /[0-9]+/ && $job->{creationTimeUTC} < $current_time - $self->{option_results}->{filter_start_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': start time too old.", debug => 1);
            next;
        }

        #isActive = 2 (never running)
        $self->{jobs}->{ $job->{name} } = {
            name => $job->{name},
            elapsed => $job->{elapsedTime},
            type => $job_type,
            isActive => $job->{isActive} =~ /True|1/i ? 1 : ($job->{creationTimeUTC} !~ /[0-9]/ ? 2 : 0),
            status => defined($job_status->{ $job->{status} }) ? $job_status->{ $job->{status} } : '-',
            subStatus => defined($job_substatus->{ $job->{subStatus} }) ? $job_substatus->{ $job->{subStatus} } : '-'
        };
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--timeout>

Set timeout time for command execution (default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--bemcli-file>

Set powershell module file (default: 'C:/Program Files/Veritas/Backup Exec/Modules/BEMCLI/bemcli').

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (default: 86400).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{status}, %{subStatus}, %{type}, %{isActive}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: 'not %{status} =~ /succeeded/i').
You can use the following variables: %{name}, %{status}, %{subStatus}, %{type}, %{isActive}.

=item B<--warning-long>

Set warning threshold for long jobs.
You can use the following variables: %{name}, %{status}, %{subStatus}, %{type}, %{isActive}, %{elapsed}.

=item B<--critical-long>

Set critical threshold for long jobs.
You can use the following variables: %{name}, %{status}, %{subStatus}, %{type}, %{isActive}, %{elapsed}.

=item B<--warning-detected>

Set warning threshold for detected jobs.

=item B<--critical-detected>

Set critical threshold for detected jobs.

=back

=cut
