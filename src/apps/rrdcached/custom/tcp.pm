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

package apps::rrdcached::custom::tcp;
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
        # Adding options legacy from appsmetrics.pm in single mode
        $options{options}->add_options(arguments => {
            'hostname:s'           => { name => 'hostname', default => '127.0.0.1' },
            'port:s'               => { name => 'port', default => 42217 },
            'timeout:s'            => { name => 'timeout', default => 5 }
        });
    }
    # Adding Help structure to the object
    $options{options}->add_help(package => __PACKAGE__, sections => 'RRDCACHED TCP OPTIONS', once => 1);
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

    my $socket = IO::Socket::INET->new(
        PeerHost => $self->{option_results}->{hostname},
        PeerPort => $self->{option_results}->{port},
        Timeout  => $self->{option_results}->{timeout},
        Proto    => 'tcp',
    );

    return $socket;
}

1;

__END__

=head1 NAME

TCP socket custom mode.

=head1 SYNOPSIS

RRDcached access via TCP socket.

=head1 RRDCACHED TCP OPTIONS

=over 8

=item B<--hostname>

Hostname to connect to.

=item B<--port>

TCP port (default: 42217)

=item B<--timeout>

Connection timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
