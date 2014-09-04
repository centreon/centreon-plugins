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

package os::linux::local::mode::cpudetailed;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

my $maps = [
    { counter => 'user', output => 'User %.2f %%', position => 1 },
    { counter => 'nice', output => 'Nice %.2f %%', position => 2 }, 
    { counter => 'system', output => 'System %.2f %%', position => 3 },
    { counter => 'idle', output => 'Idle %.2f %%', position => 4 },
    { counter => 'wait', output => 'Wait %.2f %%', position => 5 },
    { counter => 'interrupt', output => 'Interrupt %.2f %%', position => 6 },
    { counter => 'softirq', output => 'Soft Irq %.2f %%', position => 7 },
    { counter => 'steal', output => 'Steal %.2f %%', position => 8 },
    { counter => 'guest', output => 'Guest %.2f %%', position => 9 },
    { counter => 'guestnice', output => 'Guest Nice %.2f %%', position => 10 },
];

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
                                  "command:s"         => { name => 'command', default => 'cat' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '/proc/stat 2>&1' },
                                });
    foreach (@{$maps}) {
        $options{options}->add_options(arguments => {
                                                    'warning-' . $_->{counter} . ':s'    => { name => 'warning_' . $_->{counter} },
                                                    'critical-' . $_->{counter} . ':s'    => { name => 'critical_' . $_->{counter} },
                                                    });
    }
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{hostname} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (@{$maps}) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $_->{counter}, value => $self->{option_results}->{'warning_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning-" . $_->{counter} . " threshold '" . $self->{option_results}->{'warning_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $_->{counter}, value => $self->{option_results}->{'critical_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical-" . $_->{counter} . " threshold '" . $self->{option_results}->{'critical_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
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
    $self->{statefile_cache}->read(statefile => 'cache_linux_local_' . $self->{hostname}  . '_' .  $self->{mode});
    # Manage values
    my ($buffer_creation, $exit) = (0, 0);
    my $save_datas = {};
    my $new_datas = {};
    my $old_datas = {};
    my ($total_datas, $total_cpu_num) = ({}, 0);
    
    foreach my $line (split(/\n/, $stdout)) {
        next if ($line !~ /cpu(\d+)\s+/);
        my $cpu_number = $1;
        my @values = split /\s+/, $line;
        
        foreach (@{$maps}) {
            next if (!defined($values[$_->{position}]));
            if (!defined($new_datas->{$cpu_number})) {
                $new_datas->{$cpu_number} = { total => 0 };
                $old_datas->{$cpu_number} = { total => 0 };
            }
            $new_datas->{$cpu_number}->{$_->{counter}} = $values[$_->{position}];
            $save_datas->{'cpu' . $cpu_number . '_' . $_->{counter}} = $values[$_->{position}];
            my $tmp_value = $self->{statefile_cache}->get(name => 'cpu' . $cpu_number . '_' . $_->{counter});
            if (!defined($tmp_value)) {
                $buffer_creation = 1;
                next;
            }
            if ($new_datas->{$cpu_number}->{$_->{counter}} < $tmp_value) {
                $buffer_creation = 1;
                next;
            }
            
            $exit = 1;
            $old_datas->{$cpu_number}->{$_->{counter}} = $tmp_value;
            $new_datas->{$cpu_number}->{total} += $new_datas->{$cpu_number}->{$_->{counter}};
            $old_datas->{$cpu_number}->{total} += $old_datas->{$cpu_number}->{$_->{counter}};
        }
    }
    
    $self->{statefile_cache}->write(data => $save_datas);
    if ($buffer_creation == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        if ($exit == 0) {
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "CPUs usages are ok.");
    
    foreach my $cpu_number (sort keys(%$new_datas)) {
        # In buffer creation. New cpu
        next if (scalar(keys %{$old_datas->{$cpu_number}}) <= 1);
        
        if ($new_datas->{$cpu_number}->{total} - $old_datas->{$cpu_number}->{total} == 0) {
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => "Counter not moved. Have to wait.");
            $self->{output}->display();
            $self->{output}->exit();
        }
        $total_cpu_num++;
        
        my @exits;
        foreach (@{$maps}) {
            next if (!defined($new_datas->{$cpu_number}->{$_->{counter}}));
            my $value = (($new_datas->{$cpu_number}->{$_->{counter}} - $old_datas->{$cpu_number}->{$_->{counter}}) * 100) / 
                         ($new_datas->{$cpu_number}->{total} - $old_datas->{$cpu_number}->{total});
            push @exits, $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical-' . $_->{counter}, 'exit_litteral' => 'critical' }, { label => 'warning-' . $_->{counter}, 'exit_litteral' => 'warning' }]);
        }

        $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        my $str_output = "CPU '$cpu_number' Usage: ";
        my $str_append = '';
        foreach (@{$maps}) {
            next if (!defined($new_datas->{$cpu_number}->{$_->{counter}}));
        
            my $value = (($new_datas->{$cpu_number}->{$_->{counter}} - $old_datas->{$cpu_number}->{$_->{counter}}) * 100) / 
                         ($new_datas->{$cpu_number}->{total} - $old_datas->{$cpu_number}->{total});
            $total_datas->{$_->{counter}} = 0 if (!defined($total_datas->{$_->{counter}}));
            $total_datas->{$_->{counter}} += $value;
            $str_output .= $str_append . sprintf($_->{output}, $value);
            $str_append = ', ';
            my $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $_->{counter});
            my $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $_->{counter});

            $self->{output}->perfdata_add(label => 'cpu' . $cpu_number . '_' . $_->{counter}, unit => '%',
                                          value => sprintf("%.2f", $value),
                                          warning => $warning,
                                          critical => $critical,
                                          min => 0, max => 100);
        }
        $self->{output}->output_add(long_msg => $str_output);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => $str_output);
        }
    }
    
    # We can display a total (some buffer creation and counters have moved)
    if ($total_cpu_num != 0) {
        foreach my $counter (sort keys %{$total_datas}) {
            $self->{output}->perfdata_add(label => 'total_cpu_' . $counter . '_avg', unit => '%',
                                          value => sprintf("%.2f", $total_datas->{$counter} / $total_cpu_num),
                                          min => 0, max => 100);
        }
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check average usage for each CPUs (need '/proc/stat' file)
(User, Nice, System, Idle, Wait, Interrupt, SoftIRQ, Steal, Guest, GuestNice)

=over 8

=item B<--warning-*>

Threshold warning in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

=item B<--critical-*>

Threshold critical in percent.
Can be: 'user', 'nice', 'system', 'idle', 'wait', 'interrupt', 'softirq', 'steal', 'guest', 'guestnice'.

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

Command to get information (Default: 'cat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '/proc/stat 2>&1').

=back

=cut
