###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package apps::protocols::udp::mode::connection;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"   => { name => 'hostname' },
         "port:s"       => { name => 'port', },
         "timeout:s"    => { name => 'timeout', default => '3' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--hostname' option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{port})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--port' option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{port})) {
        $self->{option_results}->{port} = centreon::plugins::httplib::get_port($self);
    }

    my $icmp_sock = new IO::Socket::INET(Proto=>"icmp");
    my $read_set = new IO::Select();
    $read_set->add($icmp_sock);

    my $sock = IO::Socket::INET->new(PeerAddr => $self->{option_results}->{hostname},
                                     PeerPort => $self->{option_results}->{port},
                                     Proto => 'udp',
                                    );

    $sock->send("Hello");
    close($sock);
    (my $new_readable) = IO::Select->select($read_set, undef, undef, $self->{option_results}->{timeout});
    my $icmp_arrived = 0;
    foreach $sock (@$new_readable) {
        if ($sock == $icmp_sock) {
            $icmp_arrived = 1;
            $icmp_sock->recv(my $buffer,50,0);
        }
    }
    close($icmp_sock);

    if ($icmp_arrived == 1) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Connection failed on port %s", $self->{option_results}->{port}));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Connection success on port %s", $self->{option_results}->{port}));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check UDP connection

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--port>

Port used

=item B<--timeout>

Connection timeout in seconds (Default: 3)

=back

=cut
