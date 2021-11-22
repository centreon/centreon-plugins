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

package apps::protocols::sftp::mode::date;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use apps::protocols::sftp::lib::sftp;
use Fcntl ":mode";

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "hostname:s"       => { name => 'hostname' },
         "port:s"           => { name => 'port', },
         "ssh-options:s@"   => { name => 'ssh_options' },
         "ssh-priv-key:s"   => { name => 'ssh_priv_key' },
         "passphrase:s" => { name => 'passphrase' },
         "directory:s@"     => { name => 'directory' },
         "file-only"    => { name => 'file_only' },
         "file:s@"          => { name => 'file' },
         "username:s"   => { name => 'username' },
         "password:s"   => { name => 'password' },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '30' },
         "timezone:s"   => { name => 'timezone' },
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

    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        centreon::plugins::misc::mymodule_load(module => 'DateTime',
                                               error_msg => "Cannot load module 'DateTime'.");
    }
}

sub run {
    my ($self, %options) = @_;
    my %file_times = ();

    apps::protocols::sftp::lib::sftp::connect($self);
    my $current_time = time();
    my $dirs = ['.'];
    if (defined($self->{option_results}->{directory}) && scalar(@{$self->{option_results}->{directory}}) != 0) {
        $dirs = $self->{option_results}->{directory};

        foreach my $dir (@$dirs) {
            my $files;

            if (!($files = apps::protocols::sftp::lib::sftp::execute($self, command => 'ls', command_args => [$dir]))) {
                $self->{output}->output_add(severity => 'UNKNOWN',
                                            short_msg => sprintf("Command 'ls' issue for directory '$dir': %s", apps::protocols::sftp::lib::sftp::message()));
                $self->{output}->display();
                $self->{output}->exit();
            }
            foreach my $file (@$files) {
                my $time_result;
                if (defined($self->{option_results}->{file_only}) && !S_ISREG($file->{a}->perm)) {
                    next;
                }
                if (!($time_result = $file->{a}->mtime)) {
                    next;
                }
                $file = $dir . '/' . $file->{filename} if ($file->{filename} !~ /^$dir/); # some sftp only give filename (not the complete path)

                $file_times{$file} = $time_result;
            }
        }
    }
    foreach my $file (@{$self->{option_results}->{file}}) {
        my $time_result;

        if (!($time_result = apps::protocols::sftp::lib::sftp::execute($self, command => 'stat', command_args => [$file]))) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Command 'stat' issue for file '$file': %s", apps::protocols::sftp::lib::sftp::message()));
            $self->{output}->display();
            $self->{output}->exit();
        }
        $file_times{$file} = $time_result->{mtime};
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All file times are ok.");
    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    foreach my $name (sort keys %file_times) {
        my $diff_time = $current_time - $file_times{$name};

        my $exit_code = $self->{perfdata}->threshold_check(value => $diff_time,
                                                           threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my $display_date = scalar(localtime($file_times{$name}));
        if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
            $display_date = DateTime->from_epoch(epoch => $file_times{$name}, %$tz)->datetime()
        }

        $self->{output}->output_add(long_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, $display_date));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, $display_date));
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

IP Addr/FQDN of the sftp host

=item B<--port>

Port used

=item B<--ssh-priv-key>

Private keys for SSH connection.

=item B<--passphrase>

Passphrase for private keys.

=item B<--ssh-options>

SSH Options
E.g --ssh-options='-v' for ssh verbose output

=item B<--username>

Specify username for authentification

=item B<--password>

Specify password for authentification
Need Perl 'IO::Pty' module

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning in seconds for each files (diff time)

=item B<--critical>

Threshold critical in seconds for each files (diff time)

=item B<--directory>

Check files in the directory (no recursive) (Multiple option)

=itme B<--files-only>

Check only files in directory

=item B<--file>

Check file (Multiple option)

=item B<--timezone>

Set the timezone of display date.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
