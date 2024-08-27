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

package centreon::common::emc::navisphere::custom::custom;

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
            'ssh-address:s'        => { name => 'ssh_address' },
            'navicli-command:s'    => { name => 'navicli_command' },
            'navicli-path:s'       => { name => 'navicli_path' },
            'naviseccli-command:s' => { name => 'naviseccli_command' },
            'naviseccli-path:s'    => { name => 'naviseccli_path' },
            'sudo'                 => { name => 'sudo' },
            'special-arg:s'        => { name => 'special_arg' },
            'hostname:s'           => { name => 'hostname' },
            'secfilepath:s'        => { name => 'secfilepath' },
            'username:s'           => { name => 'username' },
            'password:s'           => { name => 'password' },
            'scope:s'              => { name => 'scope' },
            'timeout:s'            => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'NAVISPHERE OPTIONS', once => 1);

    $self->{ssh} = centreon::plugins::ssh->new(%options);

    $self->{output} = $options{output};

    # 1 means we use a file to read
    $self->{no_navicmd} = 0;
    $self->{secure} = 0;
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still hostname
    # return 0 = no hostname left

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{secfilepath} = (defined($self->{option_results}->{secfilepath})) ? $self->{option_results}->{secfilepath} : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{scope} = (defined($self->{option_results}->{scope})) ? $self->{option_results}->{scope} : 0;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{special_arg} = (defined($self->{option_results}->{special_arg})) ? $self->{option_results}->{special_arg} : undef;
    $self->{sudo} = $self->{option_results}->{sudo};

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    $self->{hostname} = centreon::plugins::misc::sanitize_command_param(value => $self->{hostname});
    $self->{scope} = centreon::plugins::misc::sanitize_command_param(value => $self->{scope});
    $self->{special_arg} = centreon::plugins::misc::sanitize_command_param(value => $self->{special_arg});
    $self->{timeout} = centreon::plugins::misc::sanitize_command_param(value => $self->{timeout});
    $self->{secfilepath} = centreon::plugins::misc::sanitize_command_param(value => $self->{secfilepath});

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{navicli_command},
        command_path => $self->{option_results}->{navicli_path}
    );
    $self->{option_results}->{navicli_command} = 'navicli'
        if (!defined($self->{option_results}->{navicli_command}) || $self->{option_results}->{navicli_command} eq '');
    $self->{option_results}->{navicli_path} = '/opt/Navisphere/bin'
        if (!defined($self->{option_results}->{navicli_path}) || $self->{option_results}->{navicli_path} eq '');

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{naviseccli_command},
        command_path => $self->{option_results}->{naviseccli_path}
    );
    $self->{option_results}->{naviseccli_command} = 'naviseccli'
        if (!defined($self->{option_results}->{naviseccli_command}) || $self->{option_results}->{naviseccli_command} eq '');
    $self->{option_results}->{naviseccli_path} = '/opt/Navisphere/bin'
        if (!defined($self->{option_results}->{naviseccli_path}) || $self->{option_results}->{naviseccli_path} eq '');

    if (defined($self->{option_results}->{ssh_address}) && $self->{option_results}->{ssh_address} ne '') {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    $self->build_command();

    return 0;
}

sub build_command {
    my ($self, %options) = @_;
    
    if ($self->{scope} !~ /^[012]$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong scope option '" . $self->{scope} . "'.");
        $self->{output}->option_exit();
    }

    $self->{cmd} = $self->{option_results}->{navicli_path} . '/' . $self->{option_results}->{navicli_command};

    if (defined($self->{username}) || defined($self->{secfilepath})) {
        $self->{cmd} = $self->{option_results}->{naviseccli_path} . '/' . $self->{option_results}->{naviseccli_command};
        $self->{secure} = 1;
    }

    if (defined($self->{secfilepath})) { 
        if (!(-x $self->{secfilepath} && -e $self->{secfilepath} . "/SecuredCLISecurityFile.xml" && -e $self->{secfilepath} . "/SecuredCLIXMLEncrypted.key")) {
            $self->{output}->add_option_msg(short_msg => 'The secfilepath ' . $self->{secfilepath} . ' does not exist or SecuredCLI files are not created.');
            $self->{output}->option_exit();
        }
    } elsif (defined($self->{username})) { 
        if (!defined($self->{password})) {
            $self->{output}->add_option_msg(short_msg => 'Need to specify password option.');
            $self->{output}->option_exit();
        }
    }

    if (! -e $self->{cmd}) {
        $self->{output}->add_option_msg(short_msg => "Command '" . $self->{cmd} . "' not exist or executable.");
        $self->{output}->option_exit();
    }

    if (defined($self->{special_arg}) && $self->{special_arg} ne '') {
        $self->{cmd} .= ' ' . $self->{special_arg};
        $self->{no_navicmd} = 1;
        # It's ok if we use a file.
        $self->{secure} = 1;
        return ;
    }

    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{secfilepath})) {
        $self->{cmd} .= " -Secfilepath '" . $self->{secfilepath} . "'";
    } elsif (defined($self->{username})) {
        $self->{cmd} .= " -User '" . $self->{username} . "' -Password '" . $self->{password} . "' -Scope " . $self->{scope};
    }
    $self->{cmd} .= ' -t ' . $self->{timeout};
    $self->{cmd} .= ' -h ' . $self->{hostname};
}

sub execute_command {
    my ($self, %options) = @_;

    if ($self->{no_navicmd} == 0) {
        $self->{cmd} .= ' ' . $options{cmd};
    }
    if (defined($options{secure_only}) && $options{secure_only} == 1 && $self->{secure} != 1) {
        $self->{output}->add_option_msg(short_msg => "Mode only works with naviseccli.");
        $self->{output}->option_exit();
    }

    my ($stdout, $exit_code);
    if (defined($self->{option_results}->{ssh_address}) && $self->{option_results}->{ssh_address} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{ssh_address},
            sudo => $self->{sudo},
            command => $self->{cmd},
            timeout => $self->{timeout} + 5
        );
    } else {
        ($stdout, $exit_code) = centreon::plugins::misc::execute(
            output => $self->{output},
            sudo => $self->{sudo},
            options => { timeout => $self->{timeout} + 5 },
            command => $self->{cmd}
        );
    }

    return ($stdout, $exit_code);
}

1;

__END__

=head1 NAME

Navisphere

=head1 SYNOPSIS

my navisphere manage

=head1 NAVISPHERE OPTIONS

=over 8

=item B<--ssh-address>

Specify ssh address target (default: use hostname option)

=item B<--navicli-path>

Specify navicli path (default: '/opt/Navisphere/bin')

=item B<--navicli-command>

Specify navicli command (default: 'navicli').

=item B<--naviseccli-path>

Specify naviseccli path (default: '/opt/Navisphere/bin')

=item B<--naviseccli-command>

Specify naviseccli command (default: 'naviseccli').

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--special-arg>

Set a special argument for the command.
To be used for set a file. (Need to change command and use 'cat' instead).

=item B<--hostname>

Emc Clariion/VNX SP Hostname.

=item B<--secfilepath>

Set directory with security files (username and password not needed. 
Will use 'naviseccli').

=item B<--username>

Username to connect (will use 'naviseccli').

=item B<--password>

Password to connect (will use 'naviseccli').

=item B<--scope>

User scope to connect (will use 'naviseccli'. Default: '0' (global)).

=item B<--timeout>

Set timeout for system command (default: '30').

=back

=head1 DESCRIPTION

B<custom>.

=cut
