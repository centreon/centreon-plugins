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

package apps::voip::asterisk::ami::custom::api;

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
            'ami-hostname:s@' => { name => 'ami_hostname' },
            'ami-port:s@'     => { name => 'ami_port' },
            'ami-username:s@' => { name => 'ami_username' },
            'ami-password:s@' => { name => 'ami_password' },
            'timeout:s@'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AMI API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{cnx_ami} = undef;

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{ami_hostname} = (defined($self->{option_results}->{ami_hostname})) ? shift(@{$self->{option_results}->{ami_hostname}}) : undef;
    $self->{ami_username} = (defined($self->{option_results}->{ami_username})) ? shift(@{$self->{option_results}->{ami_username}}) : undef;
    $self->{ami_password} = (defined($self->{option_results}->{ami_password})) ? shift(@{$self->{option_results}->{ami_password}}) : undef;
    $self->{ami_port} = (defined($self->{option_results}->{ami_port})) ? shift(@{$self->{option_results}->{ami_port}}) : 5038;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;

    if (!defined($self->{ami_hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ami-hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{ami_username})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ami-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{ami_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --ami-password option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{ami_hostname}) ||
        scalar(@{$self->{option_results}->{ami_hostname}}) == 0) {
        return 0;
    }

    return 1;
}

sub get_connect_info {
    my ($self, %options) = @_;

    return $self->{ami_hostname}  . '_' . $self->{ami_port};
}

sub read_ami_protocol_end {
    my ($self, %options) = @_;

    if (defined($options{response})) {
        if ($options{response} eq 'Follows') {
            return 1 if ($options{message} =~ /^--END COMMAND--/ms);
        } else {
            if ($options{message} =~ /^Message:\s+Command\s+output\s+follows/i) {
                return 1 if ($options{message} =~ /\n\n/ms);
            } elsif ($options{message} =~ /^Message: (.*)(\n)/ms) {
                return 1;
            }
        }
    }

    return 0;
}

sub read_ami_protocol {
    my ($self, %options) = @_;

    my $select = IO::Select->new($self->{cnx_ami});
    # Three types of message:
    #    Response: Error
    #    Message: Authentication failed
    #
    #    Response: Follows
    #    ...
    #    --END COMMAND--
    #
    #    Response: Success
    #    Message: Command output follows
    #    output: xxxx
    #    output: xxxx
    #    ...
    #

    my ($response, $read_msg);
    my $message = '';
    while (1) {
        if (!$select->can_read(10)) {
            $response = 'Timeout';
            last;
        }

        my $status = $self->{cnx_ami}->recv($read_msg, 4096);
        $read_msg =~ s/\r//msg;
        if (!defined($response)) {
            next if ($read_msg !~ /^Response: (.*?)(?:\n)(.*)/ms);
            ($response, $message) = ($1, $2);
        } else {
            $message .= $read_msg;
        }

        last if ($self->read_ami_protocol_end(response => $response, message => $message));
    }

    $message =~ s/^Output:\s+//mig;
    if ($response !~ /Success|Follows/) {
        $message =~ s/\n+$//msg;
        $message =~ s/\n/ -- /msg;
        $self->{output}->add_option_msg(short_msg => "Communication issue [" . $message . "]");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => $message, debug => 1);
    return $message;
}

sub write_ami_protocol {
    my ($self, %options) = @_;

    $self->{cnx_ami}->send($options{cmd});
}

sub login {
    my ($self, %options) = @_;

    $self->write_ami_protocol(cmd => "Action:login
Username:$self->{ami_username}
Secret:$self->{ami_password}
Events: off

");
    # don't need to get it. If it comes, it's success :)
    $self->read_ami_protocol();
}

sub connect {
    my ($self, %options) = @_;

    $self->{cnx_ami} = IO::Socket::INET->new(
        PeerAddr => $self->{ami_hostname},
        PeerPort => $self->{ami_port},
        Proto    => 'tcp',
        Timeout  => $self->{timeout},
    );
    if (!defined($self->{cnx_ami})) {
        $self->{output}->add_option_msg(short_msg => "Can't bind : $@");
        $self->{output}->option_exit();
    }

    $self->{cnx_ami}->autoflush(1);
    $self->login();
}

sub command {
    my ($self, %options) = @_;

    if (!defined($self->{cnx_ami})) {
        $self->connect();
    }
    
    $self->write_ami_protocol(cmd => "Action:command
Command:$options{cmd}

");
    return $self->read_ami_protocol();
}

sub DESTROY {
    my $self = shift;

    if (defined($self->{cnx_ami})) {
        $self->{cnx_ami}->close();
    }
}

1;

__END__

=head1 NAME

Asterisk AMI

=head1 SYNOPSIS

Asterisk AMI custom mode

=head1 AMI API OPTIONS

=over 8

=item B<--ami-hostname>

AMI hostname (Required).

=item B<--ami-port>

AMI port (Default: 5038).

=item B<--ami-username>

AMI username.

=item B<--ami-password>

AMI password.

=item B<--timeout>

Set TCP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
