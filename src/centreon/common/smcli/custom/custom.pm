#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::smcli::custom::custom;

use strict;
use warnings;
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
            'smcli-command:s' => { name => 'smcli_command' },
            'smcli-path:s'    => { name => 'smcli_path' },
            'sudo'            => { name => 'sudo', },
            'extra-options:s' => { name => 'extra_options' },
            'special-arg:s'   => { name => 'special_arg' },
            'hostname:s'      => { name => 'hostname' },
            'hostname2:s'     => { name => 'hostname2' },
            'password:s'      => { name => 'password' },
            'timeout:s'       => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SMCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};

    # 1 means we use a file to read
    $self->{no_smclicmd} = 0;

    return $self;
}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub default_command {
    my ($self, %options) = @_;

    return 'SMcli';
}

sub default_command_path {
    my ($self, %options) = @_;

    return '/opt/IBM_DS/client';
}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{hostname2} = (defined($self->{option_results}->{hostname2})) ? $self->{option_results}->{hostname2} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{extra_options} = (defined($self->{option_results}->{extra_options})) ? $self->{option_results}->{extra_options} : '-quick -S';
    $self->{special_arg} = (defined($self->{option_results}->{special_arg})) ? $self->{option_results}->{special_arg} : undef;
    $self->{sudo} = $self->{option_results}->{sudo};

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    $self->{extra_options} = centreon::plugins::misc::sanitize_command_param(value => $self->{extra_options});
    $self->{special_arg} = centreon::plugins::misc::sanitize_command_param(value => $self->{special_arg});
    $self->{hostname} = centreon::plugins::misc::sanitize_command_param(value => $self->{hostname});
    $self->{hostname2} = centreon::plugins::misc::sanitize_command_param(value => $self->{hostname2});

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{smcli_command},
        command_path => $self->{option_results}->{smcli_path}
    );
    $self->{option_results}->{smcli_command} = $self->default_command()
        if (!defined($self->{option_results}->{smcli_command}) || $self->{option_results}->{smcli_command} eq '');
    $self->{option_results}->{smcli_path} = $self->default_command_path()
        if (!defined($self->{option_results}->{smcli_path}) || $self->{option_results}->{smcli_path} eq '');

    $self->build_command();

    return 0;
}

sub build_command {
    my ($self, %options) = @_;

    $self->{cmd} = '';
    $self->{cmd} .= $self->{option_results}->{smcli_path} . '/' if (defined($self->{option_results}->{smcli_path}));
    $self->{cmd} .= $self->{option_results}->{smcli_command};

    if (defined($self->{special_arg}) && $self->{special_arg} ne '') {
        $self->{cmd} .= ' ' . $self->{special_arg};
        $self->{no_smclicmd} = 1;
        # It's ok if we use a file.
        return ;
    }

    $self->{cmd} .= " " . $self->{hostname};
    $self->{cmd} .= " " . $self->{hostname2} if (defined($self->{hostname2}));

    $self->{cmd} .= " -p '" . $self->{password} . "'" if (defined($self->{password}));
    $self->{cmd} .= " " . $self->{extra_options} if (defined($self->{extra_options}));
}

sub execute_command {
    my ($self, %options) = @_;
    
    if ($self->{no_smclicmd} == 0) {
        $self->{cmd} .= " -c '" . $options{cmd} . "'";
    }

    $self->{option_results}->{timeout} = $self->{timeout};
    my ($response, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{sudo},
        command => $self->{cmd},
        command_path => undef,
        command_options => undef,
        no_quit => 1
    );
    if ($exit_code != 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN', 
            short_msg => "Command execution error (verbose mode for more details)"
        );
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->display();
        $self->{output}->exit();
    }
    return $response;
}

1;

__END__

=head1 NAME

Smcli

=head1 SYNOPSIS

my smcli manage

=head1 SMCLI OPTIONS

=over 8

=item B<--smcli-path>

Specify smcli path (default: for dell '/opt/dell/mdstoragemanager/client', for ibm '/opt/IBM_DS/client')

=item B<--smcli-command>

Specify navicli command (default: 'SMcli').

=item B<--extra-option>

Set SMcli extras options (default: '-quick -S').

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--special-arg>

Set a special argument for the command.
To be used for set a file. (Need to change command and use 'cat' instead).

=item B<--hostname>

Set controller hostname.

=item B<--hostname2>

Set controller 2 hostname.

=item B<--password>

Password to connect.

=item B<--timeout>

Set timeout for system command (default: '30').

=back

=head1 DESCRIPTION

B<custom>.

=cut
