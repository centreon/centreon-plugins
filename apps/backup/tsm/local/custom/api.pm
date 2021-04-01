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

package apps::backup::tsm::local::custom::api;

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
        $options{options}->add_options(arguments =>  {                      
            'tsm-hostname:s'    => { name => 'tsm_hostname' },
            'tsm-username:s'    => { name => 'tsm_username' },
            'tsm-password:s'    => { name => 'tsm_password' },
            'ssh-hostname:s'    => { name => 'ssh_hostname' },
            'ssh-option:s@'     => { name => 'ssh_option' },
            'ssh-path:s'        => { name => 'ssh_path' },
            'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
            'timeout:s'         => { name => 'timeout', default => 45 },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command', default => 'dsmadmc' },
            'command-path:s'    => { name => 'command_path', default => '/opt/tivoli/tsm/client/ba/bin' },
            'command-options:s' => { name => 'command_options', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'TSM CLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{tsm_hostname}) || $self->{option_results}->{tsm_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{tsm_username}) || $self->{option_results}->{tsm_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{tsm_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to set tsm-password option.");
        $self->{output}->option_exit();
    }
 
    return 0;
}

sub tsm_build_options {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    if (defined($self->{option_results}->{ssh_hostname}) && $self->{option_results}->{ssh_hostname} ne '') {
        $self->{option_results}->{hostname} = $self->{option_results}->{ssh_hostname};
        $self->{option_results}->{remote} = 1;
    }

    $self->{option_results}->{command_options} =
        "-comma -dataonly=yes -SERVER=\"$self->{option_results}->{tsm_hostname}\" -ID=\"$self->{option_results}->{tsm_username}\" -PASSWORD=\"$self->{option_results}->{tsm_password}\" -TAB \"$options{query}\"";
}

sub get_tsm_id {
    my ($self, %options) = @_;
    
    return $self->{option_results}->{tsm_hostname} . '_' . $self->{option_results}->{tsm_username} . '_' . $self->{option_results}->{tsm_password};
}

sub execute_command {
    my ($self, %options) = @_;
    
    $self->tsm_build_options(%options);
    my ($response, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );
    
    # 11 is for: ANR2034E SELECT: No match found using this criteria.
    if ($exit_code != 0 && $exit_code != 11) {
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->add_option_msg(short_msg => "Execution command issue (details).");
        $self->{output}->option_exit();
    }
    
    $self->{output}->output_add(long_msg => $response, debug => 1);
    return $response;
}

1;

__END__

=head1 NAME

tsm cli

=head1 SYNOPSIS

my tsm cli

=head1 TSM CLI OPTIONS

=over 8

=item B<--tsm-hostname>

TSM hostname to query (Required).

=item B<--tsm-username>

TSM username (Required).

=item B<--tsm-password>

TSM password (Required).

=item B<--ssh-hostname>

Specify SSH hostname.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 45).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Specify command (default: 'dsmadmc').

=item B<--command-path>

Specify path (default: '/opt/tivoli/tsm/client/ba/bin')

=item B<--command-options>

Command options.

=back

=head1 DESCRIPTION

B<custom>.

=cut
