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

package apps::rrdcached::mode::ping;

use strict;
use warnings;
use IO::Socket;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'response',
            type => 2,
            critical_default => '%{response} !~ /PONG/',
            set => {
                key_values => [ { name => 'response' } ],
                output_template => 'response: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ping_answered = 'no response';

    # open the socket of either type TCP/UNIX
    my $socket = $options{custom}->connect();
    # exit if we cannot connect/open it
    if (!defined($socket) or !$socket->connected()) {
        $self->{output}->output_add(severity => 'CRITICAL', short_msg => "Can't connect to socket, is rrdcached running ? is your socket path/address:port correct ?");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # send the PING command and receive the response
    $socket->send("PING\n");
    SOCKETREAD:
    while (my $data = <$socket>) {
        chomp $data;
        # store the response
        $ping_answered = $data;
        $self->{output}->output_add(long_msg => sprintf("Received response - %s", $data));
        # only one line is expected so we can quit immediately
        $socket->send("QUIT\n");
        close($socket);
        # exit the while loop
        last SOCKETREAD;
    }

    $self->{global} = {
        response    => $ping_answered
    };
}

1;

__END__

=head1 MODE

Check if the RRDcached daemon is answering to the basic PING command.

=item B<--warning-response>

Define the conditions to match for the status to be WARNING. You can use the variable '%{response}'.

=item B<--critical-response>

Define the conditions to match for the status to be CRITICAL.  You can use the variable '%{response}'.
Default: '%{response} !~ /PONG/'.

=over 8

=back
