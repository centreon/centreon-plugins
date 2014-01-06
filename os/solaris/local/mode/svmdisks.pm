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

package os::solaris::local::mode::svmdisks;

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
                                  "hostname:s"         => { name => 'hostname' },
                                  "remote"             => { name => 'remote' },
                                  "ssh-option:s@"      => { name => 'ssh_option' },
                                  "ssh-path:s"         => { name => 'ssh_path' },
                                  "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"          => { name => 'timeout', default => 30 },
                                  "sudo1"              => { name => 'sudo1' },
                                  "command1:s"         => { name => 'command1', default => 'metastat' },
                                  "command1-path:s"    => { name => 'command1_path', default => '/usr/sbin' },
                                  "command1-options:s" => { name => 'command1_options', default => '-c 2>&1' },
                                  "sudo2"              => { name => 'sudo2' },
                                  "command2:s"         => { name => 'command2', default => 'metadb' },
                                  "command2-path:s"    => { name => 'command2_path', default => '/usr/sbin' },
                                  "command2-options:s" => { name => 'command2_options', default => '2>&1' },
                                  "warning:s"          => { name => 'warning', },
                                  "critical:s"         => { name => 'critical', },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warn1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
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

    my $stdout2 = centreon::plugins::misc::execute(output => $self->{output},
                                                   options => $self->{option_results},
                                                   sudo => $self->{option_results}->{sudo2},
                                                   command => $self->{option_results}->{command2},
                                                   command_path => $self->{option_results}->{command2_path},
                                                   command_options => $self->{option_results}->{command2_options});
    $long_msg = $stdout2;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg); 

    my $num_metastat_errors = 0;
    my $metastat_name = '';
    foreach (split(/\n/, $stdout)) {
        #d1               m 10.0GB d11 d12 (maint)
        #       d11          s 10.0GB /dev/dsk/c5t600A0B80002929FC0000842E5251EE71d0s6
        #       d12          s 10.0GB /dev/dsk/c5t600A0B800011978E000026D95251FEF1d0s6 (maint)
        #d5               r  4.0GB /dev/dsk/c5t600A0B80002929FC000084305251EFADd0s6 /dev/dsk/c5t600A0B800011978E000026DC52520043d0s6 /dev/dsk/c5t600A0B800011978E000026E25252811Ad0s6
        #
        # Only need to check 's' (stripping) and 'r' (raid). 'm' (mirror) is (maint) because of 's' is (maint)
        
        if (/^\s*(\S+)\s+(s|r)\s+\S+\s+(.*?)\(maint\)/i ) {
            my $name = $1;
            my $disks = $3;
            $disks = trim($disks);
            $num_metastat_errors++;
            $metastat_name .= ' [' . $name . ' (' . $disks . ')]';
        }
    }
    
    my $num_metadb_errors = 0;
    my $metadb_name = '';
    foreach (split /\n/, $stdout2) {
        #flags           first blk       block count
        #     a m  pc luo        16              8192            /dev/dsk/c5t600A0B80002929FC0000842E5251EE71d0s7
        #     a    pc luo        8208            8192            /dev/dsk/c5t600A0B80002929FC0000842E5251EE71d0s7
        #     a    pc luo        16400           8192            /dev/dsk/c5t600A0B80002929FC0000842E5251EE71d0s7
        #      W   pc l          16              8192            /dev/dsk/c5t600A0B800011978E000026D95251FEF1d0s7
        #      W   pc l          8208            8192            /dev/dsk/c5t600A0B800011978E000026D95251FEF1d0s7
        #      W   pc l          16400           8192            /dev/dsk/c5t600A0B800011978E000026D95251FEF1d0s7
        #
        # Uppercase letters are problems:
        #  W - replica has device write errors
        #  M - replica had problem with master blocks
        #  D - replica had problem with data blocks
        #  F - replica had format problems
        #  S - replica is too small to hold current data base
        #  R - replica had device read errors
        if (/^(.*?)[0-9]/i) {
            my $flags = $1;
            my $errors_flags = '';
            while ($flags =~ /([A-Z])/g) {
                $errors_flags .= $1;
            }

            next if ($errors_flags eq '');
            /(\S+)$/;
            $num_metadb_errors++;
            $metadb_name .= ' [' . $1 . ' (' . $errors_flags . ')]';
        }
    }

    my ($exit_code) = $self->{perfdata}->threshold_check(value => $num_metastat_errors, 
                                                         threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]); 
    if ($num_metastat_errors > 0) {
        output_add(severity => $exit_code,
                   short_msg => sprintf("Some metadevices need maintenance:" . $metastat_name));
    } else {
        output_add(severity => 'OK', 
               short_msg => "No problems on metadevices");
    }
    
    ($exit_code) = $self->{perfdata}->threshold_check(value => $num_metadb_errors, 
                                                      threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);    
    if ($num_metadb_errors > 0) {
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Some replicas have problems:" . $metadb_name));
    } else {
        $self->{output}->output_add(severity => 'OK', 
                                    short_msg => "No problems on replicas");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SolarisVm disk status (use 'metastat' and 'metadb' command).

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

Command to get information (Default: 'metastat').
Can be changed if you have output in a file.

=item B<--command1-path>

Command path (Default: '/usr/sbin').

=item B<--command1-options>

Command options (Default: '-c 2>&1').

=item B<--sudo2>

Use 'sudo' to execute the command.

=item B<--command2>

Command to get information (Default: 'metadb').
Can be changed if you have output in a file.

=item B<--command2-path>

Command path (Default: '/usr/sbin').

=item B<--command2-options>

Command options (Default: '2>&1').

=back

=cut
