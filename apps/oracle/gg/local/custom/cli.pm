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

package apps::oracle::gg::local::custom::cli;

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
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout' },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' },
            'sudo:s'            => { name => 'sudo' },
            'ggs-home:s'        => { name => 'ggs_home' },
            'oracle-home:s'     => { name => 'oracle_home' }
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

    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /(\d+)/) {
        $self->{timeout} = $1;
    }
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    return 0;
}

sub get_identifier {
    my ($self, %options) = @_;

    my $id = defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me';
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $id .= ':' . $self->{ssh}->get_port();
    }
    return $id;
}

sub set_local_environment {
    my ($self, %options) = @_;

    if (!defined($ENV{GGS_HOME}) || $ENV{GGS_HOME} eq '') {
        if (!defined($self->{option_results}->{ggs_home}) || $self->{option_results}->{ggs_home} eq '') {
            $self->{output}->add_option_msg(short_msg => "Please set option --ggs-home.");
            $self->{output}->option_exit();
        }

        $ENV{GGS_HOME} = $self->{option_results}->{ggs_home};
    }

    if (!defined($ENV{ORACLE_HOME}) || $ENV{ORACLE_HOME} eq '') {
        if (!defined($self->{option_results}->{oracle_home_home}) || $self->{option_results}->{oracle_home} eq '') {
            $self->{output}->add_option_msg(short_msg => "Please set option --oracle-home.");
            $self->{output}->option_exit();
        }

        $ENV{ORACLE_HOME} = $self->{option_results}->{oracle_home};
        $ENV{LD_LIBRARY_PATH} = $ENV{GGS_HOME} . ':' . $ENV{ORACLE_HOME} . '/lib';
    }
}

sub set_ssh_command {
    my ($self, %options) = @_;

    my $env_vars = '';
    my $command = 'ggsci';
    if (!defined($self->{option_results}->{ggs_home})) {
        $self->{output}->add_option_msg(short_msg => "Please set option --ggs-home.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{ggs_home} ne '') {
        $command = '"' . $self->{option_results}->{ggs_home} . '/ggsci"';
    }

    if (!defined($self->{option_results}->{oracle_home})) {
        $self->{output}->add_option_msg(short_msg => "Please set option --oracle-home.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{oracle_home} ne '') {
        $env_vars = 'export ORACLE_HOME="' . $self->{option_results}->{oracle_home} . '"; ';
        $env_vars .= 'export LD_LIBRARY_PATH="' . $self->{option_results}->{oracle_home} . '/lib"; ';
    }

    return $env_vars . 'echo "' . $options{commands} . '" | ' . $command;
}

sub execute_command {
    my ($self, %options) = @_;

    my $timeout = $self->{timeout};
    if (!defined($timeout)) {
        $timeout = defined($options{timeout}) ? $options{timeout} : 45;
    }

    my $command_override = 0;
    if (defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '') {
        $command_override = 1;
    }
    my $command_options = defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : $options{command_options};

    my $command = $self->{option_results}->{command};
    my ($stdout, $exit_code);
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        if ($command_override == 0) {
            $command = $self->set_ssh_command(commands => $options{commands});
        }

        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            sudo => $self->{option_results}->{sudo},
            command => $command,
            command_path => defined($self->{option_results}->{command_path}) && $self->{option_results}->{command_path} ne '' ? $self->{option_results}->{command_path} : $options{command_path},
            command_options => $command_options,
            timeout => $timeout,
            no_quit => $options{no_quit}
        );
    } else {        
        if ($command_override == 0) {
            $self->set_local_environment();
            $command = 'echo "' . $options{commands} . '" | "' . $ENV{GGS_HOME} . '/ggsci"';
        }
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            sudo => $self->{option_results}->{sudo},
            options => { timeout => $timeout },
            command => $command,
            command_path => defined($self->{option_results}->{command_path}) && $self->{option_results}->{command_path} ne '' ? $self->{option_results}->{command_path} : $options{command_path},
            command_options => $command_options,
            no_quit => $options{no_quit}
        );
    }

    $self->{output}->output_add(long_msg => "command response: $stdout", debug => 1);

    return ($stdout, $exit_code);
}

1;

__END__

=head1 NAME

ggsci cli

=head1 SYNOPSIS

ggsci cli

=head1 CLI OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 45). Default value can be override by the mode.

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=item B<--sudo>

sudo command.

=item B<--ggs-home>

Directory with ggsci command line.

Mandatory in ssh (you can set it empty if you have an user with GGS_HOME set in PATH environment)

Mandatory in local if GSS_HOME environment variable is not.

=item B<--oracle-home>

Oracle home directory.

Mandatory in ssh (you can set it empty if you have an user with ORACLE_HOME set in environment)

Mandatory in local if ORACLE_HOME environment variable is not set.

=back

=head1 DESCRIPTION

B<custom>.

=cut
