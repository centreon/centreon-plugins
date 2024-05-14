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

package apps::rrdcached::custom::unix;
use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    # Check if an output option is available
    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    # Check if options are available
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'socket-path:s'        => { name => 'socket_path', default => '/var/rrdtool/rrdcached/rrdcached.sock' },
            'timeout:s'            => { name => 'timeout', default => 5 }
        });
    }
    # Adding the custom mode's help to the object
    $options{options}->add_help(package => __PACKAGE__, sections => 'RRDCACHED UNIX SOCKET OPTIONS', once => 1);
    # Adding output structure to the object
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

    return 0;
}

sub connect {
    my ($self, %options) = @_;

    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Peer => $self->{option_results}->{socket_path},
        Timeout  => $self->{option_results}->{timeout},
    );

    return $socket;
}

1;

__END__

=head1 NAME

UNIX socket custom mode.

=head1 SYNOPSIS

RRDcached access via UNIX socket.

=head1 RRDCACHED UNIX SOCKET OPTIONS

=over 8

=item B<--socket-path>

Path to the UNIX socket (default is /var/rrdtool/rrdcached/rrdcached.sock).

=item B<--timeout>

Connection timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
