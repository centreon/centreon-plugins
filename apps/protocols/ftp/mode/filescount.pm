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
# Author : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package apps::protocols::ftp::mode::filescount;

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
         "recursive"        => { name => 'recursive' },
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
    my $cpt;
    my @files;
    my @array;

    apps::protocols::ftp::lib::ftp::connect($self); 
    my ($ref_array, $globalCount, $flag) = $self->countFiles(@{$self->{option_results}->{directory}});
    @array = @$ref_array;
    
    if (defined($self->{option_results}->{recursive})) {
        while ($flag == 1) {
            ($ref_array, $cpt, $flag) = $self->countFiles(@array);
            $globalCount = $globalCount + $cpt;
            @array = @$ref_array;
        }
    }
    apps::protocols::ftp::lib::ftp::quit();

    my $exit_code = $self->{perfdata}->threshold_check(value => $globalCount,
                                                       threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Number of files : %s", $globalCount));                               
    $self->{output}->perfdata_add(label => 'files',
                                  value => $globalCount,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    $self->{output}->display();
    $self->{output}->exit();
}

sub countFiles {
    my ($self, @array) = @_;
    my @files;
    my @subdirs;
    my $size;
    my $cpt = 0;
    my $time_result;
    my $flag = 0;
  
    foreach my $dir (@array) {
        if (!(@files = apps::protocols::ftp::lib::ftp::execute($self, command => $map_commands{ls}->{$self->{ssl_or_not}}->{name}, command_args => [$dir]))) {
            $flag = 0;
        }
           
        foreach my $file (@files) {
            if (!($time_result = apps::protocols::ftp::lib::ftp::execute($self, command => $map_commands{mdtm}->{$self->{ssl_or_not}}->{name}, command_args => [$file]))) {
                push(@subdirs, $file);
                $flag = 1;        
            }
            $cpt++;
        }
        $size = @subdirs;
    }
    $cpt = $cpt - $size;
    return \@subdirs, $cpt, $flag;
}

1;

__END__

=head1 MODE

Count files in an FTP directory (can be recursive).

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
Example: --ftp-options='Debug=1" --ftp-options='useSSL=1"

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning (number of files)

=item B<--critical>

Threshold critical (number of files)

=item B<--directory>

Check files in the directory (Multiple option)

=back

=cut
