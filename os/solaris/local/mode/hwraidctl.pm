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

package os::solaris::local::mode::hwraidctl;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
                                  "command:s"         => { name => 'command', default => 'raidctl' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-S 2>&1' },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
                                });
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
    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);

    my $volumes_errors = 0;
    my $disks_errors = 0;
    my $volumes = '';
    my $disks = '';
    foreach (split(/\n/, $stdout)) {
        #1 "LSI_1030"
        #c1t2d0 2 0.2.0 0.3.0 1 OPTIMAL
        #0.0.0 GOOD
        #0.1.0 GOOD
        #0.2.0 GOOD
        #0.3.0 GOOD
        #4 "LSI_1030"
        
        # For Disk
        if (/^\s*(\S+)\s+(FAILED)$/i ) {
            my $disk = $1;
            
            $disks_errors++;
            $disks .= ' [' . $disk . '/FAILED' . ']';
        } elsif (/^\s*(\S+).*?(DEGRADED|FAILED)$/i) {
            $volumes_errors++;
            $volumes .= ' [' . $1 . '/' . $2 . ']';
        }
    }

    my ($exit_code) = $self->{perfdata}->threshold_check(value => $volumes_errors, 
                                                         threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]); 
    if ($volumes_errors > 0) {
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Some volumes problems:" . $volumes));
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems on volumes");
    }
    
    ($exit_code) = $self->{perfdata}->threshold_check(value => $disks_errors, 
                                                      threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    if ($disks_errors > 0) {
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Some disks problems:" . $disks));
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems on disks");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Hardware Raid Status (use 'raidctl' command).

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'raidctl').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-S 2>&1').

=back

=cut
