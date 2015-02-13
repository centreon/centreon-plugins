################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Simon BOMM <sbomm@merethis.net>
#
####################################################################################

package apps::rrdcached::mode::stats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;
use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
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
