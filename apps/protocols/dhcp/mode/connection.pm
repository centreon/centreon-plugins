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

package apps::protocols::dhcp::mode::connection;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use IO::Socket;
use IO::Select;
use Net::DHCP::Packet;
use Net::DHCP::Constants;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "serverip:s@"      => { name => 'serverip' },
         "out-first-valid"  => { name => 'out_first_valid' },
         "timeout:s"        => { name => 'timeout', default => 15 },
         "macaddr:s"        => { name => 'macaddr', default => '999999100000'},
         "interface:s"      => { name => 'interface', default => 'eth0' },
         "cidr-match:s@"    => { name => 'cidr_match' },
         });
    $self->{unicast} = 0;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{serverip}) && scalar(@{$self->{option_results}->{serverip}}) > 0) {
        $self->{unicast} = 1;
    }
    $self->{subnet_matcher} = undef;
    if (defined($self->{option_results}->{cidr_match}) && scalar(@{$self->{option_results}->{cidr_match}}) > 0) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Net::Subnet',
                                               error_msg => "Cannot load module 'Net::Subnet'.");
        $self->{subnet_matcher} = Net::Subnet::subnet_matcher(@{$self->{option_results}->{cidr_match}});
    }
}

sub send_discover {
    my ($self, %options) = @_;
    
    $self->{random_number} = int(rand(0xFFFFFFFF));
    #Create DHCP Discover Packet
    my $discover = Net::DHCP::Packet->new(
                        Xid => $self->{random_number},
                        Flags => $self->{unicast} == 1 ? 0 : 0x8000,
                        Chaddr => $self->{option_results}->{macaddr},
                        Giaddr => $self->{my_ip},
                        Hops => $self->{unicast} == 1 ? 1 : 0,
                        DHO_HOST_NAME() => 'centreon',
                        DHO_VENDOR_CLASS_IDENTIFIER() => 'foo',
                        DHO_DHCP_MESSAGE_TYPE() => DHCPDISCOVER(),
    );
    my $str = $discover->serialize();
    #Send UDP Packet
    $self->{timing0} = [gettimeofday];
    if ($self->{unicast} == 0) {
        my $remoteipaddr = sockaddr_in(67, INADDR_BROADCAST);
        send($self->{socket}, $str, 0, $remoteipaddr);
    } else {
        foreach my $server_ip (@{$self->{option_results}->{serverip}}) {
            my $remoteipaddr = sockaddr_in(67, inet_aton($server_ip));
            send($self->{socket}, $str, 0, $remoteipaddr);
        }
    }
}

sub create_socket {
    my ($self, %options) = @_;
    
    #Create UDP Socket
    socket($self->{socket}, AF_INET, SOCK_DGRAM, getprotobyname('udp'));
    setsockopt($self->{socket}, SOL_SOCKET, SO_REUSEADDR, 1);
    if ($self->{unicast} == 0) {
        setsockopt($self->{socket}, SOL_SOCKET, SO_BROADCAST, 1);
    }

    $self->{my_ip} = undef;
    if ($self->{unicast} == 1) {
        $self->{my_ip} = $self->get_interface_address(interface => $self->{option_results}->{interface});
    }
    my $port = $self->{unicast} == 1 ? '67' : '68';
    my $addr = $self->{unicast} == 1 ?  inet_aton($self->{my_ip}) : INADDR_ANY;
    my $binding = bind($self->{socket}, sockaddr_in($port, $addr));
}

sub get_interface_address {
    my ($self, %options) = @_;

    require 'sys/ioctl.ph';
    my $socket;
    if (!socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2])) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "cannot get interface address: $!");
        $self->{output}->display();
        $self->{output}->exit();
    }
    my $buf = pack('a256', $options{interface});
    if (ioctl($socket, SIOCGIFADDR(), $buf) && (my @address = unpack('x20 C4', $buf))) {
        return join('.', @address);
    }

    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => "cannot get interface address: $!");
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_offer {
    my ($self, %options) = @_;
    $self->{discresponse} = [];
    
    #Wait DHCP OFFER Packet
    my $wait = IO::Select->new($self->{socket});
    my $timeout = $self->{option_results}->{timeout};
    my $time = time();
    $self->{random_number} = sprintf("%x", $self->{random_number});
    while (my ($found) = $wait->can_read($timeout)) {
        $timeout -= time() - $time;
        $time = time();
        my $srcpaddr = recv($self->{socket}, my $data, 4096, 0);
        my $response = new Net::DHCP::Packet($data);
        my $response_readable = $response->toString();
        # Need to get same Xid and MacAddr in response. Otherwise not for me
        if ($response_readable =~ /^xid\s+=\s+$self->{random_number}/mi && 
            $response_readable =~ /^chaddr\s+=\s+$self->{option_results}->{macaddr}/mi) {
            $self->{timeelapsed} = tv_interval($self->{timing0}, [gettimeofday]);
            push @{$self->{discresponse}}, $response_readable;
            last if (defined($self->{option_results}->{out_first_valid}));
        }
    }
    close $self->{socket};
}

sub check_results {
    my ($self, %options) = @_;

    foreach my $response (@{$self->{discresponse}}) {
        $response =~ /DHO_DHCP_LEASE_TIME.*?=\s+(.*?)\n/m;
        my $lease_time = $1;
        my $yiaddr;
        if ($response =~ /^yiaddr\s+=\s+(.*?)\n/m) {
            $yiaddr = $1;
        }
        $response =~ /^siaddr\s+=\s+(.*?)\n/m;
        my $siaddr = $1;
        
        $self->{output}->output_add(long_msg => sprintf("Response from %s : offer address %s (lease time: %s)", $siaddr, $yiaddr, $lease_time));
        if (defined($self->{subnet_matcher})) {
            if (!$self->{subnet_matcher}->($yiaddr)) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Offer address %s not matching (from: %s)", $yiaddr, $siaddr));
            }
        } else {
            if (!defined($yiaddr) || $yiaddr eq '' || $yiaddr eq '0.0.0.0' ) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("No free lease from %s server", $siaddr));
            }
        }
    }
}

sub result {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("DHCP Server found with free lease"));
    if (scalar(@{$self->{discresponse}}) == 0) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("No DHCPOFFERs were received"));
    } elsif ($self->{unicast} == 1) {
        if (scalar(@{$self->{discresponse}}) != scalar(@{$self->{option_results}->{serverip}})) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("%d of %d requested servers responded",
                                                            scalar(@{$self->{discresponse}}), scalar(@{$self->{option_results}->{serverip}}))); 
        }
    }

    $self->check_results();    
    $self->{output}->perfdata_add(label => "time", unit => 'ms',
                                  value => sprintf('%.3f', $self->{timeelapsed})) if (defined($self->{timeelapsed}));
}

sub run {
    my ($self, %options) = @_;

    $self->create_socket();
    $self->send_discover();
    $self->get_offer();       
    $self->result();

    $self->{output}->display();
    $self->{output}->exit();
}
1;

__END__

=head1 MODE

Check DHCP server availability

=over 8

=item B<--serverip>

IP Addr of the DHCP server to query (do a unicast mode)

=item B<--timeout>

How much time to check dhcp responses (Default: 15 seconds)

=item B<--out-first-valid>

Stop after first valid dhcp response

=item B<--macaddr>

MAC address to use in the DHCP request

=item B<--interface>

Interface to to use for listening (Default: eth0)

=item B<--cidr-match>

Match ip addresses offered (can be used multiple times).
Returns critical for each ip addresses with no match.

=back

=cut

