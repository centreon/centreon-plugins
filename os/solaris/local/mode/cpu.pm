################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package os::solaris::local::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

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
                                  "command:s"         => { name => 'command', default => 'kstat' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-n sys 2>&1' },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{hostname} = undef;
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
    
    $self->{statefile_cache}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
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
    $self->{statefile_cache}->read(statefile => 'cache_solaris_local_' . $self->{hostname}  . '_' .  $self->{mode});
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $datas = {};
    $datas->{last_timestamp} = time();
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "CPUs usages are ok.");
    my @output_cpu_instance = split("instance", $stdout);
    shift @output_cpu_instance;
    foreach (@output_cpu_instance) {
        /:\s.*?(\d+)/;
        my $cpu_number = $1;
        /.*?cpu_ticks_idle\s.*?(\d+).*?cpu_ticks_kernel\s.*?(\d+).*?cpu_ticks_user\s.*?(\d+)/ms;
        $datas->{'cpu_idle_' . $cpu_number} = $1;
        $datas->{'cpu_system_' . $cpu_number} = $2;
        $datas->{'cpu_user_' . $cpu_number} = $3;
        
        if (!defined($old_timestamp)) {
            next;
        }
        my $old_cpu_idle = $self->{statefile_cache}->get(name => 'cpu_idle_' . $cpu_number);
        my $old_cpu_system = $self->{statefile_cache}->get(name => 'cpu_system_' . $cpu_number);
        my $old_cpu_user = $self->{statefile_cache}->get(name => 'cpu_user_' . $cpu_number);
        if (!defined($old_cpu_system) || !defined($old_cpu_idle) || !defined($old_cpu_user)) {
            next;
        }
        
        if ($datas->{'cpu_idle_' . $cpu_number} < $old_cpu_idle) {
            # We set 0. Has reboot.
            $old_cpu_user = 0;
            $old_cpu_idle = 0;
            $old_cpu_system = 0;
        }
        
        my $total_elapsed = ($datas->{'cpu_idle_' . $cpu_number} + $datas->{'cpu_user_' . $cpu_number} + $datas->{'cpu_system_' . $cpu_number}) - ($old_cpu_user + $old_cpu_idle + $old_cpu_system);
        my $idle_elapsed = $datas->{'cpu_idle_' . $cpu_number} - $old_cpu_idle;
        my $cpu_ratio_usetime = 100 * $idle_elapsed / $total_elapsed;
        $cpu_ratio_usetime = 100 - $cpu_ratio_usetime;        
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $cpu_ratio_usetime, 
                                                           threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        $self->{output}->output_add(long_msg => sprintf("CPU %d %.2f%%", $cpu_number, $cpu_ratio_usetime));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("CPU %d %.2f%%", $cpu_number, $cpu_ratio_usetime));
        }
        $self->{output}->perfdata_add(label => 'cpu_' . $cpu_number, unit => '%',
                                      value => sprintf("%.2f", $cpu_ratio_usetime),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

	$self->{statefile_cache}->write(data => $datas);
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system CPUs (need 'kstat' command).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

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

Command to get information (Default: 'kstat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-n sys 2>&1').

=back

=cut
