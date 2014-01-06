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

package os::solaris::local::mode::lomv120;

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
        #1 FAULT speed 0%
        #2 FAULT speed 0%
        #3 OK speed 100%
        #4 OK speed 100%
        my @content = split(/\n/, $1);
        shift @content;
        pop @content;
        foreach my $line (@content) {
            next if ($line !~ /^\s*(\S+)\s+(\S+)/);
            my ($fan_num, $status) = ($1, $2);
            
            if ($status !~ /OK/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Fan '$fan_num' status is '$status'");
            }
        }
    }
    
    if ($stdout =~ /^PSUs:(.*?):/ims) {
        #PSUs:
        #1 OK
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
        #1               5V status=ok
        #2              3V3 status=ok
        #3             +12V status=ok
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
        # 1        SCSI-Term status=ok
        # 2             USB0 status=ok
        # 3             USB1 status=ok
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

Check Hardware Status for 'v120' (use 'lom' command).

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
