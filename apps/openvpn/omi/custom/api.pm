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

package apps::openvpn::omi::custom::api;

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>  {
            'omi-hostname:s@' => { name => 'omi_hostname' },
            'omi-port:s@'     => { name => 'omi_port' },
            'omi-password:s@' => { name => 'omi_password' },
            'timeout:s@'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'MANAGEMENT API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{cnx_omi} = undef; 

    return $self;

}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{omi_hostname} = (defined($self->{option_results}->{omi_hostname})) ? shift(@{$self->{option_results}->{omi_hostname}}) : undef;
    $self->{omi_password} = (defined($self->{option_results}->{omi_password})) ? shift(@{$self->{option_results}->{omi_password}}) : undef;
    $self->{omi_port} = (defined($self->{option_results}->{omi_port})) ? shift(@{$self->{option_results}->{omi_port}}) : 7505;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
 
    if (!defined($self->{omi_hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --omi-hostname option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{omi_hostname}) ||
        scalar(@{$self->{option_results}->{omi_hostname}}) == 0) {
        return 0;
    }
    
    return 1;
}

sub get_connect_info {
    my ($self, %options) = @_;
    
    return $self->{omi_hostname}  . '_' . $self->{omi_port};
}

sub write_omi_protocol {
    my ($self, %options) = @_;
    
    $self->{cnx_omi}->send($options{cmd});
}

sub read_omi_protocol {
    my ($self, %options) = @_;
    
    my $select = IO::Select->new($self->{cnx_omi});
    my $read_msg;
    my $message = '';
    while (1) {
        if (!$select->can_read(10)) {
            $self->{output}->output_add(long_msg => $message, debug => 1);
            $self->{output}->add_option_msg(short_msg => "Communication issue [Timeout or unexpected protocol]");
            $self->{output}->option_exit();
        }

        my $status = $self->{cnx_omi}->recv($read_msg, 4096);
        $message .= $read_msg;
        last if ($message =~ /$options{expected}/ms);
    }
    
    $self->{output}->output_add(long_msg => $message, debug => 1);
    $message =~ s/\r//msg;
    #if ($response !~ /Success|Follows/) {
    #    $message =~ s/\n+$//msg;
    #    $message =~ s/\n/ -- /msg;
    #    $self->{output}->add_option_msg(short_msg => "Communication issue [" . $message . "]");
    #    $self->{output}->option_exit();
    #}    
    return $message;
}

sub command_omi_protocol {
    my ($self, %options) = @_;
    
    # Three types of message:
    #   CMD1
    #   SUCCESS: nclients=5,bytesin=7761549522,bytesout=18417469629
    #
    #   CMD1
    #   ERROR: unknown command, enter 'help' for more options
    #
    #   CMD1
    #   ...
    #   END
    $self->write_omi_protocol(cmd => "$options{cmd}
");
    my $message = $self->read_omi_protocol(expected => '^(END[^\n]*?|SUCCESS:[^\n]*?|ERROR:[^\n]*?)\n');
    if ($message =~ /^ERROR:(.*)/m) {
        $self->{output}->add_option_msg(short_msg => "Protocol error [" . $message . "]");
        $self->{output}->option_exit();
    }
    
    return $message;
}

sub login {
    my ($self, %options) = @_;
    
    my $message = $self->read_omi_protocol(expected => '^(>INFO:OpenVPN.*|ENTER\s+PASSWORD:)');
    if ($message =~ /PASSWORD/) {
        if (!defined($self->{omi_password}) || $self->{omi_password} eq '') {
            $self->{output}->add_option_msg(short_msg => "Openvpn management interface require a password. please set --omi-password option");
            $self->{output}->option_exit();
        }
        $self->write_omi_protocol(cmd => $self->{omi_password});
        $message = $self->read_omi_protocol(expected => '^(SUCCESS|ERROR):[^\n]*?\n');
        if ($message =~ /^ERROR:(.*)/m) {
            $self->{output}->add_option_msg(short_msg => "Password error [" . $1 . "]");
            $self->{output}->option_exit();
        }
    }
}

sub connect {
    my ($self, %options) = @_;
    
    $self->{cnx_omi} = IO::Socket::INET->new(
        PeerAddr => $self->{omi_hostname},
        PeerPort => $self->{omi_port},
        Proto    => 'tcp',
        Timeout  => $self->{timeout},
    );
    if (!defined($self->{cnx_omi})) {
        $self->{output}->add_option_msg(short_msg => "Can't bind : $@");
        $self->{output}->option_exit();
    }
    
    $self->{cnx_omi}->autoflush(1);
    $self->login();
}

sub command {
    my ($self, %options) = @_;

    if (!defined($self->{cnx_omi})) {
        $self->connect();
    }
    
    return $self->command_omi_protocol(%options);
}

sub DESTROY {
    my $self = shift;

    if (defined($self->{cnx_omi})) {
        $self->{cnx_omi}->close();
    }
}

1;

__END__

=head1 NAME

Openvpn Management interface

=head1 SYNOPSIS

Openvpn Management interface custom mode

=head1 MANAGEMENT API OPTIONS

=over 8

=item B<--omi-hostname>

OMI hostname.

=item B<--omi-port>

OMI port (Default: 7505).

=item B<--omi-password>

OMI password.

=item B<--timeout>

Set TCP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
