###############################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Author : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

package apps::protocols::dhcp::mode::connection;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;
use IO::Select;
use Net::DHCP::Packet;
use Net::DHCP::Constants;
use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"   => { name => 'hostname' },
         "timeout:s"    => { name => 'timeout', default => '3'},
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{timeout})) {
          $self->{output}->add_option_msg(short_msg => "Please set the timeout option");
          $self->{output}->option_exit();
      }
}

sub run {
    my ($self, %options) = @_;

    my ($discover, $socket, $listen, $response, $discresponse, $buf);

    #Create DHCP Discover Packet
    $discover = Net::DHCP::Packet->new(
                        Xid => int(rand(0xFFFFFFFF)),
                        Flags => 0x8000,
                        Chaddr => '999999000000',
                        DHO_HOST_NAME() => 'perl test',
                        DHO_VENDOR_CLASS_IDENTIFIER() => 'foo',
                        DHO_DHCP_MESSAGE_TYPE() => DHCPDISCOVER(),
    );


    #Create UDP Socket
    socket($socket, AF_INET, SOCK_DGRAM, getprotobyname('udp'));
    setsockopt($socket, SOL_SOCKET, SO_REUSEADDR, 1);
    setsockopt($socket, SOL_SOCKET, SO_BROADCAST, 1);
    my $distipaddr = sockaddr_in(67, INADDR_BROADCAST);
    my $str = $discover->serialize();
    my $binding = bind($socket, sockaddr_in('68', INADDR_ANY));

    #Send UDP Packet
    send($socket, $str, 0, $distipaddr);

    #Wait DHCP OFFER Packet
    my $wait = IO::Select->new($socket);
    while (my ($found) = $wait->can_read($self->{option_results}->{timeout})) {
        my $srcpaddr = recv($socket, my $data, 4096, 0);
        $response = new Net::DHCP::Packet($data);
        $discresponse = $response->toString();
    }

    close $socket;

    #Output
    if ($discresponse !~ /siaddr = $self->{option_results}->{hostname}/) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                                short_msg => sprintf("No DHCP Server found"));
    } elsif ( $discresponse =~ /yiaddr = 0.0.0.0/ ) {
        $self->{output}->output_add(severity => 'WARNING',
                                                short_msg => sprintf("DHCP Server found with no free lease"));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                                short_msg => sprintf("DHCP Server found with free lease"));
    }

    $self->{output}->display();
    $self->{output}->exit();
}
1;

__END__

=head1 MODE

Check DHCP server availability

=over 8

=item B<--hostname>

IP Addr of the DHCP server

=item B<--timeout>

Connection timeout in seconds (Default: 3)

=back

=cut
