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

package centreon::common::protocols::ssh::custom::api;

use strict;
use warnings;
use Libssh::Session qw(:all);

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
            'hostname:s@'         => { name => 'hostname' },
            'port:s@'             => { name => 'port' },
            'timeout:s@'          => { name => 'timeout' },
            'ssh-username:s@'     => { name => 'ssh_username' },
            'ssh-password:s@'     => { name => 'ssh_password' },
            'ssh-dir:s@'               => { name => 'ssh_dir' },
            'ssh-identity:s@'          => { name => 'ssh_identity' },
            'ssh-skip-serverkey-issue' => { name => 'ssh_skip_serverkey_issue' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSH OPTIONS', once => 1);

    $self->{output} = $options{output};

    $self->{ssh} = undef;
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{port} = (defined($self->{option_results}->{port})) ? shift(@{$self->{option_results}->{port}}) : 22;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{ssh_username} = (defined($self->{option_results}->{ssh_username})) ? shift(@{$self->{option_results}->{ssh_username}}) : undef;
    $self->{ssh_password} = (defined($self->{option_results}->{ssh_password})) ? shift(@{$self->{option_results}->{ssh_password}}) : undef;
    $self->{ssh_dir} = (defined($self->{option_results}->{ssh_dir})) ? shift(@{$self->{option_results}->{ssh_dir}}) : undef;
    $self->{ssh_identity} = (defined($self->{option_results}->{ssh_identity})) ? shift(@{$self->{option_results}->{ssh_identity}}) : undef;
    $self->{ssh_skip_serverkey_issue} = defined($self->{option_results}->{ssh_skip_serverkey_issue}) ? 1 : 0;
    
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set option --hostname.");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        return 0;
    }
    return 1;
}

sub login {
    my ($self, %options) = @_;
    
    my $result = { status => 0, message => 'authentification succeeded' };
    $self->{ssh} = Libssh::Session->new();

    foreach (['hostname', 'host'], ['port', 'port'], ['timeout', 'timeout'], ['ssh_username', 'user'],
             ['ssh_dir', 'sshdir'], ['ssh_identity', 'identity']) {
        next if (!defined($self->{$_->[0]}) || $self->{$_->[0]} eq '');
        
        if ($self->{ssh}->options($_->[1] => $self->{$_->[0]}) != SSH_OK) {
            $result->{message} = $self->{ssh}->error();
            $result->{status} = 1;
            return $result;
        }
    }

    if ($self->{ssh}->connect(SkipKeyProblem => $self->{ssh_skip_serverkey_issue}) != SSH_OK) {
        $result->{message} = $self->{ssh}->error();
        $result->{status} = 1;
        return $result;
    }

    if ($self->{ssh}->auth_publickey_auto() != SSH_AUTH_SUCCESS) {
        if (defined($self->{ssh_username}) && $self->{ssh_username} ne '' &&
            defined($self->{ssh_password}) && $self->{ssh_password} ne '' &&
            $self->{ssh}->auth_password(password => $self->{ssh_password}) == SSH_AUTH_SUCCESS) {
            return $result;
        }

        my $msg_error = $self->{ssh}->error(GetErrorSession => 1);
        $result->{message} = sprintf("auth issue: %s", defined($msg_error) && $msg_error ne '' ? $msg_error : 'pubkey issue');
        $result->{status} = 1;
    }

    return $result;
}

1;

__END__

=head1 NAME

SSH connector library

=head1 SYNOPSIS

my ssh connector

=head1 SSH OPTIONS

=over 8

=item B<--hostname>

SSH server hostname (required).

=item B<--port>

SSH port.

=item B<--timeout>  

Timeout in seconds for connection (Defaults: 10 seconds)

=item B<--ssh-username>

SSH username.

=item B<--ssh-password>

SSH password.

=item B<--ssh-dir>

Set the ssh directory.

=item B<--ssh-identity>

Set the identity file name (default: id_dsa and id_rsa are checked).

=item B<--ssh-skip-serverkey-issue>

Connection will be OK even if there is a problem (server known changed or server found other) with the ssh server.

=back

=head1 DESCRIPTION

B<custom>.

=cut
