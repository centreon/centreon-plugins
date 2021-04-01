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

package centreon::common::emc::navisphere::custom::custom;

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
            'remote'               => { name => 'remote' },
            'ssh-address:s'        => { name => 'ssh_address' },
            'ssh-option:s@'        => { name => 'ssh_option' },
            'ssh-path:s'           => { name => 'ssh_path' },
            'ssh-command:s'        => { name => 'ssh_command', default => 'ssh' },
            'navicli-command:s'    => { name => 'navicli_command', default => 'navicli' },
            'navicli-path:s'       => { name => 'navicli_path', default => '/opt/Navisphere/bin' },
            'naviseccli-command:s' => { name => 'naviseccli_command', default => 'naviseccli' },
            'naviseccli-path:s'    => { name => 'naviseccli_path', default => '/opt/Navisphere/bin' },
            'sudo:s'               => { name => 'sudo', },
            'special-arg:s@'       => { name => 'special_arg' },
            'hostname:s@'          => { name => 'hostname' },
            'secfilepath:s@'       => { name => 'secfilepath' },
            'username:s@'          => { name => 'username' },
            'password:s@'          => { name => 'password' },
            'scope:s@'             => { name => 'scope' },
            'timeout:s@'           => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'NAVISPHERE OPTIONS', once => 1);

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

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still hostname
    # return 0 = no hostname left

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{secfilepath} = (defined($self->{option_results}->{secfilepath})) ? shift(@{$self->{option_results}->{secfilepath}}) : undef;
    $self->{username} = (defined($self->{option_results}->{username})) ? shift(@{$self->{option_results}->{username}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{scope} = (defined($self->{option_results}->{scope})) ? shift(@{$self->{option_results}->{scope}}) : 0;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 30;
    $self->{special_arg} = (defined($self->{option_results}->{special_arg})) ? shift(@{$self->{option_results}->{special_arg}}) : undef;
    $self->{sudo} = $self->{option_results}->{sudo};
    
    $self->build_command();
    
    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        return 0;
    }
    return 1;
}

##############
# Specific methods
##############
sub execute_command {
    my ($self, %options) = @_;
    
    if ($self->{no_navicmd} == 0) {
        $self->{cmd} .= ' ' . $options{cmd};
    }
    if (defined($options{secure_only}) && $options{secure_only} == 1 && $self->{secure} != 1) {
        $self->{output}->add_option_msg(short_msg => "Mode only works with naviseccli.");
        $self->{output}->option_exit();
    }
    
    # Need to set timeout over command.
    $self->{option_results}->{timeout} = $self->{timeout} + 5;
    return centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{sudo},
        command => $self->{cmd},
        command_path => undef,
        command_options => undef
    );
}

1;

__END__

=head1 NAME

Navisphere

=head1 SYNOPSIS

my navisphere manage

=head1 NAVISPHERE OPTIONS

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--ssh-address>

Specify ssh address target (default: use hostname option)

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

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

Set timeout for system command (Default: '30').

=back

=head1 DESCRIPTION

B<custom>.

=cut
