#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::custom::cli;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc qw/is_empty is_not_empty/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless defined($options{options});

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'        => { name => 'hostname' },
            'timeout:s'         => { name => 'timeout', default => 55 },
            'command:s'         => { name => 'command' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSH OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{ssh} = centreon::plugins::ssh->new(%options, default_backend => 'libssh');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (is_not_empty($self->{option_results}->{hostname})) {
        $self->{ssh}->check_options(option_results => $self->{option_results});
    }

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

sub execute_scenario {
    my ($self, %options) = @_;

    my $content;
    if (is_not_empty($self->{option_results}->{hostname})) {
        ($content) = $self->{ssh}->execute_scenario(
            hostname => $self->{option_results}->{hostname},
            request => $options{request},
            timeout => $self->{option_results}->{timeout}
        );
    } else {
        $self->{output}->option_exit(short_msg => 'please set --hostname option for ssh connection (or --command for local)')
            if (is_empty($self->{option_results}->{command}));

        ($content) = centreon::plugins::misc::execute(
            output => $self->{output},
            options => { timeout => $self->{option_results}->{timeout} },
            command => $self->{option_results}->{command},
            command_path => $self->{option_results}->{command_path},
            command_options => $self->{option_results}->{command_options}
        );
    }

    $content =~ s/\x{0d}//g; # carriage return
    $content =~ s/\x{08}//g; # backspace
    $content =~ s/\x{1b}\x{5b}\x{30}\x{6d}//g; # ANSI reset (ESC[0m)
    $content =~ s/\x{1b}\x{5b}\x{31}\x{6d}//g; # ANSI bold (ESC[1m)

    return $content;
}

1;

__END__

=head1 NAME

Veritas NetBackup Appliance SSH

=head1 SYNOPSIS

Veritas NetBackup Appliance SSH custom mode

=head1 SSH OPTIONS

The appliance is driven through its interactive menus, which only the C<libssh> backend supports:
it is the default backend of this plugin and it requires the Perl module C<Libssh::Session> 1.2 or later.
On first connection, the host key of the appliance is added to the known hosts file.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the SSH connection or the local command (default: 55).

=item B<--command>

Command to get information. Use it if the output is in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=head1 DESCRIPTION

B<custom>.

=cut
