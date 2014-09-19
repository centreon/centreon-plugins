###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::protocols::ftp::mode::date;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::protocols::ftp::lib::ftp;

# How much arguments i need and commands manages
my %map_commands = (
    mdtm  => { ssl => { name => '_mdtm'  }, nossl => { name => 'mdtm' } },
    ls    => { ssl => { name => 'nlst' },   nossl => { name => 'ls'} },
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"       => { name => 'hostname' },
         "port:s"           => { name => 'port', },
         "ssl"              => { name => 'use_ssl' },
         "ftp-options:s@"   => { name => 'ftp_options' },
         "directory:s@"     => { name => 'directory' },
         "file:s@"          => { name => 'file' },
         "username:s"   => { name => 'username' },
         "password:s"   => { name => 'password' },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '30' },
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
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    $self->{ssl_or_not} = 'nossl';
    if (defined($self->{option_results}->{use_ssl})) {
         $self->{ssl_or_not} = 'ssl';
    }
}

sub run {
    my ($self, %options) = @_;
    my %file_times = ();
    
    apps::protocols::ftp::lib::ftp::connect($self);
    my $current_time = time();
    my $dirs = ['.'];
    if (defined($self->{option_results}->{directory}) && scalar(@{$self->{option_results}->{directory}}) != 0) {
        $dirs = $self->{option_results}->{directory};
    }
    foreach my $dir (@$dirs) {
        my @files;

        if (!(@files = apps::protocols::ftp::lib::ftp::execute($self, command => $map_commands{ls}->{$self->{ssl_or_not}}->{name}, command_args => [$dir]))) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Command '$map_commands{ls}->{$self->{ssl_or_not}}->{name}' issue for directory '$dir': %s", apps::protocols::ftp::lib::ftp::message()));
            apps::protocols::ftp::lib::ftp::quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
        
        foreach my $file (@files) {
            my $time_result;
            
            if (!($time_result = apps::protocols::ftp::lib::ftp::execute($self, command => $map_commands{mdtm}->{$self->{ssl_or_not}}->{name}, command_args => [$file]))) {
                # Sometime we can't have mtime for a directory
                next;
            }
            
            $file_times{$file} = $time_result;
        }
    }
    foreach my $file (@{$self->{option_results}->{file}}) {
        my $time_result;
            
        if (!($time_result = apps::protocols::ftp::lib::ftp::execute($self, command => $map_commands{mdtm}->{$self->{ssl_or_not}}->{name}, command_args => [$file]))) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Command '$map_commands{mdtm}->{$self->{ssl_or_not}}->{name}' issue for file '$file': %s", apps::protocols::ftp::lib::ftp::message()));
            apps::protocols::ftp::lib::ftp::quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
        $file_times{$file} = $time_result;
    }

    apps::protocols::ftp::lib::ftp::quit();

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All file times are ok.");
    foreach my $name (sort keys %file_times) {
        my $diff_time = $current_time - $file_times{$name};

        my $exit_code = $self->{perfdata}->threshold_check(value => $diff_time, 
                                                           threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($file_times{$name}))));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($file_times{$name}))));
        }
        $self->{output}->perfdata_add(label => $name, unit => 's',
                                      value => $diff_time,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check modified time of files.

=over 8

=item B<--hostname>

IP Addr/FQDN of the ftp host

=item B<--port>

Port used

=item B<--ssl>

Use SSL connection
Need Perl 'Net::FTPSSL' module

=item B<--ftp-options>

Add custom ftp options.
Example: --ftp-options='Debug=1" --ftp-options='useSSL=1'

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning in seconds for each files (diff time)

=item B<--critical>

Threshold critical in seconds for each files (diff time)

=item B<--directory>

Check files in the directory (no recursive) (Multiple option)

=item B<--file>

Check file (Multiple option)

=back

=cut
