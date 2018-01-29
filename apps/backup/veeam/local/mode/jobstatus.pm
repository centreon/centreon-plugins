#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
use centreon::plugins::misc;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        # To exclude some OK
        if (defined($instance_mode->{option_results}->{ok_status}) && $instance_mode->{option_results}->{ok_status} ne '' &&
            eval "$instance_mode->{option_results}->{ok_status}") {
            $status = 'ok';
        } elsif (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
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
    my $msg = 'status : ' . $self->{result_values}->{status} . ' [type: ' . $self->{result_values}->{type}  . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{is_running} = $options{new_datas}->{$self->{instance} . '_is_running'};
    return 0;
}

sub custom_long_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_long}) && $instance_mode->{option_results}->{critical_long} ne '' &&
            eval "$instance_mode->{option_results}->{critical_long}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_long}) && $instance_mode->{option_results}->{warning_long} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_long}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_long_output {
    my ($self, %options) = @_;
    my $msg = 'started since : ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});

    return $msg;
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
        { name => 'job', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', skipped_code => { -11 => 1, -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Jobs : %s',
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'type' }, { name => 'is_running' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'elapsed' }, { name => 'type' }, { name => 'is_running' } ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_long_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "no-ps"               => { name => 'no_ps' },
                                  "ps-exec-only"        => { name => 'ps_exec_only' },
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "filter-type:s"           => { name => 'filter_type' },
                                  "filter-end-time:s"       => { name => 'filter_end_time', default => 86400 },
                                  "filter-start-time:s"     => { name => 'filter_start_time' },
                                  "ok-status:s"             => { name => 'ok_status', default => '' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{is_running} == 0 and not %{status} =~ /Success/i' },
                                  "warning-long:s"          => { name => 'warning_long' },
                                  "critical-long:s"         => { name => 'critical_long' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "Job '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('ok_status', 'warning_status', 'critical_status', 'warning_long', 'critical_long')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::veeam::jobstatus::get_powershell(
        no_ps => $self->{option_results}->{no_ps});

    $self->{option_results}->{command_options} .= " " . $ps;
    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    
    #[name = xxxx ][type = Backup ][isrunning = False ][result = Success ][creationTimeUTC =  1512875246.2 ][endTimeUTC =  1512883615.377 ]
    #[name = xxxx ][type = Backup ][isrunning = False ][result = ][creationTimeUTC = ][endTimeUTC = ]
    #[name = xxxx ][type = BackupSync ][isrunning = True ][result =  None ][creationTimeUTC =  1513060425.027 ][endTimeUTC = -2208992400 ]

    #is_running = 2 (never running)
    $self->{global} = { total => 0 };
    $self->{job} = {};
    my $current_time = time();
    foreach my $line (split /\n/, $stdout) {
        next if ($line !~ /^\[name\s*=(.*?)\]\[type\s*=(.*?)\]\[isrunning\s*=(.*?)\]\[result\s*=(.*?)\]\[creationTimeUTC\s*=(.*?)\]\[endTimeUTC\s*=(.*?)\]/i);
        
        my ($name, $type, $is_running, $result, $start_time, $end_time) = (centreon::plugins::misc::trim($1), 
            centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), 
            centreon::plugins::misc::trim($5), centreon::plugins::misc::trim($6));
        $start_time =~ s/,/\./;
        $end_time =~ s/,/\./;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $name . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            defined($end_time) && $end_time =~ /[0-9]+/ && $end_time < $current_time - $self->{option_results}->{filter_end_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $name . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            defined($start_time) && $start_time =~ /[0-9]+/ && $start_time < $current_time - $self->{option_results}->{filter_start_time}) {
            $self->{output}->output_add(long_msg => "skipping job '" . $name . "': start time too old.", debug => 1);
            next;
        }
        
        my $elapsed_time;
        $elapsed_time = $current_time - $start_time if ($start_time =~ /[0-9]/);
        $self->{job}->{$name} = {
            display => $name,
            elapsed => $elapsed_time,
            type => $type,
            is_running => ($is_running =~ /True/) ? 1 : ($start_time !~ /[0-9]/ ? 2 : 0),
            status => $result ne '' ? $result : '-',
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
