#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package os::aix::local::mode::process;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('Process [command => %s] [arg: %s] [state: %s] [elapsed => %s]', 
        $self->{result_values}->{cmd},
        $self->{result_values}->{args},
        $self->{result_values}->{state}, 
        $self->{result_values}->{elapsed}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'alarms', type => 2, message_multiple => '0 process problem detected', format_output => '%s process(es) problem(s) detected', 
          display_counter_problem => { nlabel => 'processes.alerts.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'processes.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of current processes: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ppid' }, { name => 'state' },
                    { name => 'elapsed' }, { name => 'cmd' }, { name => 'args' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname' },
        'remote'            => { name => 'remote' },
        'ssh-option:s@'     => { name => 'ssh_option' },
        'ssh-path:s'        => { name => 'ssh_path' },
        'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'sudo'              => { name => 'sudo' },
        'command:s'         => { name => 'command', default => 'ps' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a 2>&1' },
        'filter-command:s'  => { name => 'filter_command' },
        'filter-arg:s'      => { name => 'filter_arg' },
        'filter-state:s'    => { name => 'filter_state' },
        'filter-ppid:s'	    => { name => 'filter_ppid' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %state_map = (
    Z => 'Canceled',
    O => 'Nonexistent',
    A => 'Active',
    W => 'Swapped',
    I => 'Idle',
    T => 'Stopped',
    R => 'Running',
    S => 'Sleeping',
);

sub get_time_seconds {
    my ($self, %options) = @_;

    my $time = $options{value};
    # Format: [[dd-]hh:]mm:ss
    my @values = split /:/, $time;
    my ($seconds, $min, $lpart) = (pop @values, pop @values, pop @values);
    my $total_seconds_elapsed = $seconds + ($min * 60);
    if (defined($lpart)) {
        my ($day, $hour) = split /-/, $lpart;
        if (!defined($hour)) {
            $hour = $day;
            $day = undef;
        }
        if (defined($hour)) {
            $total_seconds_elapsed += ($hour * 60 * 60);
        }
        if (defined($day)) {
            $total_seconds_elapsed += ($day * 86400);
        }
    }

    return $total_seconds_elapsed;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    $self->{alarms}->{global} = { alarm => {} };
    my @lines = split /\n/, $stdout;
    my $line = shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(.*?)===(.*?)===(.*?)===(.*?)===(.*?)===(.*)$/);
        my ($state, $elapsed, $pid, $ppid, $cmd, $args) = (
            centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3),
            centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5), centreon::plugins::misc::trim($6)
        );

        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
                 $cmd !~ /$self->{option_results}->{filter_command}/);
        next if (defined($self->{option_results}->{filter_arg}) && $self->{option_results}->{filter_arg} ne '' &&
                 $args !~ /$self->{option_results}->{filter_arg}/);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                 $state_map{$state} !~ /$self->{option_results}->{filter_state}/i);
        next if (defined($self->{option_results}->{filter_ppid}) && $self->{option_results}->{filter_ppid} ne '' &&
                 $ppid !~ /$self->{option_results}->{filter_ppid}/);

        $self->{alarms}->{global}->{alarm}->{$pid} = {
            ppid => $ppid, 
            state => $state_map{$state},
            elapsed => $self->get_time_seconds(value => $elapsed), 
            cmd => $cmd,
            args => $args
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{alarms}->{global}->{alarm}}) };
}

1;

__END__

=head1 MODE

Check AIX processes.
Can filter on commands, arguments and states.

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

Command to get information (Default: 'ps').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a 2>&1').

=item B<--filter-command>

Filter process commands (regexp can be used).

=item B<--filter-arg>

Filter process arguments (regexp can be used).

=item B<--filter-ppid>

Filter process ppid (regexp can be used).

=item B<--filter-state>

Filter process states (regexp can be used).
You can use: 'Canceled', 'Nonexistent', 'Active',
'Swapped', 'Idle', 'Stopped', 'Running', 'Sleeping'.

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{ppid}, %{state}, %{elapsed}, %{cmd}, %{args}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{ppid}, %{state}, %{elapsed}, %{cmd}, %{args}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be: 'total'.

=back

=cut
