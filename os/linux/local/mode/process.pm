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

package os::linux::local::mode::process;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %state_map = (
    Z => 'zombie',
    X => 'dead',
    W => 'paging',
    T => 'stopped',
    S => 'InterrupibleSleep',
    R => 'running',
    D => 'UninterrupibleSleep'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'ps' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-e -o etime,pid,ppid,state,comm,args -w 2>&1' },
                                  "warning:s"           => { name => 'warning' },
                                  "critical:s"          => { name => 'critical' },
                                  "warning-time:s"      => { name => 'warning_time' },
                                  "critical-time:s"     => { name => 'critical_time' },
                                  "filter-command:s"    => { name => 'filter_command' },
                                  "filter-arg:s"        => { name => 'filter_arg' },
                                  "filter-state:s"      => { name => 'filter_state' },
                                });
    $self->{result} = {};
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
    if (($self->{perfdata}->threshold_validate(label => 'warning-time', value => $self->{option_results}->{warning_time})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-time threshold '" . $self->{option_results}->{warning_time} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-time', value => $self->{option_results}->{critical_time})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-time threshold '" . $self->{option_results}->{critical_time} . "'.");
       $self->{output}->option_exit();
    }
}

sub parse_output {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    my @lines = split /\n/, $stdout;
    # Header to manage output
    #    ELAPSED   PID  PPID S COMMAND         COMMAND
    my $line = shift @lines;
    $line =~ /^(\s*?\S+\s*?\S+\s*?\S+\s*?\S+\s*?)(\S+\s*?)\S+/;
    my ($pos1, $pos2) = (length($1), length($1) + length($2));
    foreach my $line (@lines) {
        $line =~ /^(\s*?\S+\s*?)(\S+\s*?)(\S+\s*?)(\S+\s*?)/;
        my ($elapsed, $pid, $ppid, $state) = ($1, $2, $3, $4);
        my $cmd = substr($line, $pos1, $pos2 - $pos1);
        my $args = substr($line, $pos2);
        
        $self->{result}->{centreon::plugins::misc::trim($pid)} = {ppid => centreon::plugins::misc::trim($ppid), 
                                                                  state => centreon::plugins::misc::trim($state),
                                                                  elapsed => centreon::plugins::misc::trim($elapsed), 
                                                                  cmd => centreon::plugins::misc::trim($cmd), 
                                                                  args => centreon::plugins::misc::trim($args)};
    }
}

sub check_time {
    my ($self, %options) = @_;
    
    my $time = $self->{result}->{$options{pid}}->{elapsed};
    # Format: [[dd-]hh:]mm:ss
    my @values = split /:/, $time;
    my ($seconds, $min, $lpart) = (pop @values, pop @values, pop @values);
    my $total_seconds_elapsed = $seconds + ($min * 60);
    if (defined($lpart)) {
        my ($day, $hour) = split /-/, $lpart;
        if (defined($hour)) {
            $total_seconds_elapsed += ($hour * 60 * 60);
        }
        if (defined($day)) {
            $total_seconds_elapsed += ($day * 86400);
        }
    }

    my $exit = $self->{perfdata}->threshold_check(value => $total_seconds_elapsed, threshold => [ { label => 'critical-time', 'exit_litteral' => 'critical' }, { label => 'warning-time', exit_litteral => 'warning' } ]);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Time issue for process " . $self->{result}->{$options{pid}}->{cmd});
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->parse_output();
    
    my $num_processes_match = 0;
    foreach my $pid (keys %{$self->{result}}) {
        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
                 $self->{result}->{$pid}->{cmd} !~ /$self->{option_results}->{filter_command}/);
        next if (defined($self->{option_results}->{filter_arg}) && $self->{option_results}->{filter_arg} ne '' &&
                 $self->{result}->{$pid}->{args} !~ /$self->{option_results}->{filter_arg}/);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                 $state_map{$self->{result}->{$pid}->{state}} !~ /$self->{option_results}->{filter_state}/i);

        $self->{output}->output_add(long_msg => 'Process: [command => ' . $self->{result}->{$pid}->{cmd} . 
                                                          '] [arg => ' . $self->{result}->{$pid}->{args} .
                                                          '] [state => ' . $state_map{$self->{result}->{$pid}->{state}} . ']');
        $self->check_time(pid => $pid);
        $num_processes_match++;
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $num_processes_match, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => "Number of current processes: $num_processes_match");
    $self->{output}->perfdata_add(label => 'nbproc',
                                  value => $num_processes_match,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check linux processes.
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

Command options (Default: '-e -o etime,pid,ppid,state,comm,args -w 2>&1').

=item B<--warning>

Threshold warning (in absolute of processes count. After filters).

=item B<--critical>

Threshold critical (in absolute of processes count. After filters).

=item B<--warning-time>

Threshold warning (in seconds).
On each processes filtered.

=item B<--critical-time>

Threshold critical (in seconds).
On each processes filtered.

=item B<--filter-command>

Filter process commands (regexp can be used).

=item B<--filter-arg>

Filter process arguments (regexp can be used).

=item B<--filter-state>

Filter process states (regexp can be used).
You can use: 'zombie', 'dead', 'paging', 'stopped',
'InterrupibleSleep', 'running', 'UninterrupibleSleep'.

=back

=cut