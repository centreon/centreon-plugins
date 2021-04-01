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

package centreon::plugins::nrpe;

use strict;
use warnings;
use Convert::Binary::C;
use Digest::CRC 'crc32';
use IO::Socket;
use IO::Socket::INET6;
use IO::Socket::SSL;
use Socket qw(SOCK_STREAM AF_INET6 AF_INET);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    
    if (!defined($options{output})) {
        print "Class NRPE: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class NRPE: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'nrpe-version:s'    => { name => 'nrpe_version', default => 2 },
            'nrpe-port:s'       => { name => 'nrpe_port', default => 5666 },
            'nrpe-payload:s'    => { name => 'nrpe_payload', default => 1024 },
            'nrpe-bindaddr:s'   => { name => 'nrpe_bindaddr' },
            'nrpe-use-ipv4'     => { name => 'nrpe_use_ipv4' },
            'nrpe-use-ipv6'     => { name => 'nrpe_use_ipv6' },
            'nrpe-timeout:s'    => { name => 'nrpe_timeout', default => 10 },
            'ssl-opt:s@'        => { name => 'ssl_opt' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'NRPE CLASS OPTIONS');

    $self->{output} = $options{output};
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    
    $options{option_results}->{nrpe_version} =~ s/^v//;
    if ($options{option_results}->{nrpe_version} !~ /2|3/) {
        $self->{output}->add_option_msg(short_msg => "Unknown NRPE version.");
        $self->{output}->option_exit();
    }
    $self->{nrpe_version} = $options{option_results}->{nrpe_version};
    $self->{nrpe_payload} = $options{option_results}->{nrpe_payload};

    %{$self->{nrpe_params}} = (
        PeerHost => $options{option_results}->{hostname},
        PeerPort => $options{option_results}->{nrpe_port},
        Timeout => $options{option_results}->{nrpe_timeout},
    );
    if ($options{option_results}->{bindaddr}) {
        $self->{nrpe_params}->{LocalAddr} = $options{option_results}->{nrpe_bindaddr};
    }
    if ($options{option_results}->{nrpe_use_ipv4}) {
        $self->{nrpe_params}->{Domain} = AF_INET;
    } elsif ($options{option_results}->{nrpe_use_ipv6}) {
        $self->{nrpe_params}->{Domain} = AF_INET6;
    }

    $self->{ssl_context} = '';
    my $append = '';
    foreach (@{$options{option_results}->{ssl_opt}}) {
        if ($_ ne '' && $_ =~ /.*=>.*/) {
            $self->{ssl_context} .= $append . $_;
            $append = ', ';
        }
    }
}

sub create_socket {
    my ($self, %options) = @_;

    my $socket;
    if ($self->{ssl_context} ne '') {
        $socket = IO::Socket::SSL->new(%{$self->{nrpe_params}}, eval $self->{ssl_context});
        if (!$socket) {
            $self->{output}->add_option_msg(short_msg => "Failed to establish SSL connection: $!, ssl_error=$SSL_ERROR");
            $self->{output}->option_exit();
        }
    } else {
        $socket = IO::Socket::INET6->new(Proto => 'tcp', Type => SOCK_STREAM, %{$self->{nrpe_params}});
        if (!$socket) {
            $self->{output}->add_option_msg(short_msg => "Failed to create socket: $!");
            $self->{output}->option_exit();
        }
    }

    return $socket;
}

sub assemble {
    my ($self, %options) = @_;

    $self->{c} = Convert::Binary::C->new(ByteOrder => 'BigEndian', Alignment => 0);

    my $packed;
    if ($options{version} eq 2) {
        $packed = $self->assemble_v2(%options);
    } else {
        $packed = $self->assemble_v3(%options);
    }
    return $packed;
}

sub assemble_v3 {
    my ($self, %options) = @_;

    my $buffer = $options{check};
    my $len = length($buffer);

    # In order for crc32 calculation to be correct we need to pad the buffer with \0
    # It seems that the buffer must be in multiples of 1024 so to achive this we use
    # some integer arithmetic to find the next multiple of 1024 that can hold our message
    my $pack_len;
    {
        use integer;
        $pack_len = (($len / 1024) * 1024) + 1024;
    }
    $buffer = pack("Z$pack_len", $buffer);
    $len = length($buffer) + 1;

    my $unpacked;
    $unpacked->{alignment} = 0;
    $unpacked->{buffer_length} = $len;
    $unpacked->{buffer} = $buffer;
    $unpacked->{crc32_value} = "\x00\x00\x00\x00";
    $unpacked->{packet_type} = defined($options{type}) ? $options{type} : 1;
    $unpacked->{packet_version} = 3;
    $unpacked->{result_code} = defined($options{result_code}) ? $options{result_code} : 2324;

    $self->{c}->parse(<<PACKET_STRUCT);
struct Packet{
  unsigned short   packet_version;
  unsigned short   packet_type;
  unsigned int     crc32_value;
  unsigned short   result_code;
  unsigned short   alignment;
  int              buffer_length;
  char             buffer[$len];
};
PACKET_STRUCT
    $self->{c}->tag('Packet.buffer', Format => 'String');
    my $packed = $self->{c}->pack('Packet', $unpacked);

    $unpacked->{crc32_value} = crc32($packed);
    $packed = $self->{c}->pack('Packet', $unpacked);
    return $packed;
}

sub assemble_v2 {
    my ($self, %options) = @_;
    
    my $len = $options{payload};

    my $unpacked;
    $unpacked->{buffer} = $options{check};
    $unpacked->{crc32_value} = "\x00\x00\x00\x00";
    $unpacked->{packet_type} = defined($options{type}) ? $options{type} : 1;
    $unpacked->{packet_version} = 2;
    $unpacked->{result_code} = defined($options{result_code}) ? $options{result_code} : 2324;

    $self->{c}->parse(<<PACKET_STRUCT);
struct Packet{
  unsigned short   packet_version;
  unsigned short   packet_type;
  unsigned int     crc32_value;
  unsigned short   result_code;
  char             buffer[$len];
};
PACKET_STRUCT
    $self->{c}->tag('Packet.buffer', Format => 'String');
    my $packed = $self->{c}->pack('Packet', $unpacked);

    $unpacked->{crc32_value} = crc32($packed);
    $packed = $self->{c}->pack('Packet', $unpacked);
    return $packed;
}

sub validate  {
    my ($self, $packet) = @_;

    my $unpacked = $self->disassemble($packet, 1);
    if (!$unpacked->{packet_version}) {
        # If version is missing this is probably not an NRPE Packet.
        return undef;
    }
    my $checksum = $unpacked->{crc32_value};
    $unpacked->{crc32_value} = "\x00\x00\x00\x00";
    my $packed = $self->assemble(
        %{
            {
                check   => $unpacked->{buffer},
                version => $unpacked->{packet_version},
                type    => $unpacked->{packet_type},
                result_code => $unpacked->{result_code}
            }
        }
    );
    if (crc32($packed) != $checksum) {
        return undef;
    } else {
        return 1;
    }
}

sub disassemble {
    my ($self, $packet, $novalidate) = @_;

    if (!$packet) {
        $self->{output}->add_option_msg(short_msg => "Could not disassemble packet.");
        $self->{output}->option_exit();
    }
    unless ($novalidate) {
        unless ($self->validate($packet)) {
            $self->{output}->add_option_msg(short_msg => "Packet had invalid CRC32.");
            $self->{output}->option_exit();
        }
    }

    my $version = unpack("n", $packet);
    if (!defined($version) || $version eq '') {
        $self->{output}->add_option_msg(short_msg => "Could not disassemble packet.");
        $self->{output}->option_exit();
    }

    my $unpacked = {};
    if ($version eq 2) {
        $unpacked = $self->disassemble_v2($packet);
    } else {
        $unpacked = $self->disassemble_v3($packet);
    }

    return $unpacked;
}

sub disassemble_v3 {
    my ($self, $packet) = @_;

    my @arr = unpack("n2 N n2 N Z*", $packet);
    my $unpacked = {};
    $unpacked->{packet_version} = $arr[0];
    $unpacked->{packet_type}    = $arr[1];
    $unpacked->{crc32_value}    = $arr[2];
    $unpacked->{result_code}    = $arr[3];
    $unpacked->{alignment}      = $arr[4];
    $unpacked->{buffer_length}  = $arr[5];
    $unpacked->{buffer}         = $arr[6];
    return $unpacked;
}

sub disassemble_v2 {
    my ($self, $packet) = @_;

    my @arr = unpack("n2 N n Z*", $packet);
    my $unpacked = {};
    $unpacked->{packet_version} = $arr[0];
    $unpacked->{packet_type}    = $arr[1];
    $unpacked->{crc32_value}    = $arr[2];
    $unpacked->{result_code}    = $arr[3];
    $unpacked->{buffer}         = $arr[4];
    return $unpacked;
}

sub request {
    my ($self, %options) = @_;

    my $check;
    if (!defined($options{arg}) || scalar @{$options{arg}} == 0) {
        $check = $options{check};
    } else {
        $check = join('!', $options{check}, @{$options{arg}});
    }

    my $socket = $self->create_socket(%options);

    my $assembled = $self->assemble(
        type => 1,
        check => $check,
        version => $self->{nrpe_version},
        payload => $self->{nrpe_payload}
    );
    
    my $response;
    print $socket $assembled;
    while (<$socket>) {
        $response .= $_;
    }
    close($socket);

    if (!defined($response) || $response eq '') {
        $self->{output}->add_option_msg(short_msg => "No response from remote host.");
        $self->{output}->option_exit();
    }
    
    my $response_packet = $self->disassemble($response, 1);
    if (!defined($response_packet->{packet_version}) || $response_packet->{packet_version} != $self->{nrpe_version}) {
        $self->{output}->add_option_msg(short_msg => "Bad response from remote host.");
        $self->{output}->option_exit();
    }
    
    return $response_packet;
}

sub set_nrpe_connect_params {
    my ($self, %options) = @_;
    
    foreach (keys %options) {
        $self->{nrpe_params}->{$_} = $options{$_};
    }
}

sub set_nrpe_params {
    my ($self, %options) = @_;
    
    foreach (keys %options) {
        $self->{$_} = $options{$_};
    }
}

sub get_hostname {
    my ($self) = @_;

    my $host = $self->{nrpe_params}->{PeerHost};
    $host =~ s/.*://;
    return $host;
}

sub get_port {
    my ($self) = @_;

    return $self->{nrpe_params}->{PeerPort};
}

1;

__END__

=head1 NAME

NRPE global

=head1 SYNOPSIS

NRPE class

=head1 NRPE CLASS OPTIONS

=over 8

=item B<--nrpe-version>

Version: 2 for NRPE v2 (Default), 3 for NRPE v3.

=item B<--nrpe-port>

Port (Default: 5666).

=item B<--nrpe-payload>

Buffer payload (For v2 only) (Default: 1024).

=item B<--nrpe-bindaddr>

Bind to local address.

=item B<--nrpe-use-ipv4>

Use IPv4 only

=item B<--nrpe-use-ipv6>

Use IPv6 only

=item B<--nrpe-timeout>

Timeout in secondes (Default: 10).

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => 'TLSv1'" --ssl-opt="SSL_verify_mode => 0"
--ssl-opt="SSL_cipher_list => ALL").

=back

=head1 DESCRIPTION

B<nrpe>.

=cut
