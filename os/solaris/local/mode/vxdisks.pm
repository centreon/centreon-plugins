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

package os::solaris::local::mode::vxdisks;

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
                                  "hostname:s"         => { name => 'hostname' },
                                  "remote"             => { name => 'remote' },
                                  "ssh-option:s@"      => { name => 'ssh_option' },
                                  "ssh-path:s"         => { name => 'ssh_path' },
                                  "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"          => { name => 'timeout', default => 30 },
                                  "sudo1"              => { name => 'sudo1' },
                                  "command1:s"         => { name => 'command1', default => 'vxdisk' },
                                  "command1-path:s"    => { name => 'command1_path', default => '/usr/sbin' },
                                  "command1-options:s" => { name => 'command1_options', default => 'list 2>&1' },
                                  "skip-vxdisk"        => { name => 'skip_vxdisk' },
                                  "sudo2"              => { name => 'sudo2' },
                                  "command2:s"         => { name => 'command2', default => 'vxprint' },
                                  "command2-path:s"    => { name => 'command2_path', default => '/usr/sbin' },
                                  "command2-options:s" => { name => 'command2_options', default => '-Ath 2>&1' },
                                  "skip-vxprint"       => { name => 'skip_vxprint' },
                                  "warning:s"          => { name => 'warning' },
                                  "critical:s"         => { name => 'critical' },
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

sub vdisk_execute {
    my ($self, %options) = @_;
    
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo1},
                                                  command => $self->{option_results}->{command1},
                                                  command_path => $self->{option_results}->{command1_path},
                                                  command_options => $self->{option_results}->{command1_options});
    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);
    
    foreach (split /\n/, $stdout) {        
        if (/(failed)/i ) {
            my $status = $1;
            next if (! /\S+\s+\S+\s+(\S+)\s+/);
            $self->{num_errors}++;
            $self->{vxdisks_name} .= ' [' . $1 . '/' . $status . ']';
        }
    }
}

sub vxprint_execute {
    my ($self, %options) = @_;
    
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo2},
                                                  command => $self->{option_results}->{command2},
                                                  command_path => $self->{option_results}->{command2_path},
                                                  command_options => $self->{option_results}->{command2_options});
    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);
    
    foreach (split /\n/, $stdout) {
        if (/(NODEVICE|FAILING)/i ) {
            my $status = $1;
            next if (! /^\s*\S+\s+(\S+)\s+/);
            $self->{num_errors}++;
            $self->{vxprint_name} .= ' [' . $1 . '/' . $status . ']';
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{num_errors} = 0;
    $self->{vxdisks_name} = '';
    $self->{vxprint_name} = '';

    if (!defined($self->{option_results}->{skip_vxdisk})) {
        $self->vdisk_execute();
    }
    if (!defined($self->{option_results}->{skip_vxprint})) {
        $self->vxprint_execute();
    }
    
    my ($exit_code) =  $self->{perfdata}->threshold_check(value => $self->{num_errors}, 
                                                          threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    if ($self->{num_errors} > 0) {
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Problems on some disks:" . $self->{vxdisks_name}  . $self->{vxprint_name}));
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems on disks.");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Veritas disk status (use 'vxdisk' and 'vxprint' command).

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

=item B<--sudo1>

Use 'sudo' to execute the command.

=item B<--command1>

Command to get information (Default: 'vxdisk').
Can be changed if you have output in a file.

=item B<--command1-path>

Command path (Default: '/usr/sbin').

=item B<--command1-options>

Command options (Default: 'list 2>&1').

=item B<--sudo2>

Use 'sudo' to execute the command.

=item B<--command2>

Command to get information (Default: 'vxprint').
Can be changed if you have output in a file.

=item B<--command2-path>

Command path (Default: '/usr/sbin').

=item B<--command2-options>

Command options (Default: '-Ath 2>&1').

=item B<--skip-vxdisk>

Skip 'vxdisk' command (not executed).

=item B<--skip-vxprint>

Skip 'vxprint' command (not executed).


=back

=cut
