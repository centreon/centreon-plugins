#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package os::aix::local::mode::loadaverage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

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
                                  "command:s"         => { name => 'command', default => 'uptime' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options' },
                                  "warning:s"         => { name => 'warning' },
                                  "critical:s"        => { name => 'critical' },

                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    ($self->{warn1}, $self->{warn5}, $self->{warn15}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1}, $self->{crit5}, $self->{crit15}) = split /,/, $self->{option_results}->{critical};

    if (($self->{perfdata}->threshold_validate(label => 'warn1', value => $self->{warn1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5', value => $self->{warn5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn15', value => $self->{warn15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (15min) threshold '" . $self->{warn15} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1', value => $self->{crit1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5', value => $self->{crit5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit15', value => $self->{crit15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (15min) threshold '" . $self->{crit15} . "'.");
       $self->{output}->option_exit();
    }

}


sub run {
	
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    # Header not needed
    my ($cpu_load1, $cpu_load5, $cpu_load15);
    if ($stdout =~ /([0-9\.]+),\s+([0-9\.]+),\s+([0-9\.]+)$/){
            ($cpu_load1, $cpu_load5, $cpu_load15) = ($1, $2, $3);
        }

    my $msg = sprintf("Load average: %s, %s, %s", $cpu_load1, $cpu_load5, $cpu_load15);
    $self->{output}->perfdata_add(label => 'load1',
                                  value => $cpu_load1,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'load5',
                              value => $cpu_load5,
                              warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5'),
                              critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5'),
                              min => 0);
    $self->{output}->perfdata_add(label => 'load15',
                              value => $cpu_load15,
                              warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15'),
                              critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15'),
                              min => 0);


    my $exit1 = $self->{perfdata}->threshold_check(value => $cpu_load1,
                                                   threshold => [ { label => 'crit1', 'exit_litteral' => 'critical' }, { label => 'warn1', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cpu_load5,
                                                   threshold => [ { label => 'crit5', 'exit_litteral' => 'critical' }, { label => 'warn5', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cpu_load15,
                                                   threshold => [ { label => 'crit15', 'exit_litteral' => 'critical' }, { label => 'warn15', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => $msg);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check swap memory

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

Command to get information (Default: 'lsps').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-s').

=item B<--wanring>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
