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

package storage::emc::recoverypoint::ssh::mode::systemstatus;

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
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'get_system_status' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => 'category=system summary=yes' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify hostname.");
       $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{command})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify command option.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{remote} = 1;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(output => $self->{output},
                                                                options => $self->{option_results},
                                                                sudo => $self->{option_results}->{sudo},
                                                                command => $self->{option_results}->{command},
                                                                command_path => $self->{option_results}->{command_path},
                                                                command_options => $self->{option_results}->{command_options},
                                                                );
    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;

    my ($system, $clusters, $wans, $groups);
    foreach (split(/\n/, $stdout)) {
        if (/^System:\s+(.*)$/i) {
            $system = $1;
        } elsif (/^Clusters:\s+(.*)$/i) {
            $clusters = $1;
        } elsif (/^Wans:\s+(.*)$/i) {
            $wans = $1;
        } elsif (/^Groups:\s+(.*)$/i) {
            $groups = $1;
        }
    }    

    $exit_code = 'ok';
    if (($system !~ /OK/im) || ($clusters !~ /OK/im) || ($wans !~ /OK/im) || ($groups !~ /OK/im)) {
        $exit_code = 'critical'
    }

    $self->{output}->output_add(long_msg => $long_msg);
    $self->{output}->output_add(severity => $exit_code, 
                                short_msg => sprintf("System %s, Clusters %s, WANs %s, Groups %s.",
                                            $system, $clusters, $wans, $groups));
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system status.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-pw=password').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to test (Default: get_system_status).
You can use 'sh' to use '&&' or '||'.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: category=system summary=yes).

=back

=cut
