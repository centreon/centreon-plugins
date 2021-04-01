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

package centreon::common::protocols::modbus::custom::api;

use strict;
use warnings;
use centreon::plugins::misc;

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
            'rtu-port:s@'     => { name => 'rtu_port' },
            'rtu-baudrate:s@' => { name => 'rtu_baudrate' },
            'rtu-databits:s@' => { name => 'rtu_databits' },
            'rtu-parity:s@'   => { name => 'rtu_parity' },
            'rtu-stopbits:s@' => { name => 'rtu_stopbits' },
            'tcp-host:s@'     => { name => 'tcp_host' },
            'tcp-port:s@'     => { name => 'tcp_port' },
            'timeout:s@'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'MODBUS OPTIONS', once => 1);

    $self->{output} = $options{output};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
    # We remove empty rtu_port and tcp_host
    foreach my $label ('rtu_port', 'tcp_host') {
        if (defined($self->{option_results}->{$label})) {
            my @del_indexes = reverse(grep { $self->{option_results}->{$label}->[$_] eq '' } 0..$#{$self->{option_results}->{$label}});
            foreach my $item (@del_indexes) {
                splice (@{$self->{option_results}->{$label}}, $item, 1);
            }
        }
    }
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{modbus_type} = 1;
    $self->{modbus_params} = { rtu => {} , tcp => {} };
    my $timeout = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;

    if (defined($self->{option_results}->{rtu_port}->[0])) {
        $self->{modbus_type} = 2;
        $self->{modbus_params}->{rtu}->{port} = shift(@{$self->{option_results}->{rtu_port}});
        $self->{modbus_params}->{rtu}->{baudrate} = (defined($self->{option_results}->{rtu_baudrate})) ? shift(@{$self->{option_results}->{rtu_baudrate}}) : 9600;
        $self->{modbus_params}->{rtu}->{databits} = (defined($self->{option_results}->{rtu_databits})) ? shift(@{$self->{option_results}->{rtu_databits}}) : 8;
        $self->{modbus_params}->{rtu}->{parity} = (defined($self->{option_results}->{rtu_parity})) ? shift(@{$self->{option_results}->{rtu_parity}}) : 'none';
        $self->{modbus_params}->{rtu}->{stopbits} = (defined($self->{option_results}->{rtu_stopbits})) ? shift(@{$self->{option_results}->{rtu_stopbits}}) : 1;
        $self->{modbus_params}->{rtu}->{timeout} = $timeout;
    } elsif (defined($self->{option_results}->{tcp_host}->[0])) {
        $self->{modbus_params}->{tcp}->{host} = shift(@{$self->{option_results}->{tcp_host}});
        $self->{modbus_params}->{tcp}->{port} = (defined($self->{option_results}->{tcp_port})) ? shift(@{$self->{option_results}->{tcp_port}}) : 502;
        $self->{modbus_params}->{tcp}->{timeout} = $timeout;
    } else {
        $self->{output}->add_option_msg(short_msg => "Need to specify --rtu-port or --tcp-host option.");
        $self->{output}->option_exit();
    }

    if ((!defined($self->{modbus_params}->{rtu}->{port}) || scalar(@{$self->{option_results}->{rtu_port}}) == 0) && 
        (!defined($self->{modbus_params}->{tcp}->{host}) || scalar(@{$self->{option_results}->{tcp_host}}) == 0)) {
        return 0;
    }
    return 1;
}

sub connect {
    my ($self, %options) = @_;
    
    if ($self->{modbus_type} == 1) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Device::Modbus::TCP::Client',
                                               error_msg => "Cannot load module 'Device::Modbus::TCP::Client'.");
        $self->{modbus_client} = Device::Modbus::TCP::Client->new(%{$self->{modbus_params}->{tcp}});
    } else {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Device::Modbus::RTU::Client',
                                               error_msg => "Cannot load module 'Device::Modbus::RTU::Client'.");
        $self->{modbus_client} = Device::Modbus::RTU::Client->new(%{$self->{modbus_params}->{rtu}});
    }
}

my %mapping_methods = (
    holding     => 'read_holding_registers',
    coils       => 'read_coils',
    discrete    => 'read_discrete_inputs',
    input       => 'read_input_registers',
);

sub read_objects {
    my ($self, %options) = @_;
    my $unit = defined($options{unit}) ? $options{unit} : 1;
    my $type = defined($options{type}) ? $options{type} : 'holding';
    my $quantity = defined($options{quantity}) ? $options{quantity} : 1;
    my $results = [];
    
    if (!defined($self->{modbus_client})) {
        $self->connect();
    }

    my $method = $self->{modbus_client}->can($mapping_methods{$type});
    if ($method) {
        my $req = $self->{modbus_client}->$method(unit => $unit, address => $options{address}, quantity => $quantity);
        if (!$self->{modbus_client}->send_request($req)) {
            $self->{output}->add_option_msg(short_msg => "Modbus Request: send error $!");
            $self->{output}->option_exit();
        }
        my $response = $self->{modbus_client}->receive_response;
        if ($response->success()) {
            $results = $response->values();
        } else {
            $self->{output}->add_option_msg(short_msg => "Modbus Request: error " . $response->message()->stringify());
            $self->{output}->option_exit();
        }
    }

    if (scalar(@{$results}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Modbus Request: Cant get a single value.");
        $self->{output}->option_exit();
    }
    return $results;
}

1;

__END__

=head1 NAME

Modbus connector library

=head1 SYNOPSIS

my modbus connector

=head1 MODBUS OPTIONS

=over 8

=item B<--rtu-port>

The serial port to open.
Example: --rtu-port=/dev/ttyUSB0

=item B<--rtu-baudrate>  

A valid baud rate (Default: 9600)

=item B<--rtu-databits>

An integer from 5 to 8 (Default: 8)

=item B<--rtu-parity>

Either 'even', 'odd' or 'none' (Default: none)

=item B<--rtu-stopbits>

1 or 2 (Default: 1)

=item B<--tcp-host>

Host address

=item B<--tcp-port>

Host port (Default: 502)

=item B<--timeout>

Timeout in seconds (Default: 10)

=back

=head1 DESCRIPTION

B<custom>.

=cut
