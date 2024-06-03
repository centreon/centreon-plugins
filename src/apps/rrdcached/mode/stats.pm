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

package apps::rrdcached::mode::stats;

use strict;
use warnings;
use IO::Socket;

use base qw(centreon::plugins::templates::counter);

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
            label => 'queue-length',
            nlabel => 'rrdcached.queue-length',
            set => {
                key_values => [ { name => 'queue_length' } ],
                output_template => 'queue length: %s',
                perfdatas => [
                    {
                        template     => '%d',
                        min          => 0
                    }
                ]
            }
        },
        {
            label => 'waiting-updates',
            nlabel => 'rrdcached.waiting-updates',
            set => {
                key_values => [ { name => 'waiting_updates' } ],
                output_template => 'waiting updates: %s',
                perfdatas => [
                    {
                        template => '%d',
                        min      => 0
                    }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $data;
    my %raw_data;

    # open the socket of either type TCP/UNIX
    my $socket = $options{custom}->connect();

    # exit if we cannot connect/open it
    if (!defined($socket) or !$socket->connected()) {
        $self->{output}->output_add(severity => 'CRITICAL', short_msg => "Can't connect to socket, is RRDcached running
         ? Is your socket path or address:port correct ?");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # send the STATS command and receive the response
    $socket->send("STATS\n");
    SOCKETREAD:
    while ($data = <$socket>) {
        chomp $data;
        # there should be at least 9 statistics in the response
        if ($data =~ /(\d+) Statistics follow/) {
            my $stats_number = $1;
            if ($stats_number < 9) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => "The returned statistics are incomplete. Try again later or check that the service is up.");
                $self->{output}->display();
                $self->{output}->exit();
            }
            next SOCKETREAD;
        }

        # parse the stats as "Key: value" lines
        if (my ($key, $value) = $data =~ m/^([^:]+):\s*([\d]+)$/) {
            $raw_data{$key} = $value;
            $self->{output}->output_add(long_msg => "Received data - $key: $value");
        } else {
            $self->{output}->output_add(long_msg => "Skipping data - $data");
            next SOCKETREAD;
        }
        # once all the expected data has been received, we can quit the command and close the socket
        if (defined($raw_data{QueueLength}) and defined($raw_data{UpdatesReceived}) and defined($raw_data{DataSetsWritten})) {
            $socket->send("QUIT\n");
            close($socket);
            last SOCKETREAD;
        }
    }

    # just in case...
    if (!defined($raw_data{QueueLength}) or !defined($raw_data{UpdatesReceived}) or !defined($raw_data{DataSetsWritten})) {
        # all the data have not been gathered despite the socket's answer is finished
        close($socket) if $socket->connected();
        # exit with unknown status
        $self->{output}->output_add(severity => 'UNKNOWN', short_msg => "The returned statistics are incomplete. Try again later.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    # at this point, we should have the needed data, let's store it to our counter
    $self->{global} = {
        queue_length    => $raw_data{QueueLength},
        waiting_updates => $raw_data{UpdatesReceived} - $raw_data{DataSetsWritten}
    };
}

1;

__END__

=head1 MODE

Check if the cache of RRDcached daemon's queue is too long or if it has too many updates waiting (difference between
UpdatesReceived and DataSetsWritten from the rrdcached socket STATS command).

=over 8

=item B<--warning-rrdcached-waiting-updates>

Warning threshold for cached RRD updates (one update can include several values).

=item B<--critical-rrdcached-waiting-updates>

Critical threshold for cached RRD updates (one update can include several values).

=item B<--warning-rrdcached-queue-length>

Warning threshold for the number of nodes currently enqueued in the update queue.

=item B<--critical-rrdcached-queue-length>

Critical  threshold for the number of nodes currently enqueued in the update queue.

=back
