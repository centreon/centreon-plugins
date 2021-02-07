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

package apps::backup::quadstor::local::mode::vtljobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'status : ' . $self->{result_values}->{status};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_long_output {
    my ($self, %options) = @_;
    my $msg = 'elapsed time : ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});

    return $msg;
}

sub custom_long_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    
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
    my $msg = 'frozen : no';

    if (!$self->{output}->is_status(value => $self->{instance_mode}->{last_status_frozen}, compare => 'ok', litteral => 1)) {
        $msg = 'frozen: yes';
    }    
    return $msg;
}

sub custom_frozen_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{kb} = $options{new_datas}->{$self->{instance} . '_kb'} - $options{old_datas}->{$self->{instance} . '_kb'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
       { name => 'jobs', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { label => 'alerts', min => 0 },
          group => [ { name => 'job', cb_prefix_output => 'prefix_job_output', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'elapsed' } ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'frozen', threshold => 0, set => {
                key_values => [ { name => 'kb', diff => 1 }, { name => 'status' }, { name => 'display' }, { name => 'elapsed' } ],
                closure_custom_calc => $self->can('custom_frozen_calc'),
                closure_custom_output => $self->can('custom_frozen_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_frozen_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'impexp' },
                                  "command-path:s"    => { name => 'command_path', default => '/quadstorvtl/bin' },
                                  "command-options:s" => { name => 'command_options', default => '-l' },
                                  "warning-status:s"        => { name => 'warning_status' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /error/i' },
                                  "warning-long:s"          => { name => 'warning_long' },
                                  "critical-long:s"         => { name => 'critical_long' },
                                  "warning-frozen:s"        => { name => 'warning_frozen' },
                                  "critical-frozen:s"       => { name => 'critical_frozen' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'warning_long', 'critical_long', 'warning_frozen', 'critical_frozen']);
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "job '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "quadstor_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    my ($stdout) = centreon::plugins::misc::execute(output => $self->{output},
                                                    options => $self->{option_results},
                                                    sudo => $self->{option_results}->{sudo},
                                                    command => $self->{option_results}->{command},
                                                    command_path => $self->{option_results}->{command_path},
                                                    command_options => $self->{option_results}->{command_options});    
    $self->{jobs}->{global} = { job => {} };
    #JobID  Type     Source           State        Transfer       Elapsed
    #252    Import   701831L2         Error        36.00 GB       572
    #253    Export   701849L2         Completed    19.43 GB       262
    #254    Export   701850L2         Completed    16.05 GB       1072
    #255    Export   701854L2         Completed    6.31 GB        142
    my $current_time = time();
    my @lines = split /\n/, $stdout;
    shift @lines;
    foreach (@lines) {
        next if (! /^(\d+)\s+\S+\s+(\S+)\s+(\S+)\s+([0-9\.]+)\s+\S+\s+(\d+)/);
        
        my ($job_id, $job_source, $job_state, $job_kb, $job_elapsed) = 
            ($1, $2, $3, $4, $5);
        
        my $name = $job_source . '.' . $job_id;
        $self->{jobs}->{global}->{job}->{$name} = { 
            display => $name,
            status => $job_state,
            kb => $job_kb * 1024,
            elapsed => $job_elapsed
        };
    }
    
    if (scalar(keys %{$self->{jobs}->{global}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No job found.");
        $self->{output}->option_exit();
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

Command to get information (Default: 'impexp').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/quadstorvtl/bin').

=item B<--command-options>

Command options (Default: '-l').

=item B<--warning-status>

Set warning threshold for status (Default: none)
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error/i').
Can used special variables like: %{display}, %{status}

=item B<--warning-long>

Set warning threshold for long jobs (Default: none)
Can used special variables like: %{display}, %{status}, %{elapsed}

=item B<--critical-long>

Set critical threshold for long jobs (Default: none).
Can used special variables like: %{display}, %{status}, %{elapsed}

=item B<--warning-frozen>

Set warning threshold for frozen jobs (Default: none)
Can used special variables like: %{display}, %{status}, %{elapsed}, %{kb}

=item B<--critical-frozen>

Set critical threshold for frozen jobs (Default: none).
Can used special variables like: %{display}, %{status}, %{elapsed}, %{kb}

=back

=cut
