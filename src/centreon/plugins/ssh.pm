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

package centreon::plugins::ssh;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'ssh-backend:s'  => { name => 'ssh_backend', default => 'sshcli' },
            'ssh-port:s'     => { name => 'ssh_port' },
            'ssh-priv-key:s' => { name => 'ssh_priv_key' },
            'ssh-username:s' => { name => 'ssh_username' },
            'ssh-password:s' => { name => 'ssh_password' }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'SSH GLOBAL OPTIONS');
    }

    centreon::plugins::misc::mymodule_load(
        output    => $options{output},
        module    => 'centreon::plugins::backend::ssh::sshcli',
        error_msg => "Cannot load module 'centreon::plugins::backend::ssh::sshcli'."
    );
    $self->{backend_sshcli} = centreon::plugins::backend::ssh::sshcli->new(%options);

    centreon::plugins::misc::mymodule_load(
        output    => $options{output},
        module    => 'centreon::plugins::backend::ssh::plink',
        error_msg => "Cannot load module 'centreon::plugins::backend::ssh::plink'."
    );
    $self->{backend_plink} = centreon::plugins::backend::ssh::plink->new(%options);

    centreon::plugins::misc::mymodule_load(
        output    => $options{output},
        module    => 'centreon::plugins::backend::ssh::libssh',
        error_msg => "Cannot load module 'centreon::plugins::backend::ssh::libssh'."
    );
    $self->{backend_libssh} = centreon::plugins::backend::ssh::libssh->new(%options);

    $self->{output} = $options{output};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{ssh_backend} = $options{option_results}->{ssh_backend};
    my $default_port = 22;
    if (defined($options{default_ssh_port}) && $options{default_ssh_port} =~ /\d+/) {
        $default_port = $options{default_ssh_port};
    }
    $self->{ssh_port} = defined($options{option_results}->{ssh_port}) && $options{option_results}->{ssh_port} =~ /(\d+)/ ? $1 : $default_port;
    $self->{ssh_backend} = 'sshcli'
        if (!defined($options{option_results}->{ssh_backend}) || $options{option_results}->{ssh_backend} eq '');
    if (!defined($self->{'backend_' . $self->{ssh_backend}})) {
        $self->{output}->add_option_msg(short_msg => 'unknown ssh backend: ' . $self->{ssh_backend});
        $self->{output}->option_exit();
    }
    $self->{'backend_' . $self->{ssh_backend}}->check_options(%options);
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{ssh_port};
}

sub get_ssh_backend {
    my ($self, %options) = @_;

    return $self->{ssh_backend};
}

sub execute {
    my ($self, %options) = @_;

    return $self->{'backend_' . $self->{ssh_backend}}->execute(%options);
}

1;

__END__

=head1 NAME

SSH abstraction layer.

=head1 SYNOPSIS

SSH abstraction layer for SSH CLI, Plink and libSSH backends

=head1 SSH GLOBAL OPTIONS

=over 8

=item B<--ssh-backend>

Define the backend you want to use.
It can be: C<sshcli> (default), C<plink> and C<libssh>.

=item B<--ssh-username>

Define the user name to log in to the host.

=item B<--ssh-password>

Define the password associated with the user name.
Cannot be used with the C<sshcli> backend.
Warning: using a password is not recommended. Use C<--ssh-priv-key> instead.

=item B<--ssh-port>

Define the TCP port on which SSH is listening.

=item B<--ssh-priv-key>

Define the private key file to use for user authentication.

=back

=head1 DESCRIPTION

B<ssh>.

=cut
