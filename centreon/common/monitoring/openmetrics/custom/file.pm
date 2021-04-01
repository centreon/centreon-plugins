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

package centreon::common::monitoring::openmetrics::custom::file;

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

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
            'ssh-option:s@'     => { name => 'ssh_option' },
            'ssh-path:s'        => { name => 'ssh_path' },
            'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
            'timeout:s'         => { name => 'timeout', default => 10 },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command', default => 'cat' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'FILE OPTIONS', once => 1);

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

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }

    return 0;
}

sub get_uuid {
    my ($self, %options) = @_;

    return md5_hex(
        ((defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') ? $self->{option_results}->{hostname} : 'none') . '_' .
        ((defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '') ? $self->{option_results}->{command_options} : 'none')
    );
}

sub scrape {
    my ($self, %options) = @_;

    return centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
    );
}

1;

__END__

=head1 NAME

Openmetrics file

=head1 SYNOPSIS

Openmetrics file custom mode

=head1 FILE OPTIONS

=over 8

=item B<--hostname>

Endpoint hostname (If remote).

=item B<--ssh-option>

Specify multiple options like the user (Example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (Default: none)

=item B<--ssh-command>

Specify ssh command (Default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'cat').

=item B<--command-path>

Command path.

=item B<--command-options>

Command options).

=item B<--timeout>

Set SSH timeout (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
