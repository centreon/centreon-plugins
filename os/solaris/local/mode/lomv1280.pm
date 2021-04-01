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

package os::solaris::local::mode::lomv1280;

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
                                  "command:s"         => { name => 'command', default => 'lom' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-fpv 2>&1' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
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
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");

    if ($stdout =~ /^Fans:(.*?):/ims) {
        #Fans:
        # 1 FT0/FAN3             ft_fan3         OK      speed   self-regulating
        # 9 IB6/FAN0             ft_fan0         OK      speed   100 %
        my @content = split(/\n/, $1);
        shift @content;
        pop @content;
        foreach my $line (@content) {
            next if ($line !~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
            my ($fan_name, $status) = ($2, $4);
            
            if ($status !~ /OK/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Fan '$fan_name' status is '$status'");
            }
        }
    }
    
    if ($stdout =~ /^PSUs:(.*?):/ims) {
        #PSUs:
        # PS0 OK
        # PS1 OK
        my @content = split(/\n/, $1);
        shift @content;
        pop @content;
        foreach my $line (@content) {
            next if ($line !~ /^\s*(\S+)\s+(\S+)/);
            my ($psu_num, $status) = ($1, $2);
            
            if ($status !~ /OK/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Psu '$psu_num' status is '$status'");
            }
        }
    }
    
    if ($stdout =~ /^Supply voltages:(.*?):/ims) {
        #Supply voltages:
        # 1 SSC1       v_1.5vdc0   status=ok
        # 2 SSC1       v_3.3vdc0   status=ok
        # 3 SSC1       v_5vdc0     status=ok
        # 4 RP0        v_1.5vdc0   status=ok
        my @content = split(/\n/, $1);
        shift @content;
        pop @content;
        foreach my $line (@content) {
            $line = centreon::plugins::misc::trim($line);
            my @fields = split(/\s+/, $line);

            shift @fields;
            my $field_status = pop(@fields);
            $field_status =~ /status=(.*)/i;
            my $status = $1;
            my $name = join(' ', @fields);
            if ($status !~ /OK/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Supply voltage '$name' status is '$status'");
            }
        }
    }
    
    if ($stdout =~ /^System status flags:(.*)/ims) {
        #System status flags:
        # 1 PS0        status=okay
        # 2 PS1        status=okay
        # 3 PS2        status=okay
        # 4 PS3        status=okay
        # 5 FT0        status=okay
        # 6 FT0/FAN3   status=okay
        my @content = split(/\n/, $1);
        shift @content;
        pop @content;
        foreach my $line (@content) {
            $line = centreon::plugins::misc::trim($line);
            my @fields = split(/\s+/, $line);

            shift @fields;
            my $field_status = pop(@fields);
            $field_status =~ /status=(.*)/i;
            my $status = $1;
            my $name = join(' ', @fields);
            if ($status !~ /OK/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "System '$name' flag status is '$status'");
            }
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Hardware Status for 'v1280' (use 'lom' command).

=over 8

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

Command to get information (Default: 'lom').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-fpv 2>&1').

=back

=cut
