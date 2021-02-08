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

package apps::vmware::connector::custom::connector;

use strict;
use warnings;
use JSON;
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use UUID;

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
        $options{options}->add_options(arguments => {
            'connector-hostname:s@'    => { name => 'connector_hostname' },
            'connector-port:s@'        => { name => 'connector_port' },
            'vsphere-address:s@'       => { name => 'vsphere_address' },
            'vsphere-username:s@'      => { name => 'vsphere_username' },
            'vsphere-password:s@'      => { name => 'vsphere_password' },
            'container:s@'             => { name => 'container' },
            'timeout:s@'               => { name => 'timeout' },
            'sampling-period:s@'       => { name => 'sampling_period' },
            'time-shift:s@'            => { name => 'time_shift' },
            'case-insensitive'         => { name => 'case_insensitive' },
            'unknown-connector-status:s'  => { name => 'unknown_connector_status' },
            'warning-connector-status:s'  => { name => 'warning_connector_status' },
            'critical-connector-status:s' => { name => 'critical_connector_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CONNECTOR OPTIONS', once => 1);

    $self->{output} = $options{output};

    $self->{json_send} = {};
    $self->{result} = undef;
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{connector_hostname} = (defined($self->{option_results}->{connector_hostname})) ? shift(@{$self->{option_results}->{connector_hostname}}) : undef;
    $self->{connector_port} = (defined($self->{option_results}->{connector_port})) ? shift(@{$self->{option_results}->{connector_port}}) : 5700;
    $self->{container} = (defined($self->{option_results}->{container})) ? shift(@{$self->{option_results}->{container}}) : 'default';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : undef;
    $self->{vsphere_address} = (defined($self->{option_results}->{vsphere_address})) ? shift(@{$self->{option_results}->{vsphere_address}}) : undef;
    $self->{vsphere_username} = (defined($self->{option_results}->{vsphere_username})) ? shift(@{$self->{option_results}->{vsphere_username}}) : undef;
    $self->{vsphere_password} = (defined($self->{option_results}->{vsphere_password})) ? shift(@{$self->{option_results}->{vsphere_password}}) : undef;
    $self->{sampling_period} = (defined($self->{option_results}->{sampling_period})) ? shift(@{$self->{option_results}->{sampling_period}}) : undef;
    $self->{time_shift} = (defined($self->{option_results}->{sampling_period})) ? shift(@{$self->{option_results}->{time_shift}}) : 0;
    $self->{unknown_connector_status} = (defined($self->{option_results}->{unknown_connector_status})) ? $self->{option_results}->{unknown_connector_status} : '%{code} < 0 || (%{code} > 0 && %{code} < 200)';
    $self->{warning_connector_status} = (defined($self->{option_results}->{warning_connector_status})) ? $self->{option_results}->{warning_connector_status} : '';
    $self->{critical_connector_status} = (defined($self->{option_results}->{critical_connector_status})) ? $self->{option_results}->{critical_connector_status} : '';
    $self->{case_insensitive} = (defined($self->{option_results}->{case_insensitive})) ? $self->{option_results}->{case_insensitive} : undef;
    
    $self->{connector_port} = 5700 if ($self->{connector_port} eq '');
    $self->{container} = 'default' if ($self->{container} eq '');
    if (!defined($self->{connector_hostname}) || $self->{connector_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set option --connector-hostname.');
        $self->{output}->option_exit();
    }
    if (defined($self->{timeout}) && $self->{timeout} =~ /^\d+$/ &&
        $self->{timeout} > 0) {
        $self->{timeout} = $self->{timeout};
    } else {
        $self->{timeout} = 50;
    }
    
    if (!defined($self->{connector_hostname}) ||
        scalar(@{$self->{option_results}->{connector_hostname}}) == 0) {
        return 0;
    }
    return 1;
}

sub add_params {
    my ($self, %options) = @_;
    
    $self->{json_send}->{command} = $options{command} if (defined($options{command}));
    foreach (keys %{$options{params}}) {
        $self->{json_send}->{$_} = $options{params}->{$_};
    }
}

sub connector_response {
    my ($self, %options) = @_;
    
    if (!defined($options{response})) {
        $self->{output}->add_option_msg(short_msg => "Cannot read response: $!");
        $self->{output}->option_exit();
    }
    
    my $data = zmq_msg_data($options{response});
    if ($data !~ /^RESPSERVER (.*)/msi) {
        $self->{output}->add_option_msg(short_msg => "Response not formatted: $data");
        $self->{output}->option_exit();
    }
    
    my $json = $1;
    eval {
        $self->{output}->output_add(long_msg => $json, debug => 1);
        $self->{result} = JSON->new->utf8->decode($json);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json result: $@");
        $self->{output}->option_exit();
    }
}

sub connector_response_status {
    my ($self, %options) = @_;
    
    if (!defined($self->{result})) {
        $self->{output}->add_option_msg(short_msg => 'Cannot get response (timeout received)');
        $self->{output}->option_exit();
    }
    if (!defined($self->{result}->{code})) {
        $self->{output}->add_option_msg(short_msg => 'response format incorrect - need connector vmware version >= 3.x.x');
        $self->{output}->option_exit();
    }

    foreach (('unknown_connector_status', 'warning_connector_status', 'critical_connector_status')) {
        $self->{$_} =~ s/%\{(.*?)\}/\$self->{result}->{$1}/g;
    }

    # Check response
    my $status = 'ok';
    my $message;
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($self->{critical_connector_status}) && $self->{critical_connector_status} ne '' &&
            eval "$self->{critical_connector_status}") {
            $status = 'critical';
        } elsif (defined($self->{warning_connector_status}) && $self->{warning_connector_status} ne '' &&
                 eval "$self->{warning_connector_status}") {
            $status = 'warning';
        } elsif (defined($self->{unknown_connector_status}) && $self->{unknown_connector_status} ne '' &&
                 eval "$self->{unknown_connector_status}") {
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->add_option_msg(short_msg => 'filter connector status issue: ' . $message);
        $self->{output}->option_exit();
    }

    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(long_msg => $self->{result}->{extra_message}, debug => 1);
        $self->{output}->output_add(
            severity => $status,
            short_msg => $self->{result}->{short_message}
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub entity_is_connected {
    my ($self, %options) = @_;
     
    if ($options{state} !~ /^connected$/i) {
        return 0;
    }
    return 1;
}

sub vm_is_running {
    my ($self, %options) = @_;
    
    if ($options{power} !~ /^poweredOn$/i) {
        return 0;
    }
    return 1;
}

sub get_id {
    my ($self, %options) = @_;
    
    return $self->{connector_hostname} . '.' . $self->{connector_port} . '.' .  $self->{container};
}

sub strip_cr {
     my ($self, %options) = @_;
    
    $options{value} =~ s/^\s+.*\s+$//mg;
    $options{value} =~ s/\r//mg;
    $options{value} =~ s/\n/ -- /mg;
    return $options{value};
}

sub execute {
    my ($self, %options) = @_;
    
    $self->add_params(%options);
    
    # Build request
    my $uuid;
    UUID::generate($uuid);
    $self->{uuid} = $uuid;
    $self->{json_send}->{identity} = 'client-' . unpack('H*', $self->{uuid});
    $self->{json_send}->{connector_hostname} = $self->{connector_hostname};
    $self->{json_send}->{connector_port} = $self->{connector_port};
    $self->{json_send}->{container} = $self->{container};
    $self->{json_send}->{vsphere_address} = $self->{vsphere_address};
    $self->{json_send}->{vsphere_username} = $self->{vsphere_username};
    $self->{json_send}->{vsphere_password} = $self->{vsphere_password};
    $self->{json_send}->{sampling_period} = $self->{sampling_period};
    $self->{json_send}->{time_shift} = $self->{time_shift};
    $self->{json_send}->{case_insensitive} = $self->{case_insensitive};
    
    # Init
    my $context = zmq_init();
    $self->{requester} = zmq_socket($context, ZMQ_DEALER);
    if (!defined($self->{requester})) {
        $self->{output}->add_option_msg(short_msg => "Cannot create socket: $!");
        $self->{output}->option_exit();
    }
    
    my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;
    zmq_setsockopt($self->{requester}, ZMQ_IDENTITY, "client-" . $self->{uuid});
    zmq_setsockopt($self->{requester}, ZMQ_LINGER, 0); # we discard
    zmq_connect($self->{requester}, 'tcp://' . $self->{connector_hostname} . ':' . $self->{connector_port});
    zmq_sendmsg($self->{requester}, "REQCLIENT " . JSON->new->utf8->encode($self->{json_send}), ZMQ_NOBLOCK);
    
    my @poll = (
        {
            socket  => $self->{requester},
            events  => ZMQ_POLLIN,
            callback => sub {
               my $response = zmq_recvmsg($self->{requester});
               zmq_close($self->{requester});
               $self->connector_response(response => $response);
            },
        },
    );
    
    zmq_poll(\@poll, $self->{timeout} * 1000);    
    zmq_close($self->{requester});
    
    $self->connector_response_status();
    
    return $self->{result};
}

1;

__END__

=head1 NAME

VMWare connector library

=head1 SYNOPSIS

my vmware connector

=head1 CONNECTOR OPTIONS

=over 8

=item B<--connector-hostname>

Connector hostname (required).

=item B<--connector-port>

Connector port (default: 5700).

=item B<--container>

Container to use (it depends of the connector configuration).

=item B<--vsphere-address>

Address of vpshere/ESX to connect.

=item B<--vsphere-username>

Username of vpshere/ESX connection (with --vsphere-address).

=item B<--vsphere-password>

Password of vpshere/ESX connection (with --vsphere-address).

=item B<--timeout>

Set global execution timeout (Default: 50)

=item B<--sampling-period>

Choose the sampling period (can change the default sampling for counters).
Should be not different than 300 or 20.

=item B<--time-shift>

Can shift the time. We the following option you can average X counters values (default: 0).

=item B<--case-insensitive>

Searchs are case insensitive.

=item B<--unknown-connector-status>

Set unknown threshold for connector status (Default: '%{code} < 0 || (%{code} > 0 && %{code} < 200)').
Can used special variables like: %{code}, %{short_message}, %{extra_message}.

=item B<--warning-connector-status>

Set warning threshold for connector status (Default: '').
Can used special variables like: %{code}, %{short_message}, %{extra_message}.

=item B<--critical-connector-status>

Set critical threshold for connector status (Default: '').
Can used special variables like: %{code}, %{short_message}, %{extra_message}.

=back

=head1 DESCRIPTION

B<custom>.

=cut
