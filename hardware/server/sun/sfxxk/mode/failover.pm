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

package hardware::server::sun::sfxxk::mode::failover;

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
                                  "sudo-pasv"              => { name => 'sudo_pasv' },
                                  "command-pasv:s"         => { name => 'command_pasv', default => 'showfailover' },
                                  "command-path-pasv:s"    => { name => 'command_path_pasv', default => '/opt/SUNWSMS/bin' },
                                  "command-options-pasv:s" => { name => 'command_options_pasv', default => '-r 2>&1' },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'showfailover' },
                                  "command-path:s"    => { name => 'command_path', default => '/opt/SUNWSMS/bin' },
                                  "command-options:s" => { name => 'command_options', default => '2>&1' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $stdout;
    
    $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                               options => $self->{option_results},
                                               sudo => $self->{option_results}->{sudo_pasv},
                                               command => $self->{option_results}->{command_pasv},
                                               command_path => $self->{option_results}->{command_path_pasv},
                                               command_options => $self->{option_results}->{command_options_pasv});
    if ($stdout =~ /SPARE/i) {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "System Controller is in spare mode.");
        $self->{output}->display();
        $self->{output}->exit();
    } elsif ($stdout !~ /MAIN/i) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command problems (see additional info).");
        $self->{output}->display();
        $self->{output}->exit();
    }

    $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                               options => $self->{option_results},
                                               sudo => $self->{option_results}->{sudo},
                                               command => $self->{option_results}->{command},
                                               command_path => $self->{option_results}->{command_path},
                                               command_options => $self->{option_results}->{command_options});
    
    # 'ACTIVITING' is like 'ACTIVE' for us.
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "System Controller Failover Status is ACTIVE.");
    if ($stdout =~ /^SC Failover Status:(.*?)($|\n)/ims) {
        my $failover_status = $1;
        $failover_status = centreon::plugins::misc::trim($failover_status);
        # Can be FAILED or DISABLED
        if ($failover_status !~ /ACTIVE/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "System Controller Failover Status is " . $failover_status . ".");
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun 'sfxxk' system controller failover status.

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

=item B<--sudo-pasv>

Use 'sudo' to execute the command pasv.

=item B<--command-pasv>

Command to know if system controller is 'active' (Default: 'showfailover').

=item B<--command-path-pasv>

Command pasv path (Default: '/opt/SUNWSMS/bin').

=item B<--command-options-pasv>

Command pasv options (Default: '-r 2>&1').

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'showfailover').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/opt/SUNWSMS/bin').

=item B<--command-options>

Command options (Default: '2>&1').

=back

=cut
