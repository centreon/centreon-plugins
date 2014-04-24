################################################################################
# Copyright 2005-2014 MERETHIS
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

package os::aix::local::mode::errpt;

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
                                  "command:s"         => { name => 'command', default => 'errpt' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => ' ' },
                                  "error-type:s"      => { name => 'error_type' },
								  "error-class:s"     => { name => 'error_class' },
								  "retention:s"       => { name => 'retention' },
								  "timezone:s"        => { name => 'timezone' },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
	my $extra_options = '';

	if (defined($self->{option_results}->{error_type})){
		$extra_options = $extra_options.' -T '.$self->{option_results}->{error_type};
	}
	if (defined($self->{option_results}->{error_class})){
        $extra_options = $extra_options.' -d '.$self->{option_results}->{error_class};
    }
	if (defined($self->{option_results}->{retention})){
    	my $retention = time() - $self->{option_results}->{retention};
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($retention);
		$year = $year - 100;
		if (length($sec)==1){
			$sec = '0'.$sec;
		}
		if (length($min)==1){
            $min = '0'.$min;
        }
		if (length($hour)==1){
            $hour = '0'.$hour;
        }
		$mon = $mon + 1;
		if (length($mon)==1){
            $mon = '0'.$mon;
        }
		$retention = $mon.$mday.$hour.$min.$year;
		$extra_options = $extra_options.' -s '.$retention;
    }

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $extra_options.' '.$self->{option_results}->{command_options});
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        
		my ($identifier, $timestamp, $resource_name) = ($1, $2, $5);
        $self->{result}->{$identifier} = {timestamp => $timestamp, resource_name => $resource_name};
    }
    
    if (scalar(keys %{$self->{result}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->output_add(long_msg => "No error found with these options.");
        } else {
            $self->{output}->output_add(short_msg => "No error found.");
        }
        $self->{output}->display();
    	$self->{output}->exit();
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'No error found.');
    
    foreach my $identifier (sort(keys %{$self->{result}})) {
        my $timestamp = $self->{result}->{$identifier}->{timestamp};
        my $resource_name = $self->{result}->{$identifier}->{resource_name};
        my $exit;
		
        $self->{output}->output_add(long_msg => sprintf("Error '%s' Date: %s ResourceName: %s", $identifier,
                                         	$timestamp, $resource_name));
        $self->{output}->output_add(severity => 'critical',
                                    short_msg => sprintf("Error '%s' Date: %s ResourceName: %s", $identifier,
                                        $timestamp, $resource_name));    
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check storage usages.

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

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'df').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-P -k -T 2>&1').

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--name>

Set the storage mount point (empty means 'check all storages')

=item B<--regexp>

Allows to use regexp to filter storage mount point (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--filter-type>

Filter filesystem type (regexp can be used).

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (Default: none).

=back

=cut
