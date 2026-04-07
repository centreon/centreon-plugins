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

package storage::hitachi::eseries::local::custom::cli;

use strict;
use warnings;
use centreon::plugins::misc qw/check_security_command execute/;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    print "Class Custom: Need to specify 'output' argument.\n" and exit 3 unless defined($options{output});
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.") unless defined($options{options});

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'baie-id:s'      => { name => 'baie_id',      default => '' },
            'timeout:s'      => { name => 'timeout',      default => 45 },
            'command-path:s' => { name => 'command_path', default => '' },
            'sudo'           => { name => 'sudo' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'CLI OPTIONS', once => 1);

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

    $self->{output}->option_exit(short_msg => "Please set a valid --baie-id option.")
        unless $self->{option_results}->{baie_id} =~ /^\d+$/;

    $self->{$_} = $self->{option_results}->{$_}
	foreach qw/baie_id timeout/;

    return 0;
}

sub get_baie_id {
    my ($self, %options) = @_;
    return $self->{baie_id};
}

sub execute_command {
    my ($self, %options) = @_;

    my $command_path = $self->{option_results}->{command_path} ne '' ? $self->{option_results}->{command_path}
								     : $options{command_path};

    check_security_command(
        output => $self->{output},
        command => $options{command},
        command_options => $options{command_options},
        command_path => $command_path
    );

    my ($stdout, $exit_code) = execute(
        output        => $self->{output},
        sudo          => $self->{option_results}->{sudo},
        options       => { timeout => $self->{timeout} },
        command       => $options{command},
        command_path  => $command_path,
        command_options => $options{command_options},
        no_quit       => $options{no_quit},
        no_shell_interpretation => 1
    );

    $self->{output}->output_add(long_msg => "command response: ".($stdout // '<no response>'), debug => 1);

    return ($stdout, $exit_code);
}

1;

__END__

=head1 NAME

client

=head1 SYNOPSIS

Hitachi E-Series local client custom connector.

=head1 CLI OPTIONS

=over 8

=item B<--baie-id>

Storage array ID (4 digits, required).

=item B<--timeout>

Timeout in seconds for the command (default: 45).

=item B<--command-path>

Path to the raidcom/pairdisplay binaries.

=item B<--sudo>

Run commands with sudo.

=back

=head1 DESCRIPTION

B<custom>.

=cut
