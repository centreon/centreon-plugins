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

package apps::protocols::ftp::mode::commands;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use apps::protocols::ftp::lib::ftp;

# How much arguments i need and commands manages
my %map_commands = (
    binary  => { ssl => { name => 'binary', num => 0 }, nossl => { name => 'binary', num => 0 } },
    ascii   => { ssl => { name => 'ascii', num => 0 },  nossl => { name => 'ascii', num => 0 } },
    cwd     => { ssl => { name => 'cwd', num => 1 },    nossl => { name => 'cwd', num => 0 } },
    rmdir   => { ssl => { name => 'rmdir', num => 1 },  nossl => { name => 'rmdir', num => 1 } },
    mkdir   => { ssl => { name => 'mkdir', num => 1 },  nossl => { name => 'mkdir', num => 1 } },
    ls      => { ssl => { name => 'nlst', num => 0 },   nossl => { name => 'ls', num => 0    } },
    rename  => { ssl => { name => 'rename', num => 2 }, nossl => { name => 'rename', num => 2    } },
    delete  => { ssl => { name => 'delete', num => 1 }, nossl => { name => 'delete', num => 1    } },
    get     => { ssl => { name => 'get', num => 1 },    nossl => { name => 'get', num => 1    } },
    put     => { ssl => { name => 'put', num => 1 },    nossl => { name => 'put', num => 1    } },
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "hostname:s"       => { name => 'hostname' },
         "port:s"           => { name => 'port', },
         "ssl"              => { name => 'use_ssl' },
         "ftp-options:s@"   => { name => 'ftp_options' },
         "ftp-command:s@"   => { name => 'ftp_command' },
         "username:s"   => { name => 'username' },
         "password:s"   => { name => 'password' },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '30' },
         });
    $self->{commands} = [];
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
    foreach (@{$self->{option_results}->{ftp_command}}) {
        my ($command, @args) = split /,/;
        if (!defined($map_commands{$command})) {
            $self->{output}->add_option_msg(short_msg => "Command '$command' doesn't exist or is not supported.");
            $self->{output}->option_exit();
        }
        my $ssl_or_not = $map_commands{$command}->{nossl};
        if (defined($self->{option_results}->{use_ssl})) {
            $ssl_or_not = $map_commands{$command}->{ssl};
        }
        
        if (scalar(@args) < $ssl_or_not->{num}) {
            $self->{output}->add_option_msg(short_msg => "Some arguments are missing for the command: '$command'.");
            $self->{output}->option_exit();
        }
        push @{$self->{commands}}, { name => $ssl_or_not->{name}, args => \@args};
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    apps::protocols::ftp::lib::ftp::connect($self);
    foreach my $command (@{$self->{commands}}) {
        if (!defined(apps::protocols::ftp::lib::ftp::execute($self, command => $command->{name}, command_args => \@{$command->{args}}))) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Command '$command->{name}' issue: %s", apps::protocols::ftp::lib::ftp::message()));
            apps::protocols::ftp::lib::ftp::quit();
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    apps::protocols::ftp::lib::ftp::quit();

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3f ", $timeelapsed));
    $self->{output}->perfdata_add(label => "time",
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check if commands succeed to an FTP Server.

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

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=item B<--ftp-command>

Set command to test (can be multiple).
It will be executed in the order and stop on first command problem.
Following commands can be used:

=over 16

=item binary

Transfer file in binary mode.

=item ascii

Transfer file in ascii mode.

=item cwd,DIR

Attempt to change directory to the directory given in DIR.
If no directory is given then an attempt is made to change the directory to the root directory.

=item rmdir,DIR

Remove the directory with the name DIR.

=item mkdir,DIR

Create a new directory with the name DIR.

=item ls,DIR

Get a directory listing of DIR, or the current directory.

=item rename,OLDNAME,NEWNAME

Rename a file on the remote FTP server from OLDNAME to NEWNAME.

=item delete,FILENAME

Send a request to the server to delete FILENAME.

=item get,REMOTE_FILE,LOCAL_FILE

Get REMOTE_FILE from the server and store locally.

=item put,LOCAL_FILE,REMOTE_FILE

Put a file on the remote server.

=back

=back

=cut
