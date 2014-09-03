################################################################################
# Copyright 2005-2013 MERETHIS
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

package storage::emc::clariion::custom;

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => 
                    {
                      "navicli-command:s"       => { name => 'navicli_command', default => 'navicli' },
                      "navicli-path:s"          => { name => 'navicli_path', default => '/opt/Navisphere/bin' },
                      "naviseccli-command:s"    => { name => 'naviseccli_command', default => 'naviseccli' },
                      "naviseccli-path:s"       => { name => 'naviseccli_path', default => '/opt/Navisphere/bin' },
                      "sudo:s"                  => { name => 'sudo', },
                      "special-arg:s@"      => { name => 'special_arg' },
                      "hostname:s@"         => { name => 'hostname' },
                      "secfilepath:s@"      => { name => 'secfilepath' },
                      "username:s@"         => { name => 'username' },
                      "password:s@"         => { name => 'password' },
                      "scope:s@"            => { name => 'scope' },
                      "timeout:s@"          => { name => 'timeout' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CLARIION OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    
    # 1 means we use a file to read
    $self->{no_navicmd} = 0;
    $self->{secure} = 0;
    
    return $self;
}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}
    
    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
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
    return centreon::plugins::misc::execute(output => $self->{output},
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

Clariion

=head1 SYNOPSIS

my navisphere manage

=head1 CLARIION OPTIONS

=over 8

=item B<--navicli-path>

Specify navicli path (default: 'navicli')

=item B<--navicli-command>

Specify navicli command (default: '/opt/Navisphere/bin').

=item B<--naviseccli-path>

Specify naviseccli path (default: 'naviseccli')

=item B<--naviseccli-command>

Specify naviseccli command (default: '/opt/Navisphere/bin').

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--special-arg>

Set a special argument for the command.
To be used for set a file. (Need to change command and use 'cat' instead).

=item B<--hostname>

Emc Clariion SP Hostname.

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
