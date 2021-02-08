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

package apps::backup::netbackup::local::mode::jobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        # To exclude some OK
        if (defined($self->{instance_mode}->{option_results}->{ok_status}) && $self->{instance_mode}->{option_results}->{ok_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{ok_status}") {
            $status = 'ok';
        } elsif (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'Status : ' . $self->{result_values}->{status};
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub custom_long_output {
    my ($self, %options) = @_;
    
    return 'Started Since: ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});
}

sub custom_long_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};

    return -11 if ($self->{result_values}->{state} !~ /queued|active/);

    return 0;
}

sub custom_frozen_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{instance_mode}->{option_results}->{critical_frozen}) && $self->{instance_mode}->{option_results}->{critical_frozen} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_frozen}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_frozen}) && $self->{instance_mode}->{option_results}->{warning_frozen} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_frozen}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
       $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    $self->{instance_mode}->{last_status_frozen} = $status;
    return $status;
}

sub custom_frozen_output {
    my ($self, %options) = @_;
    my $msg = "Frozen: 'no'";

    if (!$self->{output}->is_status(value => $self->{instance_mode}->{last_status_frozen}, compare => 'ok', litteral => 1)) {
        $msg = "Frozen: 'yes'";
    }    
    return $msg;
}

sub custom_frozen_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{kb} = $options{new_datas}->{$self->{instance} . '_kb'} - $options{old_datas}->{$self->{instance} . '_kb'};
    $self->{result_values}->{parentid} = $options{new_datas}->{$self->{instance} . '_parentid'};
    $self->{result_values}->{schedule} = $options{new_datas}->{$self->{instance} . '_schedule'};
    $self->{result_values}->{jobid} = $options{new_datas}->{$self->{instance} . '_jobid'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'policy', type => 2, cb_prefix_output => 'prefix_policy_output', cb_long_output => 'policy_long_output',
          message_multiple => 'All policies are ok',
          group => [ { name => 'job', cb_prefix_output => 'prefix_job_output', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Jobs : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'type' }, { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'elapsed' }, { name => 'type' },
                    { name => 'state' } ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'frozen', threshold => 0, set => {
                key_values => [ { name => 'kb', diff => 1 }, { name => 'status' }, 
                    { name => 'display' }, { name => 'elapsed' }, { name => 'type' }, { name => 'state' },
                    { name => 'parentid' }, { name => 'schedule' }, { name => 'jobid' } ],
                closure_custom_calc => $self->can('custom_frozen_calc'),
                closure_custom_output => $self->can('custom_frozen_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_frozen_threshold'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'hostname:s'              => { name => 'hostname' },
        'remote'                  => { name => 'remote' },
        'ssh-option:s@'           => { name => 'ssh_option' },
        'ssh-path:s'              => { name => 'ssh_path' },
        'ssh-command:s'           => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'               => { name => 'timeout', default => 30 },
        'sudo'                    => { name => 'sudo' },
        'command:s'               => { name => 'command', default => 'bpdbjobs' },
        'command-path:s'          => { name => 'command_path' },
        'command-options:s'       => { name => 'command_options', default => '-report -most_columns' },
        'exec-only'               => { name => 'exec_only' },
        'filter-policy-name:s'    => { name => 'filter_policy_name' },
        'filter-type:s'           => { name => 'filter_type' },
        'filter-end-time:s'       => { name => 'filter_end_time', default => 86400 },
        'filter-start-time:s'     => { name => 'filter_start_time' },
        'ok-status:s'             => { name => 'ok_status', default => '%{status} == 0' },
        'warning-status:s'        => { name => 'warning_status', default => '%{status} == 1' },
        'critical-status:s'       => { name => 'critical_status', default => '%{status} > 1' },
        'warning-long:s'          => { name => 'warning_long' },
        'critical-long:s'         => { name => 'critical_long' },
        'warning-frozen:s'        => { name => 'warning_frozen' },
        'critical-frozen:s'       => { name => 'critical_frozen', default => '%{state} =~ /active|queue/ && %{kb} == 0' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'ok_status', 'warning_status', 'critical_status', 'warning_long', 
        'critical_long', 'warning_frozen', 'critical_frozen']
    );
}

sub policy_long_output {
    my ($self, %options) = @_;

    return "Checking policy '" . $options{instance_value}->{display} . "'";
}

sub prefix_policy_output {
    my ($self, %options) = @_;

    return "Policy '" . $options{instance_value}->{display} . "' ";
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "Job '" . $options{instance_value}->{display} . "' [Type: " . $options{instance_value}->{type} . "] [State: " . $options{instance_value}->{state} . "] " ;
}

my %job_type = (
    0 => 'backup', 1 => 'archive', 2 => 'restore', 3 => 'verify', 4 => 'duplicate', 5 => 'phase 1 or phase 2 import',
    6 => 'catalog backup', 7 => 'vault duplicate', 8 => 'label tape', 9 => 'erase tape',
    10 => 'tape request', 11 => 'clean tape', 12 => 'format tape', 13 => 'physical inventory of robotic library', 
    14 => 'qualification test of drive or robotic library', 15 => 'catalog recovery', 16 => 'media contents', 
    17 => 'image cleanup', 18 => 'LiveUpdate', 20 => 'Replication (Auto Image Replication)', 21 => 'Import (Auto Image Replication)',
    22 => 'backup From Snapshot', 23 => 'Replication (snap)', 24 => 'Import (snap)', 25 => 'application state capture', 
    26 => 'indexing', 27 => 'index cleanup', 28 => 'Snapshot',
    29 => 'SnapIndex', 30 => 'ActivateInstantRecovery', 31 => 'DeactivateInstantRecovery',
    32 => 'ReactivateInstantRecovery', 33 => 'StopInstantRecovery', 34 => 'InstantRecovery',
);

my %job_state = (
    0 => 'queued and awaiting resources', 
    1 => 'active', 
    2 => 'requeued and awaiting resources', 
    3 => 'done', 4 => 'suspended', 5 => 'incomplete',
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "netbackup_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_policy_name}) ? md5_hex($self->{option_results}->{filter_policy_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_start_time}) ? md5_hex($self->{option_results}->{filter_start_time}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{job_end_time}) ? md5_hex($self->{option_results}->{job_end_time}) : md5_hex('all'));
    
    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    if (defined($self->{option_results}->{exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    $self->{global} = { total => 0 };
    $self->{policy} = {};
    my $current_time = time();
    foreach my $line (split /\n/, $stdout) {
        my @values = split /,/, $line;
        my ($job_id, $job_type, $job_state, $job_status, $job_pname, $job_schedule, $job_start_time, $job_end_time, $job_kb, $job_parentid) = 
            ($values[0], $values[1], $values[2], $values[3], $values[4], $values[5], $values[8], $values[10], $values[14], $values[33]);

        $job_pname = defined($job_pname) && $job_pname ne '' ? $job_pname : 'unknown';
        $job_status = defined($job_status) && $job_status =~ /[0-9]/ ? $job_status : -1;
        # when the job is running, end_time = 000000
        $job_end_time = undef if (defined($job_end_time) && int($job_end_time) == 0);
        if (defined($self->{option_results}->{filter_policy_name}) && $self->{option_results}->{filter_policy_name} ne '' &&
            $job_pname !~ /$self->{option_results}->{filter_policy_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job_pname . "/" . $job_id . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job_type{$job_type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job_pname . "/" . $job_id . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            defined($job_end_time) && $job_end_time =~ /[0-9]+/ && $job_end_time < $current_time - $self->{option_results}->{filter_end_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job_pname . "/" . $job_id . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            defined($job_start_time) && $job_start_time =~ /[0-9]+/ && $job_start_time < $current_time - $self->{option_results}->{filter_start_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job_pname . "/" . $job_id . "': start time too old.", debug => 1);
            next;
        }

        $self->{policy}->{$job_pname} = { job => {}, display => $job_pname } if (!defined($self->{policy}->{$job_pname}));
        my $elapsed_time = $current_time - $job_start_time;
        $self->{policy}->{$job_pname}->{job}->{$job_id} = {
            display => $job_id,
            elapsed => $elapsed_time, 
            status => $job_status,
            state => $job_state{$job_state},
            type => $job_type{$job_type},
            kb => defined($job_kb) && $job_kb =~ /[0-9]+/ ? $job_kb : '0',
            parentid => defined($job_parentid) ? $job_parentid : '',
            jobid => $job_id,
            schedule => defined($job_schedule) ? $job_schedule : '',
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check job status.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'bpdbjobs').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-report -most_columns').

=item B<--exec-only>

Print command output

=item B<--filter-policy-name>

Filter job policy name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (Default: 86400).

=item B<--ok-status>

Set ok threshold for status (Default: '%{status} == 0')
Can used special variables like: %{display}, %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} == 1')
Can used special variables like: %{display}, %{status}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} > 1').
Can used special variables like: %{display}, %{status}, %{type}

=item B<--warning-long>

Set warning threshold for long jobs (Default: none)
Can used special variables like: %{display}, %{status}, %{elapsed}, %{type}

=item B<--critical-long>

Set critical threshold for long jobs (Default: none).
Can used special variables like: %{display}, %{status}, %{elapsed}, %{type}

=item B<--warning-frozen>

Set warning threshold for frozen jobs (Default: none)
Can used special variables like:
%{display}, %{status}, %{elapsed}, %{type}, %{kb}, %{parentid}, %{schedule}, %{jobid}

=item B<--critical-frozen>

Set critical threshold for frozen jobs (Default: '%{state} =~ /active|queue/ && %{kb} == 0').
Can used special variables like: 
%{display}, %{status}, %{elapsed}, %{type}, %{kb}, %{parentid}, %{schedule}, %{jobid}

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
