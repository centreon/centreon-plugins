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

package apps::rrdcached::mode::stats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                 "host:s"               => { name => 'host', default => '127.0.0.1' },
                                 "port:s"               => { name => 'port', default => '42217' },
                                 "unix-socket-path:s"   => { name => 'unix_socket_path', default => '/var/rrdtool/rrdcached/rrdcached.sock' },
                                 "warning-update:s"     => { name => 'warning_update', default => '3000' },
                                 "critical-update:s"    => { name => 'critical_update', default => '5000' },
                                 "warning-queue:s"      => { name => 'warning_queue', default => '70' },
                                 "critical-queue:s"     => { name => 'critical_queue', default => '100' },
                                 "socket-type:s"        => { name => 'socket_type', default => 'unix' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-update', value => $self->{option_results}->{warning_update})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-update threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-update', value => $self->{option_results}->{critical_update})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-queue', value => $self->{option_results}->{warning_queue})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-queue threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-queue', value => $self->{option_results}->{critical_queue})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-queue threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    my $data;
    my @stat;
    my @tab;
    my $queueLenght;
    my $socket;
     
    if ($self->{option_results}->{socket_type} eq 'tcp') {
        $socket = IO::Socket::INET->new(
        PeerHost => $self->{option_results}->{host},
        PeerPort => $self->{option_results}->{port},
        Proto => 'tcp',
        ); 
    } else {
        my $SOCK_PATH = $self->{option_results}->{unix_socket_path};
            $socket = IO::Socket::UNIX->new(
                Type => SOCK_STREAM(),
                Peer => $SOCK_PATH,
            );
    }
    
    if (!defined($socket)) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => "Can't connect to socket, is rrdcached running ? is your socket path/address:port correct ?");
        $self->{output}->display();
        $self->{output}->exit();
    } else { 
        $socket->send("STATS\n");
        while ($data = <$socket>) {
            if ($data =~ /(\d+) Statistics follow/) {
                my $stats_number = $1;
                if ($stats_number < 9) {
                    $self->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Stats available are incomplete, check rrdcached daemon (try again if few moments)");
                    $self->{output}->display();
                    $self->{output}->exit();
                }
            }    
            next if $data !~ m/(^UpdatesR|Data|Queue)/;
            push @tab,$data;
            $socket->send("QUIT\n");
                    
        } 
      
        close($socket);

        foreach my $line (@tab) {
            my ($key, $value) = split (/:\s*/, $line,2);
            push @stat, $value;
            $self->{output}->output_add(long_msg => sprintf("%s = %i", $key, $value));
        }
        chomp($stat[0]);  
        my $updatesNotWritten = $stat[1] - $stat[2];
    
        my $exit1 = $self->{perfdata}->threshold_check(value => $updatesNotWritten, threshold => [ { label => 'critical-update', 'exit_litteral' => 'critical' }, { label => 'warning-update', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $stat[0], threshold => [ { label => 'critical-queue', 'exit_litteral' => 'critical' }, { label => 'warning-queue', exit_litteral => 'warning' } ]);

        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("RRDCached has %i updates waiting and %i node(s) in queue", $updatesNotWritten, $stat[0]));

        $self->{output}->perfdata_add(label => 'QueueLenght', unit => 'nodes',
                                      value => $stat[0],
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
 
        $self->{output}->perfdata_add(label => 'UpdatesWaiting', unit => 'updates',
                                      value => $updatesNotWritten,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
                      
        $self->{output}->display();
        $self->{output}->exit();
     }
}

1;

__END__

=head1 MODE

Check Updates cache of rrdcached daemon (compute delta between UpdatesReceived and DataSetsWritten from the rrdcached socket STATS command)

=over 8

=item B<--tcp>

Specify this option if TCP socket is used

=item B<--host>

Host where the socket is (should be set if --tcp is used) (default: 127.0.0.1)

=item B<--port>

Port where the socket is listening (default: 42217)

=item B<--unix>

Specify this option if UNIX socket is used

=item B<--socket-path>

Path to the socket (should be set if --unix is used) (default is /var/rrdtool/rrdcached/rrdcached.sock)

=item B<--warning-update>

Warning number of cached RRD updates (One update can include several values)

=item B<--critical-update>

Critical number of cached RRD updates (One update can include several values)

=item B<--warning-queue>

Warning number of nodes in rrdcached queue

=item B<--critical-queue>

Critical number of nodes in rrdcached queue

=back

=cut
