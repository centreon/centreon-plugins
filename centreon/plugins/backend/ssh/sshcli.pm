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

package centreon::plugins::backend::ssh::sshcli;

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'sshcli-command:s' => { name => 'sshcli_command', default => 'ssh' },
            'sshcli-path:s'    => { name => 'sshcli_path' },
            'sshcli-option:s@' => { name => 'sshcli_option' }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'BACKEND SSHCLI OPTIONS', once => 1);
    }

    $self->{output} = $options{output};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{ssh_command} = defined($options{option_results}->{sshcli_command}) && $options{option_results}->{sshcli_command} ne '' ? 
        $options{option_results}->{sshcli_command} : 'ssh';
    $self->{ssh_path} = $options{option_results}->{sshcli_path};
    $self->{ssh_option} = defined($options{option_results}->{sshcli_option}) ? $options{option_results}->{sshcli_option} : [];
    $self->{ssh_port} = defined($options{option_results}->{ssh_port}) && $options{option_results}->{ssh_port} =~ /(\d+)/ ? $1 : 22;
    $self->{ssh_priv_key} = $options{option_results}->{ssh_priv_key};
    $self->{ssh_username} = $options{option_results}->{ssh_username};
    if (defined($options{option_results}->{ssh_password}) && $options{option_results}->{ssh_password} ne '') {
        $self->{output}->add_option_msg(short_msg => 'sshcli backend cannot use ssh password. please use backend plink or libssh');
        $self->{output}->option_exit();
    }

    push @{$self->{ssh_option}}, '-o=BatchMode=yes';
    push @{$self->{ssh_option}}, '-l=' . $self->{ssh_username} if (defined($self->{ssh_username}) && $self->{ssh_username} ne '');
    push @{$self->{ssh_option}}, '-p=' . $self->{ssh_port} if (defined($self->{ssh_port}) && $self->{ssh_port} ne '');
    push @{$self->{ssh_option}}, '-i=' . $self->{ssh_priv_key} if (defined($self->{ssh_priv_key}) && $self->{ssh_priv_key} ne '');
}

sub execute {
    my ($self, %options) = @_;

    push @{$self->{ssh_option}}, '-T' if (defined($options{ssh_pipe}) && $options{ssh_pipe} == 1);
    $options{command} .= $options{cmd_exit} if (defined($options{cmd_exit}) && $options{cmd_exit} ne '');

    my ($content, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        sudo => $options{sudo},
        command => $options{command},
        command_path => $options{command_path},
        command_options => $options{command_options},
        ssh_pipe => $options{ssh_pipe},
        options => {
            remote => 1,
            ssh_address => $options{hostname},
            ssh_command => $self->{ssh_command},
            ssh_path => $self->{ssh_path},
            ssh_option => $self->{ssh_option},
            timeout => $options{timeout}
        },
        no_quit => $options{no_quit}
    );

    if (defined($options{ssh_pipe}) && $options{ssh_pipe} == 1) {
        # Last failed login: Tue Feb 25 09:30:20 EST 2020 from 10.40.1.160 on ssh:notty
        # There was 1 failed login attempt since the last successful login.
        $content =~ s/^(?:Last failed login:|There was.*?failed login).*?\n//msg;
    }

    return ($content, $exit_code);
}

1;

__END__

=head1 NAME

ssh cli backend.

=head1 SYNOPSIS

ssh cli backend.

=head1 BACKEND SSHCLI OPTIONS

=over 8

=item B<--sshcli-command>

ssh command (default: 'ssh').

=item B<--sshcli-path>

ssh command path (default: none)

=item B<--sshcli-option>

Specify ssh cli options (example: --sshcli-option='-o=StrictHostKeyChecking=no').

=back

=head1 DESCRIPTION

B<sshcli>.

=cut
