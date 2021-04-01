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

package apps::hddtemp::custom::cli;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {                      
            'hostname:s'                => { name => 'hostname' },
            'timeout:s'                 => { name => 'timeout', default => 45 },
            'command-drives:s'          => { name => 'command_drives' },
            'command-path-drives:s'     => { name => 'command_path_drives' },
            'command-options-drives:s'  => { name => 'command_options_drives' },
            'command-hddtemp:s'         => { name => 'command_hddtemp' },
            'command-path-hddtemp:s'    => { name => 'command_path_hddtemp' },
            'command-options-hddtemp:s' => { name => 'command_options_hddtemp' },
            'sudo:s'                    => { name => 'sudo' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    return 0;
}

sub list_drives {
    my ($self, %options) = @_;

    my $stdout;
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($stdout) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            command => defined($self->{option_results}->{command_drives}) && $self->{option_results}->{command_drives} ne '' ? $self->{option_results}->{command_drives} : 'lsblk',
            command_path => $self->{option_results}->{command_path_drives},
            command_options => defined($self->{option_results}->{command_options_drives}) && $self->{option_results}->{command_options_drives} ne '' ? $self->{option_results}->{command_options_drives} : '-I 8 -d -o NAME -p -n',
            timeout => $self->{option_results}->{timeout}
        );
    } else {
        ($stdout) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            command => defined($self->{option_results}->{command_drives}) && $self->{option_results}->{command_drives} ne '' ? $self->{option_results}->{command_drives} : 'lsblk',
            command_path => $self->{option_results}->{command_path_drives},
            command_options => defined($self->{option_results}->{command_options_drives}) && $self->{option_results}->{command_options_drives} ne '' ? $self->{option_results}->{command_options_drives} : '-I 8 -d -o NAME -p -n'
        );
    }

    $self->{output}->output_add(long_msg => "command response: $stdout", debug => 1);
    my $drives = {};
    $drives->{$_} = {} foreach (split /\n/, $stdout);

    return $drives;
}

sub get_drives_information {
    my ($self, %options) = @_;

    my $drives = $self->list_drives();
    my $cmd_options = '-u C ' . join(' ', keys %$drives);
    
    my ($stdout, $exit_code);
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            sudo => $self->{option_results}->{sudo},
            command => defined($self->{option_results}->{command_hddtemp}) && $self->{option_results}->{command_hddtemp} ne '' ? $self->{option_results}->{command_hddtemp} : 'hddtemp',
            command_path => $self->{option_results}->{command_path_hddtemp},
            command_options => defined($self->{option_results}->{command_options_hddtemp}) && $self->{option_results}->{command_options_hddtemp} ne '' ? $self->{option_results}->{command_options_hddtemp} : $cmd_options,
            timeout => $self->{option_results}->{timeout},
            no_quit => 1
        );
    } else {
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            sudo => $self->{option_results}->{sudo},
            command => defined($self->{option_results}->{command_hddtemp}) && $self->{option_results}->{command_hddtemp} ne '' ? $self->{option_results}->{command_hddtemp} : 'hddtemp',
            command_path => $self->{option_results}->{command_path_hddtemp},
            command_options => defined($self->{option_results}->{command_options_hddtemp}) && $self->{option_results}->{command_options_hddtemp} ne '' ? $self->{option_results}->{command_options_hddtemp} : $cmd_options . ' 2> /dev/null',
            no_quit => 1,
        );
    }

    # exit values can be: 0/1. Need root permissions.
    if ($exit_code != 0 && $exit_code != 1) {
        $self->{output}->add_option_msg(short_msg => sprintf('command execution error [exit code: %s]', $exit_code));
        $self->{output}->option_exit();
    }

    # OK: 
    #   /dev/sda: SanDisk ...: 32 C
    # ERROR:
    #   message on stderr. So if we don't catch stderr and we have nothing, surely error. for example:
    #   /dev/sda: open: Permission denied
    # UNKNOWN:
    #   /dev/sda: SanDisk ...: no sensor
    # SLEEP:
    #   /dev/sda: SanDisk ...: drive is sleeping
    # NOSENSOR:
    #   /dev/sda: SanDisk ...: drive supported, but it doesn't have a temperature sensor
    # NOT_APPLICABLE:
    #   /dev/sda: SanDisk ...: misc message
    foreach my $name (keys %$drives) {
        if ($stdout =~ /^$name:.*?:\s+(\d+).*?C/m) {
            $drives->{$name}->{status} = 'ok';
            $drives->{$name}->{temperature_unit} = 'C';
            $drives->{$name}->{temperature} = $1;
        } elsif ($stdout =~ /^$name:.*?:\s+(.*)$/m) {
            my $message = $1;
            $drives->{$name}->{status} = 'notApplicable';
            $drives->{$name}->{status} = 'unknown' if ($message =~ /no sensor/i);
            $drives->{$name}->{status} = 'driveSleep' if ($message =~ /drive is sleeping/i);
            $drives->{$name}->{status} = 'noSensor' if ($message =~ /drive supported, but it doesn't have a temperature sensor/i);
        } else {
            $drives->{$name}->{status} = 'error';
        }
    }

    return $drives;
}

1;

__END__

=head1 NAME

ssh

=head1 SYNOPSIS

my ssh

=head1 CLI OPTIONS

=over 8

=item B<--hostname>

Hostname to query (ssh mode).

=item B<--timeout>

Timeout in seconds for the command (Default: 45).

=item You can override command for drives listing.
By default, we use 'lsblk -I 8 -d -o NAME -p -n':

=over 16

=item B<--command-drives>

Command to get information. Used it you have output in a file.

=item B<--command-path-drives>

Command path.

=item B<--command-options-drives>

Command options.

=back

=item You can override command hddtemp used.
By default, we use 'hddtemp -u C /dev/sda /dev/sdb ...' built with the result of drives command:

=over 16

=item B<--command-hddtemp>

Command to get information. Used it you have output in a file.

=item B<--command-path-hddtemp>

Command path.

=item B<--command-options-hddtemp>

Command options.

=item B<--sudo>

Sudo hddtemp command.

=back

=back

=head1 DESCRIPTION

B<custom>.

=cut
