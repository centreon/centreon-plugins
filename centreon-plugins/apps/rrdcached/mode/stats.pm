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
use IO::Socket::UNIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                 "socket-path:s"    => { name => 'socket_path', default => '/var/rrdtool/rrdcached/rrdcached.sock' },
                                 "warning:s"    => { name => 'warning', default => '3000' },
                                 "critical:s"    => { name => 'critical', default => '5000' },
                                 "timeout:s"    => { name => 'timeout', default => '10' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    my $data;
    my @stat;
    my @tab;
    my $queueLenght; 
    my $SOCK_PATH = $self->{option_results}->{socket_path};
    
    if (-S $SOCK_PATH) {

        my $socket = IO::Socket::UNIX->new(
            Type => SOCK_STREAM(),
            Peer => $SOCK_PATH,
        );
    
    
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
            next if $data !~ m/(^UpdatesR|Data)/;
            push @tab,$data;
            $socket->send("QUIT\n");
        } 
        
        close($socket);
         
        foreach my $line (@tab) {
           my ($key, $value) = split (/:\s*/, $line,2);
           push @stat, $value;
           $self->{output}->output_add(long_msg => sprintf("%s = %i", $key, $value));
        }
         
        my $updatesNotWritten = $stat[0] - $stat[1];
        
        my $exit = $self->{perfdata}->threshold_check(value => $updatesNotWritten, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("RRDCached has %i updates waiting", $updatesNotWritten));

        $self->{output}->perfdata_add(label => 'UpdatesWaiting', unit => 'updates',
                                      value => $updatesNotWritten,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
                      
        $self->{output}->display();
        $self->{output}->exit();
    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => "Can't connect to socket, is rrdcached running ? is your socket path correct ?");
        $self->{output}->display();
        $self->{output}->exit();

    }

}

1;

__END__

=head1 MODE

Check if one of centreon-broker output is dead and failover file is present. CRITICAL STATE ONLY

=over 8

=item B<--rrd-config-file>

Specify the name of your master rrd config-file (default: central-rrd.xml)

=item B<--sql-config-file>

Specify the name of your master sql config file (default: central-broker.xml)

=item B<--config-path>

Specify the path to your broker config files (defaut: /etc/centreon-broker/)

=back

=cut
