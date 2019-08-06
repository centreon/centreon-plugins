#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::hddtemp::local::mode::temperature;

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
                                  "command:s"         => { name => 'command', default => 'hddtemp' },
                                  "command-path:s"    => { name => 'command_path', default => '/usr/sbin'  },
                                  "command-options:s" => { name => 'command_options', default => '-u' },
                                  "warning:s"           => { name => 'warning' },
                                  "critical:s"          => { name => 'critical' },
                                  "disks:s"				=> { name => 'disks' },
                                  "unit:s"				=> { name => 'unit', default => 'C' }
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{disks}) || $self->{option_results}->{disks} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify hdd (ex. /dev/sda).");
       $self->{output}->option_exit();
    }
    
    #### Create command_options
    if (defined($self->{option_results}->{unit})) {
        $self->{option_results}->{command_options} .= $self->{option_results}->{unit};
    }
    $self->{option_results}->{command_options} .= ' ' . $self->{option_results}->{disks};
    $self->{option_results}->{command_options} .= ' 2>&1';
}

sub run {
    my ($self, %options) = @_;
    my $total_size = 0;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All temperatures are ok.");
    foreach (split(/\n/, $stdout)) {
        next if (!/(.*): (.*): ([0-9]*)/);
        my ($disk, $model, $temp) = ($1, $2, $3);
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $temp, 
                                                           threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("%s: %s", $disk, $temp . '°' . $self->{option_results}->{unit}));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("'%s' temp is %s", $disk, $temp . '°' . $self->{option_results}->{unit}));
        }
        $self->{output}->perfdata_add(label => $disk, unit => $self->{option_results}->{unit},
                                      value => $temp,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hdd temperature with hddtemp.

=over 8

=item B<--disks>

Disks to check (ex: /dev/sda)

=item B<--unit>

Temperature unit (default: C).

=item B<--warning>

Threshold warning in °.

=item B<--critical>

Threshold critical in °.

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

Command to get information (Default: 'hddtemp').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-u').

=back

=cut
