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

package os::aix::local::mode::swap;

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
                                  "command:s"         => { name => 'command', default => 'lsps' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-s' },
                                  "warning:s"         => { name => 'warning' },
                                  "critical:s"        => { name => 'critical' },

                                });
#    $self->{result} = {};
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
}


sub run {
	
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    my ($pgSize, $prct_used);
    foreach my $line (@lines) {
        next if ($line !~ /(\d+)MB\s+(\d+)\.*/);
            ($pgSize, $prct_used) = ($1, $2);
        }

    my $swapSize = $pgSize * 1024 * 1024;
    
    my $swapUsed = $swapSize * $prct_used / 100;
    my $swapFree = $swapSize - $swapUsed;
    my $prct_free = 100 - $prct_used;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($swapSize_value, $swapSize_unit) = $self->{perfdata}->change_bytes(value => $swapSize);
    my ($swapUsed_value, $swapUsed_unit) = $self->{perfdata}->change_bytes(value => $swapUsed);
    my ($swapFree_value, $swapFree_unit) = $self->{perfdata}->change_bytes(value => $swapFree);


    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf 'Swap Total: %s, Used: %s (%.2f%%), Free: %s (%.2f%%)',
                                             $swapSize_value . " " . $swapSize_unit,
                                             $swapUsed_value . " " . $swapUsed_unit, $prct_used,
                                             $swapFree_value . " " . $swapFree_unit, $prct_free);

    $self->{output}->perfdata_add(label => 'used', unit => 'B',
                                  value => sprintf('%d',$swapUsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => $swapSize);
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
