################################################################################
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

package centreon::common::smcli::custom::custom;

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
                      "smcli-command:s"     => { name => 'smcli_command', default => 'SMcli' },
                      "smcli-path:s"        => { name => 'smcli_path', },
                      "sudo:s"              => { name => 'sudo', },
                      "extra-options:s@"    => { name => 'extra_options' },
                      "special-arg:s@"      => { name => 'special_arg' },
                      "hostname:s@"         => { name => 'hostname' },
                      "hostname2:s@"        => { name => 'hostname2' },
                      "password:s@"         => { name => 'password' },
                      "timeout:s@"          => { name => 'timeout' },
                      "show-output:s"       => { name => 'show_output' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SMCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    
    # 1 means we use a file to read
    $self->{no_smclicmd} = 0;
    
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
    
    $self->{cmd} = '';
    $self->{cmd} .= $self->{option_results}->{smcli_path} . '/' if (defined($self->{option_results}->{smcli_path}));
    $self->{cmd} .= $self->{option_results}->{smcli_command};
   
    if (defined($self->{special_arg}) && $self->{special_arg} ne '') {
        $self->{cmd} .= ' ' . $self->{special_arg};
        $self->{no_smclicmd} = 1;
        # It's ok if we use a file.
        return ;
    }
    
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }
    $self->{cmd} .= " " . $self->{hostname};
    $self->{cmd} .= " " . $self->{hostname2} if (defined($self->{hostname2}));
    
    $self->{cmd} .= " -p '" . $self->{password} . "'" if (defined($self->{password}));
    $self->{cmd} .= " " . $self->{extra_options} if (defined($self->{extra_options}));
}

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still hostname
    # return 0 = no hostname left

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{hostname2} = (defined($self->{option_results}->{hostname2})) ? shift(@{$self->{option_results}->{hostname2}}) : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? shift(@{$self->{option_results}->{password}}) : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 30;
    $self->{extra_options} = (defined($self->{option_results}->{extra_options})) ? shift(@{$self->{option_results}->{extra_options}}) : '-quick -S';
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
    
    if ($self->{no_smclicmd} == 0) {
        $self->{cmd} .= " -c '" . $options{cmd} . "'";
    }
    
    # Need to set timeout over command.
    $self->{option_results}->{timeout} = $self->{timeout};
    my ($response, $exit_code) = centreon::plugins::misc::execute(output => $self->{output},
                                            options => $self->{option_results},
                                            sudo => $self->{sudo},
                                            command => $self->{cmd},
                                            command_path => undef,
                                            command_options => undef,
                                            no_quit => 1
                                            );
    if ($exit_code != 0) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command execution error (verbose mode for more details)");
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

Specify smcli path (default: none)

=item B<--smcli-command>

Specify navicli command (default: 'SMcli').

=item B<--extra-option>

Set SMcli extras options (Default: '-quick -S').

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

Set timeout for system command (Default: '30').

=back

=head1 DESCRIPTION

B<custom>.

=cut
