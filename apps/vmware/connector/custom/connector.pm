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
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package apps::vmware::connector::custom::connector;

use strict;
use warnings;
use JSON;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);
use UUID;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    # $options{noptions} = integer

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => 
                    {
                      "connector-hostname:s@"    => { name => 'connector_hostname' },
                      "connector-port:s@"        => { name => 'connector_port' },
                      "container:s@"             => { name => 'container' },
                      "timeout:s@"               => { name => 'timeout' },                      
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CONNECTOR OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};

    $self->{json_send} = {};
    return $self;
}

# Method to manage multiples
sub set_options {
    my ($self, %options) = @_;
    # options{options_result}

    $self->{option_results} = $options{option_results};
}

# Method to manage multiples
sub set_defaults {
    my ($self, %options) = @_;
    # options{default}
    
    # Manage default value
    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    # return 1 = ok still hostname
    # return 0 = no hostname left

    $self->{connector_hostname} = (defined($self->{option_results}->{connector_hostname})) ? shift(@{$self->{option_results}->{connector_hostname}}) : undef;
    $self->{connector_port} = (defined($self->{option_results}->{connector_port})) ? shift(@{$self->{option_results}->{connector_port}}) : 5700;
    $self->{container} = (defined($self->{option_results}->{container})) ? shift(@{$self->{option_results}->{container}}) : 'default';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : undef;
    
    if (!defined($self->{connector_hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set option --connector-hostname.");
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

sub set_discovery {
    my ($self, %options) = @_;
    
    $self->{discovery} = 1;
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
    my $result;
    
    eval {
        $result =  JSON->new->utf8->decode($json);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json result: $@");
        $self->{output}->option_exit();
    }
    
    foreach my $output (@{$result->{plugin}->{outputs}}) {
        if ($output->{type} == 1) {
            $self->{output}->output_add(severity => $output->{exit},
                                        short_msg => $output->{msg});
        } elsif ($output->{type} == 2) {
            $self->{output}->output_add(long_msg => $output->{msg});
        }
    }
    
    foreach my $perf (@{$result->{plugin}->{perfdatas}}) {
        $self->{output}->perfdata_add(label => $perf->{label}, unit => $perf->{unit},
                                      value => $perf->{value},
                                      warning => $perf->{warning},
                                      critical => $perf->{critical},
                                      min => $perf->{min}, max => $perf->{max});
    }
}

sub run {
    my ($self, %options) = @_;
    
    # Build request
    my $uuid;
    UUID::generate($uuid);
    $self->{uuid} = $uuid;
    $self->{json_send}->{identity} = 'client-' . unpack('H*', $self->{uuid});
    $self->{json_send}->{connector_hostname} = $self->{connector_hostname};
    $self->{json_send}->{connector_port} = $self->{connector_port};
    $self->{json_send}->{container} = $self->{container};    
    
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
               # We need to remove xml output
               if (defined($self->{output}->{option_results}->{output_xml})) {
                   delete $self->{output}->{option_results}->{output_xml};
               }
               if (!defined($self->{discovery})) {
                   $self->{output}->display();
               } else {
                   $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
               }
               $self->{output}->exit();
            },
        },
    );
    
    zmq_poll(\@poll, $self->{timeout} * 1000);    
    zmq_close($self->{requester});
    
    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => sprintf("Cannot get response (timeout received)"));
    $self->{output}->display();
    $self->{output}->exit();
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

=item B<--timeout>

Set global execution timeout (Default: 50)

=back

=head1 DESCRIPTION

B<custom>.

=cut