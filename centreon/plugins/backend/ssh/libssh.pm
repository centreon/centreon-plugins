#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::plugins::backend::ssh::libssh;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'libssh-strict-connect' => { name => 'libssh_strict_connect' }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'BACKEND LIBSSH OPTIONS', once => 1);
    }

    $self->{connected} = 0;
    $self->{output} = $options{output};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'Libssh::Session',
        error_msg => "Cannot load module 'Libssh::Session'."
    );
    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'centreon::plugins::backend::ssh::libsshconstants',
        error_msg => "Cannot load module 'centreon::plugins::backend::ssh::libsshconstants'."
    );
    $self->{constant_cb} = \&centreon::plugins::backend::ssh::libsshconstants::get_constant_value;

    if (!defined($self->{ssh})) {
        $self->{ssh} = Libssh::Session->new();
    }

    $self->{ssh_port} = defined($options{option_results}->{ssh_port}) && $options{option_results}->{ssh_port} =~ /(\d+)/ ? $1 : 22;
    $self->{ssh}->options(port => $self->{ssh_port});
    $self->{ssh_username} = $options{option_results}->{ssh_username};
    $self->{ssh_password} = $options{option_results}->{ssh_password};
    
    $self->{ssh}->options(identity => $options{option_results}->{ssh_priv_key})
        if (defined($options{option_results}->{ssh_priv_key}) && $options{option_results}->{ssh_priv_key} ne '');
    $self->{ssh}->options(user => $options{option_results}->{ssh_username})
        if (defined($options{option_results}->{ssh_username}) && $options{option_results}->{ssh_username} ne '');
    $self->{ssh_strict_connect} = defined($options{option_results}->{libssh_strict_connect}) ? 0 : 1;
}

sub connect {
    my ($self, %options) = @_;

    return if ($self->{connected} == 1);

    $self->{ssh}->options(host => $options{hostname});
    if ($self->{ssh}->connect(SkipKeyProblem => $self->{ssh_strict_connect}) != $self->{constant_cb}->(name => 'SSH_OK')) {
        $self->{output}->add_option_msg(short_msg => 'connect issue: ' . $self->{ssh}->error());
        $self->{output}->option_exit();
    }

    if ($self->{ssh}->auth_publickey_auto() != $self->{constant_cb}->(name => 'SSH_AUTH_SUCCESS')) {
        if (defined($self->{ssh_username}) && $self->{ssh_username} ne '' &&
            defined($self->{ssh_password}) && $self->{ssh_password} ne '' &&
            $self->{ssh}->auth_password(password => $self->{ssh_password}) == $self->{constant_cb}->(name => 'SSH_AUTH_SUCCESS')) {
            $self->{connected} = 1;
            return ;
        }

        my $msg_error = $self->{ssh}->error(GetErrorSession => 1);
        $self->{output}->add_option_msg(short_msg => sprintf("auth issue: %s", defined($msg_error) && $msg_error ne '' ? $msg_error : 'pubkey issue'));
        $self->{output}->option_exit();
    }
}

sub execute {
    my ($self, %options) = @_;

    if (defined($options{timeout}) && $options{timeout} =~ /(\d+)/) {
        $self->{ssh}->options(timeout => $options{timeout});
    }

    $self->connect(hostname => $options{hostname});

    my $cmd = '';
    $cmd = 'sudo ' if (defined($options{sudo}));
    $cmd .= $options{command_path} . '/' if (defined($options{command_path}));
    $cmd .= $options{command} . ' ' if (defined($options{command}));
    $cmd .= $options{command_options} if (defined($options{command_options}));

    my $ret;
    if (!defined($options{ssh_pipe}) || $options{ssh_pipe} == 0) {
        $ret = $self->{ssh}->execute_simple(
            cmd => $cmd,
            timeout => $options{timeout},
            timeout_nodata => $options{timeout}
        );
    } else {
        $ret = $self->{ssh}->execute_simple(
            input_data => $cmd,
            timeout => $options{timeout},
            timeout_nodata => $options{timeout}
        );
    }

    $self->{output}->output_add(long_msg => $ret->{stdout}, debug => 1) if (defined($ret->{stdout}));
    $self->{output}->output_add(long_msg => $ret->{stderr}, debug => 1) if (defined($ret->{stderr}));

    my ($content, $exit_code);
    if ($ret->{exit} == $self->{constant_cb}->(name => 'SSH_OK')) {
        $content = $ret->{stdout};
        $exit_code = $ret->{exit_code};
    } elsif ($ret->{exit} == $self->{constant_cb}->(name => 'SSH_AGAIN')) { # AGAIN means timeout
        $self->{output}->add_option_msg(short_msg => sprintf('command execution timeout'));
        $self->{output}->option_exit();
    } else {
        $self->{output}->add_option_msg(short_msg =>
            sprintf(
                'command execution error: %s',
                $self->{ssh}->error(GetErrorSession => 1)
            )
        );
        $self->{output}->option_exit();
    }

    if (defined($options{ssh_pipe}) && $options{ssh_pipe} == 1) {
        # Last failed login: Tue Feb 25 09:30:20 EST 2020 from 10.40.1.160 on ssh:notty
        # There was 1 failed login attempt since the last successful login.
        $content =~ s/^(?:Last failed login:|There was.*?failed login).*?\n//msg;
    }

    if ($exit_code != 0 && (!defined($options{no_quit}) || $options{no_quit} != 1)) {
        $self->{output}->add_option_msg(short_msg => sprintf('command execution error [exit code: %s]', $exit_code));
        $self->{output}->option_exit();
    }

    return ($content, $exit_code);
}

1;

__END__

=head1 NAME

libssh backend.

=head1 SYNOPSIS

libssh backend.

=head1 BACKEND LIBSSH OPTIONS

=over 8

=item B<--libssh-strict-connect>

Connection won't be OK even if there is a problem (server known changed or server found other) with the ssh server.

=back

=head1 DESCRIPTION

B<libssh>.

=cut
