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

package cloud::linux::libvirt::local::custom::virshcli;

use strict;
use warnings;
use centreon::plugins::ssh;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    unless ($options{output}) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    unless ($options{noptions}) {
        $options{options}->add_options(arguments => {
            'hostname:s'    => { name => 'hostname',    default => '' },
            'connect-uri:s' => { name => 'connect_uri', default => 'qemu:///system?socket=/var/run/libvirt/libvirt-sock-ro' },
            'virsh-path:s'  => { name => 'virsh_path',  default => '/usr/bin' },
            'timeout:s'     => { name => 'timeout',     default => 30 },
            'sudo'          => { name => 'sudo' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'VIRSHCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};
    $self->{ssh} = centreon::plugins::ssh->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/connect_uri virsh_path timeout sudo hostname/;

    $self->{ssh}->check_options(option_results => $self->{option_results})
	if $self->{hostname} ne '';

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => 'virsh',
        command_options => '',
        command_path => $self->{virsh_path}
    );

    return 0;
}

sub get_identifier {
    my ($self, %options) = @_;

    my $id = $self->{connect_uri} =~ s/[^a-zA-Z0-9_-]/_/gr;
    $id.=':'.$self->{hostname} if $self->{hostname} ne '';
    return $id;
}

sub execute_command {
    my ($self, %options) = @_;

    # $options{virsh_args}: virsh subcommand and its arguments (e.g. 'list --all')
    my $command_options = '--connect ' . $self->{connect_uri} . ' ' . $options{virsh_args};

    my ($stdout, $exit_code);
    if ($self->{hostname} ne '') {
        ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{hostname},
            sudo => $self->{sudo},
            command => 'virsh',
            command_path => $self->{virsh_path},
            command_options => $command_options,
            timeout => $self->{timeout},
            no_quit => $options{no_quit}
        );

    } else {
	($stdout, $exit_code) = centreon::plugins::misc::execute(
            output          => $self->{output},
	    sudo            => $self->{sudo},
            options         => { timeout => $self->{timeout} },
	    command         => 'virsh',
            command_path    => $self->{virsh_path},
	    command_options => $command_options,
            no_quit         => $options{no_quit},
	    no_shell_interpretation => 1
        );
    }

    $self->{output}->output_add(long_msg => "virsh response: $stdout", debug => 1);

    return $stdout;
}

1;

__END__

=head1 NAME

C<virshcli>

=head1 VIRSHCLI OPTIONS

Libvirt C<virsh> CLI custom mode.

=over 8

=item B<--hostname>

Hostname to connect when using the SSH backend.

=item B<--connect-uri>

Libvirt connection URI (default: 'qemu:///system?socket=/var/run/libvirt/libvirt-sock-ro').
Examples: qemu:///system, qemu+ssh://user@host/system, xen:///.

=item B<--virsh-path>

Path to the C<virsh> binary directory (default: '/usr/bin').

=item B<--timeout>

Timeout in seconds for C<virsh> commands (default: 30).

=item B<--sudo>

Run C<virsh> commands with sudo.

=back

=head1 DESCRIPTION

B<custom>.

=cut
